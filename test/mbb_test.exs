defmodule MbbTest do
  use ExUnit.Case
  doctest Mbb
  import ExUnit.CaptureIO

  @prompt "How many r in Strawberry? Answer with one following: one, two, three"

  describe "main/1 function" do
    test "main/1 should return string from llm if everything correct" do
      result = capture_io(fn -> Mbb.main([@prompt], SystemMock) end)
      assert String.contains?(result, "three") or String.contains?(result, "two")
    end

    test "main/1 should return error if something wrong" do
      original = System.get_env("API_KEY")
      System.put_env("API_KEY", "invalid_key")
      result = capture_io(fn -> Mbb.main(["invalid prompt to cause error"], SystemMock) end)
      assert String.length(result) > 0

      if original do
        System.put_env("API_KEY", original)
      else
        System.delete_env("API_KEY")
      end
    end

    test "main/1 should print help message if no args" do
      result = capture_io(fn -> Mbb.main([], SystemMock) end)
      assert result == "Usage: ./mbb <your question>\n"
    end
  end

  describe "send/1 function" do
    test "send/1 message to llm and get response" do
      {:ok, result} =
        Mbb.send(@prompt)

      assert String.contains?(result, "three") or String.contains?(result, "two")
    end

    test "send/1 return error with invalid api key" do
      original = System.get_env("API_KEY")
      System.put_env("API_KEY", "invalid_key")
      {:error, _reason} = Mbb.send(@prompt)

      if original do
        System.put_env("API_KEY", original)
      else
        System.delete_env("API_KEY")
      end
    end
  end
end
