defmodule Client.ConnectionHandler do
  use GenServer
  require Logger

  def start_link(socket) do
    GenServer.start_link(__MODULE__, %{registered: false, matched: false, player_name: nil, socket: socket})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_info({:tcp, socket, msg}, %{registered: registered, matched: matched} = state) do
    cond do
      not registered -> handle_register(msg, state)
      registered and matched -> handle_game_event(socket, msg, state)
      true -> handle_unexpected_message(socket, msg, state)
    end
  end


  def handle_info({:tcp_closed, _port}, state) do
    Logger.info "#{state.player_name} has disconnected"
    IO.puts "poop"
    {:stop, :tcp_close, state}
  end

  defp handle_unexpected_message(_socket, msg, state) do
    Logger.warn("Unexpected message #{msg}")
    {:noreply, state}
  end

  defp handle_register(msg, state) do
    # TODO currently have a problem when user connects and reconnects
    case XombiServer.Command.run(msg) do
      {:register, player_name} -> {:noreply, %{state | registered: true, player_name: player_name}}
      _ -> {:stop, :bad_register}
    end

    with {:register, player_name} <- XombiServer.Command.run(msg),
      :ok <- XombiMatch.Lobby.match(player_name)
      do
        {:noreply, %{state | registered: true, player_name: player_name}}
      end
  end

  defp handle_game_event(_socket, msg, state) do
    case XombiServer.Command.run(msg) do
      {:move, move} -> XombiMatch.Lobby.handle_move(state.player_name, move)
      {:error, error} -> Logger.warn "Bad input for move #{error}"
    end

    {:noreply, state}
  end

  def handle_cast({:matched, opponent}, state) do
    :gen_tcp.send(state.socket, XombiServer.Encoder.matched(state.player_name, opponent))
    {:noreply, %{state | matched: true}}
  end

  def handle_cast({:waiting, player}, state) do
    :gen_tcp.send(state.socket, XombiServer.Encoder.waiting(player))
    {:noreply, state}
  end

  def handle_cast({:move, player, move}, state) do
    :gen_tcp.send(state.socket, XombiServer.Encoder.moved(player, move))
    {:noreply, state}
  end

end
