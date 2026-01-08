# config/runtime.exs
import Config

config :budget_chat, port: String.to_integer(System.get_env("PORT", "4000"))
