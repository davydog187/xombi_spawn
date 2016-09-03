defmodule XombiMatch.Match do
  alias XombiMatch.Types.Move
  use GenServer
  require Logger

  @doc """
  Starts a new match.
  """
  def start_link do
    Logger.info "Starting #{__MODULE__}"
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:ok, %{player1: %Move{}, player2: %Move{}}}
  end

  def get_player_move(pid, player) when is_atom(player) do
    GenServer.call(pid, {:get_move, player})
  end

  def move_player(pid, player, move = %Move{}) when is_atom(player) do
    GenServer.cast(pid, {:move_player, player, move})
  end

  def handle_call({:get_move, player}, _from, state) do
    {:reply, state[player], state}
  end

  def handle_cast({:move_player, player, move}, state) do
    {:noreply, Map.put(state, player, move)}
  end

end
