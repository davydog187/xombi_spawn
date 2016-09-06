defmodule XombiServer.GameServer do
  use GenServer
  require Logger

  @tcp_options [:binary, packet: :line, active: true, reuseaddr: true]

  def start_link(port) do
    Logger.info "Starting game server"
    GenServer.start_link(__MODULE__, %{socket: nil, port: port})
  end

  def init(state) do
    {:ok, socket} = :gen_tcp.listen(state.port, @tcp_options)

    Logger.info "Accepting connections on port #{state.port}"

    # TODO take a number into the GameServer state and spawn that number of acceptor tasks
    {:ok, _pid} = Task.Supervisor.start_child(XombiServer.ConnectionSupervisor, fn -> accept(socket) end)

    {:ok, %{state | socket: socket}}
  end

  def accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info "Connected to new client #{inspect client}"
    {:ok, pid } = Client.Supervisor.start_child(client)
    :ok = :gen_tcp.controlling_process(client, pid)

    accept(socket)
  end

end
