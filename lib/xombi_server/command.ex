defmodule XombiServer.Command do
  require Logger
  alias XombiMatch.Types.Move

  def run(input) do
    #TODO we should have a size limit here to prevent DOS attack
    output = input
              |> String.trim()
              |> String.split(" ")
              |> handle

    case output do
      :error -> {:error, input}
      _ -> output
    end
  end

  defp handle(["register", id]) do
    {:register, String.trim(id)}
  end

  defp handle(["move", x, y, z]) do
    x = String.to_integer(x)
    y = String.to_integer(y)
    z = String.to_integer(z)
    {:move, %Move{x: x, y: y, z: z}}
  end

  defp handle(error) do
    {:error, error}
  end

 def request_match(name) do
    XombiMatch.Lobby.match(name) # TODO send pid of caller?
  end

end
