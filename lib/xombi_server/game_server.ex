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

 defp read_registration(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0);

    {:register, player_name} = XombiServer.Command.run(data)
    Logger.info "Registering #{player_name}"
    XombiServer.SocketTable.set(player_name, socket)

    player_name
  end

  defp send_match_message(player, players) do
    # TODO this is bad, will crash the handling process if the socket
    # is down
    {:ok, socket} = XombiServer.SocketTable.get(player)
    write_line(XombiServer.Encoder.matched(player, filter_players(players, player)), socket)
  end

  defp filter_players(players, exclude_player) do
    Enum.filter(players, fn player -> player != exclude_player end)
  end

  defp read_username(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)

    with {:ok, username, message} <- XombiServer.Decoder.decode(data),
    {:ok, response} <- dispatch_message(username, message),
    do: Logger.info "For #{username} got #{inspect(message)}"
  end

end
