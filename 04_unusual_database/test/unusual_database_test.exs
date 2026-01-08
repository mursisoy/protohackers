defmodule UnusualDatabaseTest do
  use ExUnit.Case
  doctest UnusualDatabase

  test "greets the world" do
    assert UnusualDatabase.hello() == :world
  end
end
