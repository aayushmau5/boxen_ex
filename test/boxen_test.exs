defmodule BoxenTest do
  use ExUnit.Case
  doctest Boxen

  test "without any args" do
    assert Boxen.boxify("hello, elixir") ==
             {:ok, "┌─────────────┐\n│hello, elixir│\n└─────────────┘"}
  end

  test "with title" do
    assert Boxen.boxify("hello, elixir", title: "Message") ==
             {:ok, "┌─────────────┐\n│hello, elixir│\n└─────────────┘"}
  end
end
