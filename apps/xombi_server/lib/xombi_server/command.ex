defmodule XombiServer.Command do
  require Logger

  def expect_registration("register " <> id) do
    Logger.info "Registering #{id}"
    {:ok, String.trim(id)}
  end

  def request_match(name) do
    XombiMatch.Lobby.match(name)
  end

end
