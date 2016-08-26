defmodule XombiMatch.Match.Supervisor do
  use Supervisor

  def start_link(options) do
    Supervisor.start_link(__MODULE__, :ok, options)
  end

  def init(:ok) do
    children = []

    supervise(children, strategy: :one_for_one)
  end

  def start_child() do
    Supervisor.start_child(__MODULE__, worker(XombiMatch.Match, []))
  end

end
