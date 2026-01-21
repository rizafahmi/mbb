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

    @api_url
    |> Req.post(
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
        messages: messages
      }
    )
    |> handle_response()
  end

  defp send(message) do
    send([%{role: "user", content: message}])
  end

  defp handle_response({:ok, %{status: 200, body: body}}) do
    case body["stop_reason"] do
      "tool_use" ->
        tool_use = Enum.find(body["content"], &(&1["type"] == "tool_use"))
        tool_result = execute_tool(tool_use["name"], tool_use["input"])
        {:tool_use, body["content"], tool_use["id"], tool_result}

      _ ->
        text = get_in(body, ["content", Access.at(0), "text"])
        {:ok, text}
    end
  end

  defp handle_response({:ok, %{status: status, body: body}}) do
    error = get_in(body, ["error", "message"]) || "API error: #{status}"
    {:error, error}
  end

  defp handle_response({:error, error}), do: {:error, error}

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
