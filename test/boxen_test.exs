defmodule BoxenTest do
  use ExUnit.Case, async: true
  doctest Boxen

  test "without any args" do
    assert Boxen.boxify("hello, elixir") ==
             {:ok, "┌─────────────┐\n│hello, elixir│\n└─────────────┘"}
  end

  test "with title" do
    assert Boxen.boxify("hello, elixir", title: "Message") ==
             {:ok, "┌ Message ────┐\n│hello, elixir│\n└─────────────┘"}
  end

  test "with title and title aligment center" do
    assert Boxen.boxify("hello, elixir", title: "Message", title_alignment: :center) ==
             {:ok, "┌── Message ──┐\n│hello, elixir│\n└─────────────┘"}
  end

  test "with title and title aligment right" do
    assert Boxen.boxify("hello, elixir", title: "Message", title_alignment: :right) ==
             {:ok, "┌──── Message ┐\n│hello, elixir│\n└─────────────┘"}
  end

  test "with wrong title type" do
    assert Boxen.boxify("hello, elixir", title: 2) == {:error, "Title must be nil or a string"}
  end

  test "with padding as integer value" do
    assert Boxen.boxify("hello, elixir", padding: 1) ==
             {:ok,
              "┌───────────────────┐\n│                   │\n│   hello, elixir   │\n│                   │\n└───────────────────┘"}
  end

  test "with padding as map value" do
    assert Boxen.boxify("hello, elixir", padding: %{top: 1, bottom: 2, left: 0, right: 1}) ==
             {:ok,
              "┌──────────────┐\n│              │\n│hello, elixir │\n│              │\n│              │\n└──────────────┘"}
  end

  test "with margin as integer value" do
    assert Boxen.boxify("hello, elixir", margin: 1) ==
             {:ok, "\n   ┌─────────────┐\n   │hello, elixir│\n   └─────────────┘\n"}
  end

  test "with margin as map value" do
    assert Boxen.boxify("hello, elixir", margin: %{top: 1, bottom: 2, left: 0, right: 1}) ==
             {:ok, "\n┌─────────────┐\n│hello, elixir│\n└─────────────┘\n\n"}
  end

  test "with width > text width" do
    assert Boxen.boxify("hello, elixir", width: 80) ==
             {:ok,
              "┌────────────────────────────────────────────────────────────────────────────────┐\n│hello, elixir                                                                   │\n└────────────────────────────────────────────────────────────────────────────────┘"}
  end

  test "with width < text width" do
    assert Boxen.boxify("hello, elixir", width: 4) ==
             {:ok, "┌────┐\n│hell│\n│o,  │\n│elix│\n│ir  │\n└────┘"}
  end

  test "with width == 1" do
    assert Boxen.boxify("hello, elixir", width: 1) ==
             {:ok, "┌─┐\n│h│\n│e│\n│l│\n│l│\n│o│\n│,│\n│e│\n│l│\n│i│\n│x│\n│i│\n│r│\n└─┘"}
  end

  test "with rounded box" do
    assert Boxen.boxify("hello, elixir", box: :round) ==
             {:ok, "╭─────────────╮\n│hello, elixir│\n╰─────────────╯"}
  end

  test "with custom box" do
    assert Boxen.boxify("hello, elixir",
             box: %{
               top_left: "|",
               top: "|",
               top_right: "|",
               right: "|",
               bottom_right: "|",
               bottom: "|",
               bottom_left: "|",
               left: "|"
             }
           ) ==
             {:ok, "|||||||||||||||\n|hello, elixir|\n|||||||||||||||"}
  end

  test "with border color" do
    red = IO.ANSI.red()

    assert Boxen.boxify("hello, elixir", border_color: red) ==
             {:ok,
              "\e[31m┌\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m┐\e[0m\n\e[31m│\e[0mhello, elixir\e[31m│\e[0m\n\e[31m└\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m┘\e[0m"}
  end

  test "with text color" do
    blue = IO.ANSI.blue()

    assert Boxen.boxify("hello, elixir", text_color: blue) ==
             {:ok, "┌─────────────┐\n│\e[34mhello, elixir\e[0m│\n└─────────────┘"}
  end

  test "with text and border_color color" do
    red = IO.ANSI.red()
    blue = IO.ANSI.blue()

    assert Boxen.boxify("hello, elixir", text_color: blue, border_color: red) ==
             {:ok,
              "\e[31m┌\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m┐\e[0m\n\e[31m│\e[0m\e[34mhello, elixir\e[0m\e[31m│\e[0m\n\e[31m└\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m─\e[0m\e[31m┘\e[0m"}
  end

  test "with custom text color" do
    text = IO.ANSI.format([:red, "Hello, ", :blue, "elixir"]) |> IO.chardata_to_string()

    assert Boxen.boxify(text) ==
             {:ok, "┌─────────────┐\n│\e[31mHello, \e[34melixir\e[0m│\n└─────────────┘"}
  end
end
