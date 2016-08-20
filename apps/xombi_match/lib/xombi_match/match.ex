defmodule XombiMatch.Match do

  @doc """
  Starts a new match.
  """
  def start_link do
    Agent.start_link(fn -> %{} end)
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
