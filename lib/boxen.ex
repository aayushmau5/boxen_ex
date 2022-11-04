defmodule Boxen do
  @moduledoc """
  Documentation for `Boxen`.
  """

  alias Boxen.{Boxes, Helpers}

  @padding " "

  def boxify(input_text, opts \\ []) do
    # TODO: add padding and margin properties
    # TODO: text aligment
    # TODO: usage with terminal width
    # TODO: ability to add your own box through config
    # TODO: add colors: https://hexdocs.pm/elixir/1.14.1/IO.ANSI.html

    box = Boxes.get_box(Keyword.get(opts, :box_type, :single))
    title = Keyword.get(opts, :title, nil)
    title_alignment = Keyword.get(opts, :title_alignment, :left)
    text_alignment = Keyword.get(opts, :text_alignment, :center)
    border_color = Keyword.get(opts, :border_color, :white)
    font_color = Keyword.get(opts, :font_color, :white)
    padding = Keyword.get(opts, :padding, 0) |> set_map_value()
    margin = Keyword.get(opts, :margin, 0) |> set_map_value()

    width = determine_dimension(input_text, padding: padding)

    input_text = input_text |> Helpers.strip_ansi() |> make_text(width, padding, text_alignment)

    top =
      if title do
        placeholder = String.duplicate(box.top, width)
        box.top_left <> make_title(title, placeholder, title_alignment) <> box.top_right
      else
        IO.ANSI.format([
          border_color,
          box.top_left <> String.duplicate(box.top, width) <> box.top_right
        ])
      end

    bottom =
      IO.ANSI.format([
        border_color,
        :bright,
        box.bottom_left <> String.duplicate(box.bottom, width) <> box.bottom_right
      ])

    # middle =
    #   IO.ANSI.format([border_color, box.left, font_color, input_text, border_color, box.right])

    middle =
      input_text
      |> String.split("\n")
      |> Enum.map(fn line -> box.left <> line <> box.right end)
      |> Enum.join("\n")

    Enum.join([top, middle, bottom], "\n") |> IO.puts()
  end

  defp determine_dimension(text, opts) do
    padding = Keyword.get(opts, :padding)

    # max_available_width = get_terminal_columns() - padding.left - padding.right - 2
    Helpers.widest_line(text) + padding.left + padding.right
  end

  defp make_title(title, placeholder, alignment) do
    title_width = Helpers.text_representation_length(title)
    placeholder_width = String.length(placeholder)

    case alignment do
      :left ->
        title <> String.slice(placeholder, title_width, placeholder_width)

      :right ->
        String.slice(placeholder, title_width, placeholder_width) <> title

      _ ->
        placeholder = String.slice(placeholder, title_width, placeholder_width)
        placeholder_width = String.length(placeholder)

        if rem(placeholder_width, 2) == 1 do
          placeholder =
            String.slice(
              placeholder,
              Integer.floor_div(placeholder_width, 2),
              placeholder_width
            )

          String.slice(placeholder, 1, placeholder_width) <> title <> placeholder
        else
          placeholder =
            String.slice(
              placeholder,
              div(placeholder_width, 2),
              placeholder_width
            )

          placeholder <> title <> placeholder
        end
    end
  end

  defp make_text(text, width, padding, _text_alignment) do
    lines = String.split(text, "\n")
    text_width = Helpers.widest_line(text)
    max = width - padding.left - padding.right

    padding_left = String.duplicate(@padding, padding.left)
    padding_right = String.duplicate(@padding, padding.right)

    lines = Enum.map(lines, fn line -> padding_left <> line <> padding_right end)

    lines =
      if padding.top > 0 do
        padded_lines =
          Enum.map(1..padding.top, fn _ ->
            String.duplicate(@padding, width)
          end)

        padded_lines ++ lines
      else
        lines
      end

    lines =
      if padding.bottom > 0 do
        padded_lines =
          Enum.map(1..padding.bottom, fn _ ->
            String.duplicate(@padding, width)
          end)

        lines ++ padded_lines
      else
        lines
      end

    Enum.join(lines, "\n")

    # text_width = widest_line(text)
    # max_width = terminal_columns - padding.left - padding.right

    # lines =
    #   if text_width > max_width do
    #     lines
    #   else
    #     case text_alignment do
    #       :center ->
    #         Enum.map(lines, fn line ->
    #           String.duplicate(@padding, div(max_width - text_width, 2)) <> line
    #         end)

    #       :right ->
    #         Enum.map(lines, fn line ->
    #           String.duplicate(@padding, max_width - text_width) <> line
    #         end)

    #       _ ->
    #         lines
    #     end
    #   end
  end

  defp set_map_value(val) when is_number(val) do
    %{top: val, right: val, bottom: val, left: val}
  end

  defp set_map_value(val) when is_map(val) do
    default_val = %{top: 0, right: 0, bottom: 0, left: 0}
    Map.merge(default_val, val)
  end
end
