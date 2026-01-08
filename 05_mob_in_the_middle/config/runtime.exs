# config/runtime.exs
import Config

config :mob,
  port: String.to_integer(System.get_env("PORT", "4000")),
  upstream_server: "chat.protohackers.com:16963"
