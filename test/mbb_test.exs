defmodule MbbTest do
  use ExUnit.Case
  doctest Mbb
  import ExUnit.CaptureIO

  test "greets the world" do
    assert Mbb.hello() == :world
  test "main/1 should print help message if no args" do
    result = capture_io(fn -> Mbb.main([]) end)
    assert result == "Usage: ./mbb <your question>\n"
  end
end
