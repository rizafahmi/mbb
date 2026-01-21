defmodule Mbb do
  @api_url "https://api.anthropic.com/v1/messages"
  @model "claude-haiku-4-5-20251001"
  @system_prompt """
  You are an excellent principal engineer. You love programming language. \
  Your favorite language is Elixir and you always write code in functional paradigm. \
  You always answer in a concise and precise manner.\
  """

  defp send(message) do
    api_key = System.get_env("API_KEY") || ""

    @api_url
    |> Req.post(
      headers: [
        {"x-api-key", api_key},
        {"anthropic-version", "2023-06-01"}
      ],
      json: %{
        model: @model,
        max_tokens: 10_000,
        temperature: 1,
        system: @system_prompt,
        messages: [%{role: "user", content: message}]
      }
    )
    |> handle_response()
  end

  defp handle_response({:ok, %{status: 200, body: body}}) do
    text = get_in(body, ["content", Access.at(0), "text"])
    {:ok, text}
  end

  defp handle_response({:ok, %{status: status, body: body}}) do
    error = get_in(body, ["error", "message"]) || "API error: #{status}"
    {:error, error}
  end

  defp handle_response({:error, error}), do: {:error, error}

  def main(args, system_mod \\ System, sender \\ &send/1)

  def main([args], system_mod, sender) do
    case sender.(args) do
      {:ok, response} ->
        IO.puts(response)
        system_mod.halt(0)

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}")
        system_mod.halt(1)
    end
  end

  def main([], system_mod, _sender) do
    IO.puts("Usage: ./mbb <your question>")
    system_mod.halt(1)
  end
end
