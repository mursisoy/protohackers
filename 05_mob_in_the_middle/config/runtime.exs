# config/runtime.exs
import Config

config :mob,
  port: String.to_integer(System.get_env("PORT", "4000")),
  upstream_server: "localhost:16963"
