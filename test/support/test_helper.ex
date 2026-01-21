defmodule Mbb.TestHelper do
  def execute_read_file(path) do
    cond do
      not File.exists?(path) -> "Error: File not found: #{path}"
      File.dir?(path) -> "Error: Path is a directory: #{path}"
      true -> File.read!(path)
    end
  end
end
