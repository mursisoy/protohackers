# config/runtime.exs
import Config

config :smoke_test, port: String.to_integer(System.get_env("PORT", "4000"))
