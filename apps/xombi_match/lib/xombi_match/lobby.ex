defmodule XombiMatch.Lobby do
  require Logger
  alias XombiMatch.Match

  def start_link do
    Logger.info "Starting #{__MODULE__}"
    Agent.start_link(fn -> %{ waiting: [], matches: []} end, name: __MODULE__)
  end

  @doc "Gets the next match id"
  def match(player) do
    case Agent.get(__MODULE__, fn state -> state[:waiting] end) do
      [] -> queue_player(player)
      [waiting] -> match_players(waiting, player)
      _ -> {:error, "Unable to match"}
    end
  end

  defp queue_player(player) do
    Agent.update(__MODULE__, fn state -> %{ state | waiting: [player]} end)
    {:waiting, player}
  end

  defp match_players(waiting, player) do
    {:ok, pid} = XombiMatch.Match.Supervisor.start_child()
    Agent.update(__MODULE__, fn state -> %{ state | waiting: []} end)
    {:matched, [waiting, player]}
  end

end
