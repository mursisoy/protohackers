# config/runtime.exs
import Config

config :means_end, port: String.to_integer(System.get_env("PORT", "4000"))
