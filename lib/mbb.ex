defmodule Mbb do
  @api_url "https://api.anthropic.com/v1/messages"
  @model "claude-haiku-4-5-20251001"
  @system_prompt """
  You are an excellent principal engineer. You love programming language. \
  Your favorite language is Elixir and you always write code in functional paradigm. \
  You always answer in a concise and precise manner.\
  """
  @tools [
    %{
      name: "get_current_time",
      description: "Gets the current date and time",
      input_schema: %{type: "object", properties: %{}}
    },
    %{
      name: "read_file",
      description: "Reads a file from the filesystem",
      input_schema: %{
        type: "object",
        properties: %{
          path: %{type: "string", description: "File path to read"}
        },
        required: ["path"]
      }
    }
  ]

  defp send(messages) when is_list(messages) do
    api_key = System.get_env("API_KEY") || ""

    state = %{
      content: [],
      current_block: nil,
      current_text: "",
      current_tool_input: "",
      stop_reason: nil
    }

    result =
      Req.post!(@api_url,
        headers: [
          {"x-api-key", api_key},
          {"anthropic-version", "2023-06-01"}
        ],
        json: %{
          model: @model,
          max_tokens: 10_000,
          tools: @tools,
          temperature: 1,
          system: @system_prompt,
          messages: messages,
          stream: true
        },
        into: fn {:data, chunk}, {req, resp} ->
          new_state = process_sse_chunk(chunk, Process.get(:stream_state, state))
          Process.put(:stream_state, new_state)
          {:cont, {req, resp}}
        end
      )

    final_state = Process.get(:stream_state, state)
    Process.delete(:stream_state)

    case result do
      %{status: 200} -> handle_stream_result(final_state)
      %{status: status, body: body} -> {:error, "API error: #{status} - #{inspect(body)}"}
    end
  end

  defp send(message) do
    send([%{role: "user", content: message}])
  end

  defp process_sse_chunk(chunk, state) do
    chunk
    |> String.split("\n")
    |> Enum.reduce(state, fn line, acc ->
      case line do
        "data: " <> json_str ->
          case Jason.decode(json_str) do
            {:ok, event} -> handle_sse_event(event, acc)
            _ -> acc
          end

        _ ->
          acc
      end
    end)
  end

  defp handle_sse_event(%{"type" => "content_block_start", "content_block" => block}, state) do
    case block do
      %{"type" => "text"} ->
        %{state | current_block: :text, current_text: ""}

      %{"type" => "tool_use", "id" => id, "name" => name} ->
        %{state | current_block: {:tool_use, id, name}, current_tool_input: ""}
    end
  end

  defp handle_sse_event(%{"type" => "content_block_delta", "delta" => delta}, state) do
    case delta do
      %{"type" => "text_delta", "text" => text} ->
        IO.write(text)
        %{state | current_text: state.current_text <> text}

      %{"type" => "input_json_delta", "partial_json" => json} ->
        %{state | current_tool_input: state.current_tool_input <> json}

      _ ->
        state
    end
  end

  defp handle_sse_event(%{"type" => "content_block_stop"}, state) do
    case state.current_block do
      :text ->
        block = %{"type" => "text", "text" => state.current_text}
        %{state | content: state.content ++ [block], current_block: nil}

      {:tool_use, id, name} ->
        input =
          case state.current_tool_input do
            "" -> %{}
            json -> Jason.decode!(json)
          end

        block = %{"type" => "tool_use", "id" => id, "name" => name, "input" => input}
        %{state | content: state.content ++ [block], current_block: nil}

      _ ->
        state
    end
  end

  defp handle_sse_event(%{"type" => "message_delta", "delta" => %{"stop_reason" => reason}}, state) do
    %{state | stop_reason: reason}
  end

  defp handle_sse_event(_event, state), do: state

  defp handle_stream_result(%{stop_reason: "tool_use", content: content}) do
    tool_use = Enum.find(content, &(&1["type"] == "tool_use"))
    tool_result = execute_tool(tool_use["name"], tool_use["input"])
    {:tool_use, content, tool_use["id"], tool_result}
  end

  defp handle_stream_result(%{stop_reason: _}) do
    IO.puts("")
    {:ok, :streamed}
  end

  defp execute_tool("get_current_time", _input) do
    NaiveDateTime.local_now() |> NaiveDateTime.to_string()
  end

  defp execute_tool("read_file", %{"path" => path}) do
    cond do
      not File.exists?(path) -> "Error: File not found: #{path}"
      File.dir?(path) -> "Error: Path is a directory: #{path}"
      true -> File.read!(path)
    end
  end

  def main(args, system_mod \\ System, sender \\ &send/1)

  def main([args], system_mod, sender) do
    process_response(sender.(args), [%{role: "user", content: args}], system_mod, sender)
  end

  def main([], system_mod, _sender) do
    IO.puts("Usage: ./mbb <your question>")
    system_mod.halt(1)
  end

  defp process_response({:ok, :streamed}, _messages, system_mod, _sender) do
    system_mod.halt(0)
  end

  defp process_response({:ok, response}, _messages, system_mod, _sender) do
    IO.puts(response)
    system_mod.halt(0)
  end

  defp process_response(
         {:tool_use, assistant_content, tool_id, tool_result},
         messages,
         system_mod,
         sender
       ) do
    new_messages =
      messages ++
        [
          %{role: "assistant", content: assistant_content},
          %{
            role: "user",
            content: [
              %{type: "tool_result", tool_use_id: tool_id, content: tool_result}
            ]
          }
        ]

    process_response(sender.(new_messages), new_messages, system_mod, sender)
  end

  defp process_response({:error, error}, _messages, system_mod, _sender) do
    IO.puts("Error: #{inspect(error)}")
    system_mod.halt(1)
  end
end
