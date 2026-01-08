defmodule MobTest do
  use ExUnit.Case
  doctest Mob

  test "greets the world" do
    assert Mob.hello() == :world
  end
end
