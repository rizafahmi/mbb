defmodule MbbTest do
  use ExUnit.Case
  doctest Mbb
  import ExUnit.CaptureIO

  @prompt "How many r in Strawberry? Answer with one following: one, two, three"

  describe "main/1 function" do
    test "main/1 should return string from llm if everything correct" do
      result = capture_io(fn -> Mbb.main([@prompt], SystemMock) end)
      assert String.contains?(result, "three")
    end

    test "main/1 should return error if something wrong"

    test "main/1 should print help message if no args" do
      result = capture_io(fn -> Mbb.main([], SystemMock) end)
      assert result == "Usage: ./mbb <your question>\n"
    end
  end

  describe "send function" do
    test "send message to llm and get response" do
      {:ok, result} =
        Mbb.send(@prompt)

      assert String.contains?(result, "three") or String.contains?(result, "two")
    end
  end
end
