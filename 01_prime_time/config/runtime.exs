# config/runtime.exs
import Config

config :prime_time, port: String.to_integer(System.get_env("PORT", "4000"))
