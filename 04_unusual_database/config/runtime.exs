# config/runtime.exs
import Config

config :unusual_database, port: String.to_integer(System.get_env("PORT", "4000"))
