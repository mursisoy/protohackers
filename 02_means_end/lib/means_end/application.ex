defmodule MeansEnd.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: SmokeTest.Worker.start_link(arg)
      {MeansEnd.Acceptor, port: Application.fetch_env!(:means_end, :port)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MeansEnd.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
