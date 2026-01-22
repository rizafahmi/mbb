defmodule Mbb.TestHelper do
  def execute_read_file(path) do
    cond do
      not File.exists?(path) -> "Error: File not found: #{path}"
      File.dir?(path) -> "Error: Path is a directory: #{path}"
      true -> File.read!(path)
    end
  end

  def execute_write_file(path, content) do
    case File.write(path, content) do
      :ok -> "Successfully wrote #{byte_size(content)} bytes to #{path}"
      {:error, reason} -> "Error: Failed to write file: #{reason}"
    end
  end
end
