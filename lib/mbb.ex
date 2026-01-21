defmodule Mbb do
  def main(args) do
    IO.puts("Hello, world!")
  end
  def main([]) do
    IO.puts("Usage: ./mbb <your question>")
  end
end
