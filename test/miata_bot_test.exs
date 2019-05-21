defmodule MiataBotTest do
  use ExUnit.Case
  doctest MiataBot

  test "greets the world" do
    assert MiataBot.hello() == :world
  end
end
