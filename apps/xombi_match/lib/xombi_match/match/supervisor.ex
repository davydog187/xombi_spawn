defmodule XombiMatch.Match.Supervisor do
  use Supervisor

  def start_link(options) do
    Supervisor.start_link(__MODULE__, :ok, options)
  end

  def init(:ok) do
    children = [
      worker(XombiMatch.Match, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_child() do
    Supervisor.start_child(__MODULE__, [])
  end

end
