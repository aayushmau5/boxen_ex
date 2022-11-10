defmodule Boxen.Boxes do
  @box_types [
    :default,
    :single,
    :double,
    :round,
    :bold,
    :single_double,
    :double_single,
    :classic,
    :arrow
  ]

  @boxes [
    default: %Boxen.Box{
      top_left: " ",
      top: " ",
      top_right: " ",
      right: " ",
      bottom_right: " ",
      bottom: " ",
      bottom_left: " ",
      left: " "
    },
    single: %Boxen.Box{
      top_left: "┌",
      top: "─",
      top_right: "┐",
      right: "│",
      bottom_right: "┘",
      bottom: "─",
      bottom_left: "└",
      left: "│"
    },
    double: %Boxen.Box{
      top_left: "╔",
      top: "═",
      top_right: "╗",
      right: "║",
      bottom_right: "╝",
      bottom: "═",
      bottom_left: "╚",
      left: "║"
    },
    round: %Boxen.Box{
      top_left: "╭",
      top: "─",
      top_right: "╮",
      right: "│",
      bottom_right: "╯",
      bottom: "─",
      bottom_left: "╰",
      left: "│"
    },
    bold: %Boxen.Box{
      top_left: "┏",
      top: "━",
      top_right: "┓",
      right: "┃",
      bottom_right: "┛",
      bottom: "━",
      bottom_left: "┗",
      left: "┃"
    },
    single_double: %Boxen.Box{
      top_left: "╓",
      top: "─",
      top_right: "╖",
      right: "║",
      bottom_right: "╜",
      bottom: "─",
      bottom_left: "╙",
      left: "║"
    },
    double_single: %Boxen.Box{
      top_left: "╒",
      top: "═",
      top_right: "╕",
      right: "│",
      bottom_right: "╛",
      bottom: "═",
      bottom_left: "╘",
      left: "│"
    },
    classic: %Boxen.Box{
      top_left: "+",
      top: "-",
      top_right: "+",
      right: "|",
      bottom_right: "+",
      bottom: "-",
      bottom_left: "+",
      left: "|"
    },
    arrow: %Boxen.Box{
      top_left: "↘",
      top: "↓",
      top_right: "↙",
      right: "←",
      bottom_right: "↖",
      bottom: "↑",
      bottom_left: "↗",
      left: "→"
    }
  ]

  @type t() :: %Boxen.Box{
          top_left: String.t(),
          top: String.t(),
          top_right: String.t(),
          right: String.t(),
          bottom_right: String.t(),
          bottom: String.t(),
          bottom_left: String.t(),
          left: String.t()
        }

  @spec get_box_types() :: list()
  def get_box_types() do
    @box_types
  end

  @spec get_box(type :: atom) :: t()
  def get_box(type) when is_atom(type) do
    Keyword.get(@boxes, type, :default)
  end

  @spec setup_box(box :: t()) :: t()
  def setup_box(box) when is_map(box) do
    Map.merge(Keyword.get(@boxes, :default), box)
  end

  def setup_box(_), do: {:error, "Invalid box input"}
end
