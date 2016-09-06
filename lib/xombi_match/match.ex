defmodule XombiMatch.Match do
  alias XombiMatch.Types.Move
  use GenServer
  require Logger

  @doc """
  Starts a new match.
  """
  def start_link(player1, player2) do
    Logger.info "Starting #{__MODULE__}"
    GenServer.start_link(__MODULE__, %{player1: nil, player2: nil, player1_pid: player1, player2_pid: player2})
  end

  def init(state) do
    {:ok, %{state | player1: %Move{}, player2: %Move{}}}
  end

  def get_player_move(pid, player) when is_atom(player) do
    GenServer.call(pid, {:get_move, player})
  end

  def move_player(pid, player, move = %Move{}) do
    GenServer.cast(pid, {:move_player, player, move})
  end

  def handle_call({:get_move, player}, _from, state) do
    {:reply, state[player], state}
  end

  def handle_cast({:move_player, player, move}, state) do
    Logger.info("Moving player #{player} to #{inspect move}")
    GenServer.cast(state.player1_pid, {:move, move})
    GenServer.cast(state.player2_pid, {:move, move})
    {:noreply, Map.put(state, player, move)}
  end

end
