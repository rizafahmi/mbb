# Building an Oversimplified Coding Assistant in Elixir

A step-by-step tutorial on building an AI-powered coding assistant CLI using Elixir and Claude API.

## What We're Building

A command-line tool that:
- Accepts natural language questions
- Streams responses in real-time from Claude
- Can read and write files on your system
- Uses an **agentic loop** pattern for multi-turn tool use

```bash
./mbb "What time is it?"
./mbb "Read the file mix.exs and explain what it does"
./mbb "Create a hello.txt file with a greeting"
```

---

## Step 1: Initialize the Elixir Project

```bash
mix new mbb
cd mbb
```

Create the basic module in `lib/mbb.ex`:

```elixir
defmodule Mbb do
  def main(args) do
    IO.puts("Hello, world!")
  end
end
```

---

## Step 2: Setup Escript for CLI Execution

Update `mix.exs` to build an executable:

```elixir
def project do
  [
    app: :mbb,
    version: "0.1.0",
    elixir: "~> 1.18",
    start_permanent: Mix.env() == :prod,
    escript: [main_module: Mbb],  # Add this line
    deps: deps()
  ]
end
```

Build the executable:

```bash
mix escript.build
./mbb
```

---

## Step 3: Add Help Message and Argument Validation

Handle the case when no arguments are provided:

```elixir
defmodule Mbb do
  def main([]) do
    IO.puts("Usage: ./mbb <your question>")
  end

  def main(args) do
    IO.puts("Hello, world!")
  end
end
```

Add a test in `test/mbb_test.exs`:

```elixir
defmodule MbbTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "main/1 should print help message if no args" do
    result = capture_io(fn -> Mbb.main([]) end)
    assert result == "Usage: ./mbb <your question>\n"
  end
end
```

---

## Step 4: Gracefully Exit the Application

Use `System.halt/1` to exit with proper codes. Inject the System module for testability:

```elixir
defmodule Mbb do
  def main(args, system_mod \\ System)

  def main([], system_mod) do
    IO.puts("Usage: ./mbb <your question>")
    system_mod.halt(1)
  end

  def main([args], system_mod) do
    IO.puts("Hello, world!")
    system_mod.halt(0)
  end
end
```

Create a mock for testing in `test/support/system_mock.ex`:

```elixir
defmodule SystemMock do
  def halt(_), do: :ok
end
```

Update `mix.exs` to compile test support files:

```elixir
defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(_), do: ["lib"]
```

---

## Step 5: Add HTTP Client Dependency

Add `Req` to `mix.exs`:

```elixir
defp deps do
  [
    {:req, "~> 0.5.17"}
  ]
end
```

Install:

```bash
mix deps.get
```

---

## Step 6: Send Requests to Claude API

Create the `send/1` function to call the Anthropic API:

```elixir
defmodule Mbb do
  @api_url "https://api.anthropic.com/v1/messages"
  @model "claude-haiku-4-5-20251001"
  @system_prompt """
  You are an excellent principal engineer. You love programming language. \
  Your favorite language is Elixir and you always write code in functional paradigm. \
  You always answer in a concise and precise manner.\
  """

  def send(message) do
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
        temperature: 1,
        system: @system_prompt,
        messages: [%{role: "user", content: message}]
      }
    )
    |> handle_response()
  end

  defp handle_response({:ok, %{status: 200, body: body}}) do
    text = get_in(body, ["content", Access.at(0), "text"])
    {:ok, text}
  end

  defp handle_response({:ok, %{status: status, body: body}}) do
    error = get_in(body, ["error", "message"]) || "API error: #{status}"
    {:error, error}
  end

  defp handle_response({:error, error}), do: {:error, error}

  def main(args, system_mod \\ System)

  def main([args], system_mod) do
    case send(args) do
      {:ok, response} ->
        IO.puts(response)
        system_mod.halt(0)

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}")
        system_mod.halt(1)
    end
  end

  def main([], system_mod) do
    IO.puts("Usage: ./mbb <your question>")
    system_mod.halt(1)
  end
end
```

Test it:

```bash
export API_KEY="your-anthropic-api-key"
mix escript.build
./mbb "What is Elixir?"
```

---

## Step 7: Add Tool Calling Support

Define tools that Claude can use:

```elixir
@tools [
  %{
    name: "get_current_time",
    description: "Gets the current date and time",
    input_schema: %{type: "object", properties: %{}}
  }
]
```

Update `send/1` to accept a messages list and include tools:

```elixir
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
```

Handle tool use responses:

```elixir
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

defp execute_tool("get_current_time", _input) do
  NaiveDateTime.local_now() |> NaiveDateTime.to_string()
end
```

---

## Step 8: Implement the Agentic Loop

The key pattern: when Claude uses a tool, send the result back and continue the conversation:

