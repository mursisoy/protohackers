defmodule UnusualDatabase.Database do
  use Agent

  def start_link(initial_value) when is_map(initial_value) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key, ""))
  end

  def set(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end
end
