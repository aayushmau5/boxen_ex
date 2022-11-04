defmodule BoxenTest do
  use ExUnit.Case
  doctest Boxen

  test "greets the world" do
    assert Boxen.hello() == :world
  end
end
