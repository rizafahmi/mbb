defmodule Mbb do
  def main(args, system_mod \\ System)

    IO.puts("Hello, world!")
  end

  def main([], system_mod) do
    IO.puts("Usage: ./mbb <your question>")
    system_mod.halt(1)
  end
end
