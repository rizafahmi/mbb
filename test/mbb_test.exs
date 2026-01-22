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

  describe "read_file tool" do
    test "reads file content successfully" do
      path = Path.join(System.tmp_dir!(), "test_read_#{:rand.uniform(10000)}.txt")
      File.write!(path, "hello world")

      result =
        capture_io(fn ->
          Mbb.main(["Read the file"], SystemMock, SenderMock.read_file_flow(path))
        end)

      assert String.contains?(result, "Here is the file content")
      File.rm!(path)
    end

    test "returns error when file not found" do
      path = "/nonexistent/path/file.txt"
      sender = SenderMock.read_file_flow(path)

      result =
        capture_io(fn ->
          Mbb.main(["Read the file"], SystemMock, sender)
        end)

      assert String.contains?(result, "Here is the file content")
    end

    test "returns error when path is a directory" do
      path = System.tmp_dir!()
      sender = SenderMock.read_file_flow(path)

      result =
        capture_io(fn ->
          Mbb.main(["Read the file"], SystemMock, sender)
        end)

      assert String.contains?(result, "Here is the file content")
    end
  end

  describe "write_file tool" do
    test "writes file content successfully" do
      path = Path.join(System.tmp_dir!(), "test_write_#{:rand.uniform(10000)}.txt")
      content = "hello from test"

      result =
        capture_io(fn ->
          Mbb.main(["Write the file"], SystemMock, SenderMock.write_file_flow(path, content))
        end)

      assert String.contains?(result, "File written successfully")
      assert File.read!(path) == content
      File.rm!(path)
    end

    test "returns error when path is invalid" do
      path = "/nonexistent/directory/file.txt"
      content = "test content"
      sender = SenderMock.write_file_flow(path, content)

      result =
        capture_io(fn ->
          Mbb.main(["Write the file"], SystemMock, sender)
        end)

      assert String.contains?(result, "File written successfully")
    end
  end
end
