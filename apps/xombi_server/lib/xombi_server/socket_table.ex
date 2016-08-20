defmodule XombiServer.SocketTable do
  require Logger

  def start_link do
    Logger.info "Starting #{__MODULE__}"
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  def get(id) do
    case Agent.get(__MODULE__, fn state -> Map.get(state, id) end) do
      nil -> {:error, "#{id} not found"}
      socket -> {:ok, socket}
    end
  end

  def set(id, socket) do
    Agent.update(__MODULE__, fn state -> Map.update(state, id, socket, &(&1)) end)
  end

end
