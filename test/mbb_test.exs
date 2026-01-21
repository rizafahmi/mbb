defmodule MbbTest do
  use ExUnit.Case
  doctest Mbb
  import ExUnit.CaptureIO

  @prompt "How many r in Strawberry? Answer with one following: one, two, three"

  test "main/1 should return string from llm if everything correct" do
    result = capture_io(fn -> Mbb.main([@prompt], SystemMock, &SenderMock.success/1) end)
    assert String.contains?(result, "mocked response")
  end

  test "main/1 should return error if something wrong" do
    result = capture_io(fn -> Mbb.main(["test"], SystemMock, &SenderMock.error/1) end)
    assert String.contains?(result, "Error:")
  end

  test "main/1 should print help message if no args" do
    result = capture_io(fn -> Mbb.main([], SystemMock) end)
    assert result == "Usage: ./mbb <your question>\n"
  end

  test "main/1 handles tool use flow: calls tool and returns final response" do
    result =
      capture_io(fn ->
        Mbb.main(["What time is it?"], SystemMock, &SenderMock.tool_use_flow/1)
      end)

    assert String.contains?(result, "9:46 PM")
  end
end
