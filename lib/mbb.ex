defmodule Mbb do
  def send(message) do
    req =
      Req.new(base_url: "https://api.anthropic.com/v1/messages")
      |> Req.Request.put_header("Content-Type", "application/json")
      |> Req.Request.put_header("x-api-key", System.get_env("API_KEY"))
      |> Req.Request.put_header("anthropic-version", "2023-06-01")
      |> Req.post(
        json: %{
          "model" => "claude-haiku-4-5-20251001",
          "max_tokens" => 10000,
          "temperature" => 1,
          "system" =>
            "You are an excellent principal engineer. You love programming language. Your favorite language is Elixir and you always write code in functional paradigm. You always answer in a concise and precise manner.",
          "messages" => [
            %{"role" => "user", "content" => message}
          ]
        }
      )

    case req do
      {:ok, response} ->
        text = response.body["content"] |> List.first() |> Map.get("text")
        {:ok, text}

      {:error, error} ->
        {:error, error}
    end
  end

  def main(args, system_mod \\ System)

  def main([args], system_mod) do
    case send(args) do
      {:ok, response} ->
        IO.puts(response)
        system_mod.halt(0)

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}")
        system_mod.halt(1)
    end
  end

  def main([], system_mod) do
    IO.puts("Usage: ./mbb <your question>")
    system_mod.halt(1)
  end
end
