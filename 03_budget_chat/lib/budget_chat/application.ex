defmodule BudgetChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: BudgetChat.BroadcastRegistry},
      {Registry, keys: :unique, name: BudgetChat.UsernameRegistry},
      {BudgetChat.Acceptor, port: 4000}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BudgetChat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
