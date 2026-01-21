defmodule SenderMock do
  def success(_message) do
    {:ok, "mocked response"}
  end

  def error(_message) do
    {:error, "API error"}
  end

  def tool_use_flow(message) when is_binary(message) do
    {:tool_use,
     [
       %{"type" => "text", "text" => "Let me check the time."},
       %{"type" => "tool_use", "id" => "tool_123", "name" => "get_current_time", "input" => %{}}
     ], "tool_123", "2026-01-21 21:46:00"}
  end

  def tool_use_flow(messages) when is_list(messages) do
    {:ok, "The current time is 9:46 PM."}
  end
end
