defmodule Client.ConnectionHandler do
  use GenServer
  require Logger

  def start_link(socket) do
    Logger.info "Creating connection handler from #{inspect self}"
    GenServer.start_link(__MODULE__, %{registered: false, matched: false, player_name: nil, socket: socket})
  end

  def init(state) do
    Logger.info "Got state #{inspect state} from #{inspect self}"
    {:ok, state}
  end

  def handle_info({:tcp, socket, msg}, %{registered: registered, matched: matched} = state) do
    Logger.info("Got message for #{state.player_name} #{msg}")
    cond do
      #registered and not matched -> handle_matching(socket, msg, state)
      not registered -> handle_register(msg, state)
      true -> handle_game_event(socket, msg, state)
    end
  end

  defp handle_register(msg, state) do
    case XombiServer.Command.run(msg) do
      {:register, player_name} -> {:noreply, %{state | registered: true, player_name: player_name}}
      _ -> {:stop, :bad_register}
    end

    with {:register, player_name} <- XombiServer.Command.run(msg),
      :ok <- XombiMatch.Lobby.match(player_name),
      do: {:noreply, %{state | registered: true, player_name: player_name}}
  end

  defp handle_game_event(_socket, msg, state) do
    Logger.info("handling game event")
    case XombiServer.Command.run(msg) do
      {:move, move} -> XombiMatch.Lobby.handle_move(state.player_name, move)
      {:error, error} -> Logger.info "Bad input for move #{error}"
    end

    {:noreply, state}
  end

  def handle_cast({:matched, opponent}, state) do
    Logger.info "Got matched message"
    :gen_tcp.send(state.socket, XombiServer.Encoder.matched(state.player_name, opponent))
    {:noreply, %{state | matched: true}}
  end

  def handle_cast({:waiting, player}, state) do
    Logger.info "Got waiting message"
    {:noreply, state}
  end

  def handle_cast({:move, move}, state) do
    :gen_tcp.send(state.socket, "Player moved to #{inspect move}")
    {:noreply, state}
  end

  defp handle_matching(socket, msg, state) do
    Logger.info("Handling matching")
    XombiServer.Lobby.match(state.player_name)
      |> handle_match_response(socket, state)

    {:noreply, state}
  end

  defp handle_match_response({:waiting, player}, socket, state) do
    Logger.info "Sending waiting"
    :gen_tcp.send(socket, XombiServer.Encoder.waiting(player))
  end

  defp handle_match_response({:matched, opponent}, socket, state) do
    Logger.info "Sending matched"
    :gen_tcp.send(socket, XombiServer.Encoder.matched(state.player_name, opponent))
  end

  defp handle_match_response({:error, message}, socket, state) do
    :gen_tcp.send(socket, XombiServer.Encoder.error(message))
  end

end
