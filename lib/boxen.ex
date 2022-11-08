defmodule Boxen do
  @moduledoc """
  Documentation for `Boxen`.
  """

  alias Boxen.{Boxes, Helpers, Helpers.WrapText}

  @padding " "
  @borders_width 2
  @newline "\n"

  # @spec boxify(binary, keyword) :: {:ok, binary()} | {:error, binary()}
  def boxify(input_text, opts \\ []) do
    # TODO: usage with terminal width(wrapping, etc.)
    # TODO: deal with title and width
    # TODO: ability to add your own box through opts
    # TODO: add colors: https://hexdocs.pm/elixir/1.14.1/IO.ANSI.html
    # TODO: ability to change line height(for livebook)
    # TODO: return {:ok, text} or {:error, reason} response
    # TODO: make livebook compatible(with width, etc)
    # TODO: suitable error for non-existing box
    # TODO: replace string.duplice with String.pad_leading() | String.pad_trailing()

    box = Boxes.get_box(Keyword.get(opts, :box_type, :single))
    title = Keyword.get(opts, :title, nil)
    title_alignment = Keyword.get(opts, :title_alignment, :left)
    text_alignment = Keyword.get(opts, :text_alignment, :left)
    # border_color = Keyword.get(opts, :border_color, :white)
    # font_color = Keyword.get(opts, :font_color, :white)
    padding = Keyword.get(opts, :padding, 0) |> set_map_value()
    margin = Keyword.get(opts, :margin, 0) |> set_map_value()
    width = Keyword.get(opts, :width, nil)

    {width, margin} =
      determine_dimension(input_text, padding: padding, margin: margin, width: width)

    padding = prevent_padding_overflow(width, padding)

    input_text = input_text |> Helpers.strip_ansi() |> make_text(width, padding, text_alignment)

    box_content(box, input_text,
      width: width,
      title: title,
      title_alignment: title_alignment,
      margin: margin
    )
    |> IO.puts()
  end

  defp determine_dimension(text, opts) do
    padding = Keyword.get(opts, :padding)
    margin = Keyword.get(opts, :margin)
    width = Keyword.get(opts, :width)
    columns = Helpers.get_terminal_columns()

    width_override? = width != nil
    max_width = columns - margin.left - margin.right - @borders_width

    widest =
      Helpers.widest_line(WrapText.wrap(text, columns - @borders_width)) + padding.left +
        padding.right

    width = if width_override?, do: width, else: widest

    margin_change =
      if !width_override? && (margin.left != 0 && margin.right != 0) && width > max_width do
        space_for_margins = columns - width - @borders_width
        multiplier = space_for_margins / margin.left + margin.right
        margin_left = max(0, floor(margin.left * multiplier))
        margin_right = max(0, floor(margin.right * multiplier))
        Map.merge(margin, %{left: margin_left, right: margin_right})
      else
        margin
      end

    width =
      if !width_override? do
        min(width, columns - @borders_width - margin_change.left - margin_change.right)
      else
        width
      end

    {width, margin_change}
  end

  defp make_title(title, placeholder, alignment) do
    title = " #{title} "
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

  defp make_text(text, width, padding, text_alignment) do
    text = Helpers.ansi_align_text(text, text_alignment)
    lines = String.split(text, @newline)
    text_width = Helpers.widest_line(text)
    max = width - padding.left - padding.right

    lines =
      if text_width > max do
        Enum.reduce(lines, [], fn line, acc ->
          aligned_lines =
            line
            |> WrapText.wrap_line(max)
            |> Helpers.ansi_align_text(text_alignment)
            |> String.split("\n")

          longest_length =
            Enum.reduce(aligned_lines, 0, fn text, width ->
              max(width, Helpers.text_representation_length(text))
            end)

          lines =
            Enum.map(aligned_lines, fn line ->
              case text_alignment do
                :right -> String.duplicate(@padding, max - longest_length) <> line
                :center -> String.duplicate(@padding, div(max - longest_length, 2)) <> line
                _ -> line
              end
            end)

          acc ++ lines
        end)
      else
        lines
      end

    lines =
      if text_width < max do
        case text_alignment do
          :right ->
            Enum.map(lines, fn line ->
              String.duplicate(@padding, max - text_width) <> line
            end)

          :center ->
            Enum.map(lines, fn line ->
              String.duplicate(@padding, div(max - text_width, 2)) <> line
            end)

          _ ->
            lines
        end
      else
        lines
      end

    padding_left = String.duplicate(@padding, padding.left)
    padding_right = String.duplicate(@padding, padding.right)

    lines =
      lines
      |> Enum.map(fn line -> padding_left <> line <> padding_right end)
      |> Enum.map(fn line ->
        # never go less than 0
        remaining_width = max(width - Helpers.text_representation_length(line), 0)
        line <> String.duplicate(@padding, remaining_width)
      end)

    # Add top padding
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

    # Add bottom padding
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

    Enum.join(lines, @newline)
  end

  defp prevent_padding_overflow(width, padding) do
    remaining_width = width - padding.left - padding.right

    if remaining_width <= 0 do
      Map.merge(padding, %{left: 0, right: 0})
    else
      padding
    end
  end

  defp set_map_value(val) when is_number(val) do
    %{top: val, right: val * 3, bottom: val, left: val * 3}
  end

  defp set_map_value(val) when is_map(val) do
    default_val = %{top: 0, right: 0, bottom: 0, left: 0}
    Map.merge(default_val, val)
  end

  defp box_content(box, text, opts) do
    content_width = Keyword.get(opts, :width)
    margin = Keyword.get(opts, :margin)
    title = Keyword.get(opts, :title)
    title_alignment = Keyword.get(opts, :title_alignment)
    columns = Helpers.get_terminal_columns()

    margin_top = String.duplicate(@newline, margin.top)
    margin_bottom = String.duplicate(@newline, margin.bottom)
    margin_left = String.duplicate(@padding, margin.left)

    title =
      if title do
        placeholder = String.duplicate(box.top, content_width)
        make_title(title, placeholder, title_alignment)
      else
        String.duplicate(box.top, content_width)
      end

    top = margin_top <> margin_left <> box.top_left <> title <> box.top_right

    bottom =
      margin_left <>
        box.bottom_left <>
        String.duplicate(box.bottom, content_width) <> box.bottom_right <> margin_bottom

    line_separator =
      if content_width + @borders_width + margin.left >= columns do
        ""
      else
        "\n"
      end

    middle =
      text
      |> String.split(@newline)
      |> Enum.map(fn line -> margin_left <> box.left <> line <> box.right end)
      |> Enum.join(line_separator)

    Enum.join([top, middle, bottom], line_separator)
  end
end
