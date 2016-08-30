defmodule XombiServer do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Task.Supervisor, [[name: XombiServer.ConnectionSupervisor]]),
      worker(XombiServer.SocketTable, []),
      worker(Task, [XombiServer, :accept, [4040]]),
    ]

    opts = [strategy: :one_for_one, name: XombiServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info "Got a new socket connection"

    {:ok, pid } = Task.Supervisor.start_child(XombiServer.ConnectionSupervisor, fn -> register(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp register(socket) do
    socket
    |> read_registration()

    serve(socket)
  end

  defp serve(socket) do
    socket
    |> read_move()

    serve(socket)
  end

  defp read_move(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)

    case XombiServer.Command.run(data) do
      {:move, move} -> Logger.info "got move #{inspect move}"
      {:error, error} -> Logger.info "Bad input for move #{error}"
    end
  end

  defp read_registration(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0);
    Logger.info "Got data #{inspect data}"

    {:register, player_name} = XombiServer.Command.run(data)
    Logger.info "Registering #{player_name}"
    XombiServer.SocketTable.set(player_name, socket)

    case XombiServer.Command.request_match(player_name) do
      {:waiting, player} -> write_line(XombiServer.Encoder.waiting(player), socket)
      {:matched, players} -> Enum.map(players, fn current_player -> send_match_message(current_player, players) end)
      {:error, message} -> write_line(XombiServer.Encoder.error(message), socket)
    end
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

  defp dispatch_message(username, message) do
    case message do
      #%XombiMatch.Types.Move{} ->
      _ -> {:ok, "hello"}
    end
  end

  defp read_username(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)

    with  {:ok, username, message} <- XombiServer.Decoder.decode(data),
    {:ok, response} <- dispatch_message(username, message),
    do: Logger.info "For #{username} got #{inspect(message)}"
  end

  defp write_line(line, socket) do
    Logger.info "Sending #{line}"
    :gen_tcp.send(socket, line)
  end

end
