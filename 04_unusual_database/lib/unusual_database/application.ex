defmodule UnusualDatabase.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: SmokeTest.Worker.start_link(arg)
      {UnusualDatabase.Database, %{}},
      {UnusualDatabase.Server, port: Application.fetch_env!(:unusual_database, :port)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UnusualDatabase.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
