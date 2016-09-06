defmodule XombiServer do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Task.Supervisor, [[name: XombiServer.ConnectionSupervisor]]),
      supervisor(Client.Supervisor, [[name: Client.Supervisor]]),
      worker(XombiServer.GameServer, [4040], name: GameServer),
      #worker(XombiServer.SocketTable, []),
      supervisor(XombiMatch.Match.Supervisor, [[name: XombiMatch.Match.Supervisor]]),
      worker(XombiMatch.Lobby, []),
    ]


    opts = [strategy: :one_for_one, name: XombiServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