```elixir
def main([args], system_mod, sender) do
  process_response(sender.(args), [%{role: "user", content: args}], system_mod, sender)
end

defp process_response({:ok, response}, _messages, system_mod, _sender) do
  IO.puts(response)
  system_mod.halt(0)
end

defp process_response({:tool_use, assistant_content, tool_id, tool_result}, messages, system_mod, sender) do
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

  # Recursive call - continues until Claude responds with text
  process_response(sender.(new_messages), new_messages, system_mod, sender)
end

defp process_response({:error, error}, _messages, system_mod, _sender) do
  IO.puts("Error: #{inspect(error)}")
  system_mod.halt(1)
end
```

---

## Step 9: Add File Reading Tool

Add the `read_file` tool definition:

```elixir
@tools [
  # ... get_current_time ...
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
```

Implement the tool:

```elixir
defp execute_tool("read_file", %{"path" => path}) do
  IO.puts("\n\n📖 Reading #{path}.\n\n")

  cond do
    not File.exists?(path) -> "Error: File not found: #{path}"
    File.dir?(path) -> "Error: Path is a directory: #{path}"
    true -> File.read!(path)
  end
end
```

---

## Step 10: Add Streaming Support

Replace the blocking API call with SSE streaming for real-time output:

```elixir
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
        stream: true  # Enable streaming!
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
```

Process SSE chunks:

```elixir
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
      _ -> acc
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
      IO.write(text)  # Print text in real-time!
      %{state | current_text: state.current_text <> text}

    %{"type" => "input_json_delta", "partial_json" => json} ->
      %{state | current_tool_input: state.current_tool_input <> json}

    _ -> state
  end
end

defp handle_sse_event(%{"type" => "content_block_stop"}, state) do
  case state.current_block do
    :text ->
      block = %{"type" => "text", "text" => state.current_text}
      %{state | content: state.content ++ [block], current_block: nil}

    {:tool_use, id, name} ->
      input = case state.current_tool_input do
        "" -> %{}
        json -> Jason.decode!(json)
      end
      block = %{"type" => "tool_use", "id" => id, "name" => name, "input" => input}
      %{state | content: state.content ++ [block], current_block: nil}

    _ -> state
  end
end

defp handle_sse_event(%{"type" => "message_delta", "delta" => %{"stop_reason" => reason}}, state) do
  %{state | stop_reason: reason}
end

defp handle_sse_event(_event, state), do: state
```

---

## Step 11: Add File Writing Tool

Complete the coding assistant with write capability:

```elixir
@tools [
  # ... other tools ...
  %{
    name: "write_file",
    description: "Writes content to a file. Creates the file if it doesn't exist, overwrites if it does.",
    input_schema: %{
      type: "object",
      properties: %{
        path: %{type: "string", description: "File path to write to"},
        content: %{type: "string", description: "Content to write to the file"}
      },
      required: ["path", "content"]
    }
  }
]

defp execute_tool("write_file", %{"path" => path, "content" => content}) do
  IO.puts("\n\n✏️  Writing to #{path}.\n\n")

  case File.write(path, content) do
    :ok -> "Successfully wrote #{byte_size(content)} bytes to #{path}"
    {:error, reason} -> "Error: Failed to write file: #{reason}"
  end
end
```

---

## Final Build

```bash
mix escript.build
```

## Usage Examples

```bash
# Ask questions
./mbb "Explain pattern matching in Elixir"

# Read files
./mbb "Read mix.exs and explain the dependencies"

# Write files
./mbb "Create a GenServer module in lib/counter.ex"

# Multi-turn tool use
./mbb "What time is it and write it to time.txt"
```

---

## Architecture Summary

```
┌─────────────┐
│  CLI Entry  │
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐
│  API Call   │────▶│  SSE Stream │
└─────────────┘     └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ Stop Reason │
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                                 ▼
   ┌─────────────┐                   ┌─────────────┐
   │  Tool Use   │                   │   Output    │
   └──────┬──────┘                   └─────────────┘
          │
          ▼
   ┌─────────────┐
   │   Execute   │
   │    Tool     │
   └──────┬──────┘
          │
          ▼
   ┌─────────────┐
   │ Send Result │──────┐
   │   to API    │      │
   └─────────────┘      │
          ▲             │
          └─────────────┘
        (Recursive Loop)
```

The **agentic loop** continues until Claude responds with `stop_reason: "end_turn"` instead of `"tool_use"`.

---

## Key Concepts

1. **Dependency Injection** - Pass `System` module and `sender` function for testability
2. **SSE Streaming** - Real-time output using Req's `into:` callback
3. **Agentic Loop** - Recursive `process_response/4` that continues until completion
4. **Tool Definitions** - JSON schema describing tools Claude can use
5. **Process Dictionary** - Accumulate streaming state during chunk processing

## Next Steps

- Add more tools (shell commands, web search, etc.)
- Add conversation history/memory
- Add error recovery and retries
- Add file path validation and sandboxing
