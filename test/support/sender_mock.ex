defmodule SenderMock do
  def success(_message) do
    {:ok, "mocked response"}
  end

  def error(_message) do
    {:error, "API error"}
  end
end
