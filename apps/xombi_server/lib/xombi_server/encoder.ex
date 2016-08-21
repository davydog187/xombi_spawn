defmodule XombiServer.Encoder do
  @error 0
  @waiting 1
  @matched 2
  @moved 3

  def waiting(user) do
    encode(@waiting, %{waiting: true, name: user})
  end

  def error(message) do
    encode(@error, message)
  end

  def matched(player, opponents) do
    encode(@matched, %{ name: player, opponents: opponents})
  end

  def moved() do
    encode(@moved, %{})
  end

  defp encode(type, message) do
    Poison.encode!(%{ msgType: type, message: message })
  end

end
