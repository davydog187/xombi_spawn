defmodule XombiMatch.Match do
  alias XombiMatch.Types.Move
  require Logger

  @doc """
  Starts a new match.
  """
  def start_link do
    Agent.start_link(fn -> %{ player1: %Move{}, player2: %Move{} } end, name: __MODULE__)
    Logger.info "Started #{__MODULE__}"
  end

  def player_move(_player, _movement) do
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(match, key) do
    Agent.get(match, &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(match, key, value) do
    Agent.update(match, &Map.put(&1, key, value))
  end

end
