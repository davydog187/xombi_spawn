defmodule XombiMatch.Lobby do
  use GenServer
  require Logger
  alias XombiMatch.Match

  def start_link do
    Logger.info "Starting #{__MODULE__} #{inspect self}"
    Agent.start_link(fn -> %{ waiting: [], matches: [], player_to_match: Map.new } end, name: __MODULE__)
  end

  @doc "Gets the next match id"
  def match(player) do
    player_pid = self
    case Agent.get(__MODULE__, fn state -> state[:waiting] end) do
      [] -> queue_player(player, player_pid)
      [waiting] -> match_players(waiting, {player, player_pid})
      _ -> {:error, "Unable to match"}
    end
    :ok
  end

  def handle_move(player, move) do
    case get_match_for_player(player) do
      {:ok, match} -> XombiMatch.Match.move_player(match, player, move)
      :error -> Logger.error "Trying to move #{player} without a match"
    end
  end

  defp get_match_for_player(player) do
    Agent.get(__MODULE__, fn state -> Map.fetch(state[:player_to_match], player) end)
  end

  defp queue_player(player, pid) do
    Agent.update(__MODULE__, fn state -> %{ state | waiting: [{player, pid}]} end)
    GenServer.cast(pid, {:waiting, player})
  end

  defp match_players({waiting_player, waiting_pid}, {player, player_pid}) do
    {:ok, match_pid} = XombiMatch.Match.Supervisor.start_child(waiting_pid, player_pid)
    Agent.update(__MODULE__, fn state ->
      new_player_match = Map.put(state[:player_to_match], player, match_pid)
      %{ state | waiting: [], matches: [match_pid | state.matches], player_to_match: new_player_match}
    end)

    GenServer.cast(waiting_pid, {:matched, player})
    GenServer.cast(player_pid, {:matched, waiting_player})
  end

end
