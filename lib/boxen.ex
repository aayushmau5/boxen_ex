defmodule Boxen do
  @moduledoc """
  Documentation for `Boxen`.
  """

  alias Boxen.{Boxes, Helpers, WrapText, Helpers.Validate}

  @padding " "
  @borders_width 2
  @newline "\n"

  @doc ~S"""
  Function to boxify a given text.

  Opts:
  - `:box_type`
  - `:box`
  - `:title`
  - `:title_alignment`
  - `:text_alignment`
  - `:padding`
  - `:margin`
  - `:width`
  - `:border_color`
  - `:text_color`
      
  Example:
  
  Simple: Boxen.boxify("Hello, world")
  
  With title: Boxen.boxify("Hello, world", title: "Message")
  """
  @spec boxify(input_text :: String.t(), opts :: keyword()) ::
          {:ok, String.t()} | {:error, String.t()}
  def boxify(input_text, opts \\ []) do
    # TODO: tests and get library ready(smaller functions, more comments, docs, readme, etc.)

    box_type = Keyword.get(opts, :box_type, :single)
    new_box = Keyword.get(opts, :box, nil)
    title = Keyword.get(opts, :title, nil)
    title_alignment = Keyword.get(opts, :title_alignment, :left)
    text_alignment = Keyword.get(opts, :text_alignment, :left)
    padding = Keyword.get(opts, :padding, 0)
    margin = Keyword.get(opts, :margin, 0)
    width = Keyword.get(opts, :width, nil)
    border_color = Keyword.get(opts, :border_color, nil)
    text_color = Keyword.get(opts, :text_color, nil)

    with {:ok, input_text} <- Validate.input_text(input_text),
         {:ok, new_box} <- Validate.box_input(new_box),
         {:ok, box_type} <- Validate.box_type(box_type),
         {:ok, title} <- Validate.title(title),
         {:ok, title_alignment} <- Validate.title_alignment(title_alignment),
         {:ok, text_alignment} <- Validate.text_alignment(text_alignment),
         {:ok, padding} <- Validate.padding(padding),
         {:ok, margin} <- Validate.margin(margin),
         {:ok, width} <- Validate.width(width),
         {:ok, border_color} <-
           Validate.border_color(border_color),
         {:ok, text_color} <- Validate.text_color(text_color) do
      padding = set_map_value(padding)
      margin = set_map_value(margin)

      {width, margin, title} =
        determine_dimension(input_text,
          padding: padding,
          margin: margin,
          width: width,
          title: title
        )

      padding = prevent_padding_overflow(width, padding)

      input_text =
        input_text
        |> apply_text_color(text_color)
        |> make_text(width, padding, text_alignment)

      # Arg `:box` overrides `:box_type`
      box =
        if new_box do
          Boxes.setup_box(new_box)
        else
          Boxes.get_box(box_type)
        end

      box =
        if border_color do
          apply_border_color(box, border_color)
        else
          box
        end

      {:ok,
       box_content(box, input_text,
         width: width,
         title: title,
         title_alignment: title_alignment,
         margin: margin,
         border_color: border_color
       )}
    else
      error -> error
    end
  end

  defp determine_dimension(text, opts) do
    padding = Keyword.get(opts, :padding)
    margin = Keyword.get(opts, :margin)
    width = Keyword.get(opts, :width)
    title = Keyword.get(opts, :title)
    columns = Helpers.get_terminal_columns()

    width_override? = width != nil
    max_width = columns - margin.left - margin.right - @borders_width

    widest =
      Helpers.widest_line(WrapText.wrap(Helpers.strip_ansi(text), columns - @borders_width)) +
        padding.left +
        padding.right

    title =
      if title do
        if width_override? do
          title = String.slice(title, 0, max(0, width - 2))
          if String.length(title) != 0, do: " #{title} ", else: title
        else
          title = String.slice(title, 0, max(0, max_width - 2))
          if String.length(title) != 0, do: " #{title} ", else: title
        end
      else
        title
      end

    title_width = if title, do: Helpers.text_representation_length(title), else: 0
    width = if width_override? && title_width > widest, do: title_width, else: width
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

    {width, margin_change, title}
  end

  defp make_title(title, placeholder, alignment, border_color) do
    title_width = Helpers.text_representation_length(title)
    # removes ANSI color codes from placeholder
    placeholder = Helpers.strip_ansi(placeholder)
    placeholder_width = String.length(placeholder)
    placeholder = String.slice(placeholder, title_width, placeholder_width)
    reset = if border_color, do: IO.ANSI.reset(), else: ""
    border_color = if border_color, do: border_color, else: ""

    case alignment do
      :left ->
        title <> border_color <> placeholder <> reset

      :right ->
        border_color <> placeholder <> reset <> title

      _ ->
        placeholder_width = String.length(placeholder)

        if rem(placeholder_width, 2) == 1 do
          placeholder =
            String.slice(
              placeholder,
              Integer.floor_div(placeholder_width, 2),
              placeholder_width
            )

          left_placeholder =
            border_color <> String.slice(placeholder, 1, placeholder_width) <> reset

          right_placeholder = border_color <> placeholder <> reset

          left_placeholder <> title <> right_placeholder
        else
          placeholder =
            String.slice(
              placeholder,
              div(placeholder_width, 2),
              placeholder_width
            )

          placeholder = border_color <> placeholder <> reset

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
            |> WrapText.wrap(max)
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

  defp box_content(box, text, opts) do
    content_width = Keyword.get(opts, :width)
    margin = Keyword.get(opts, :margin)
    title = Keyword.get(opts, :title)
    title_alignment = Keyword.get(opts, :title_alignment)
    border_color = Keyword.get(opts, :border_color)
    columns = Helpers.get_terminal_columns()

    margin_top = String.duplicate(@newline, margin.top)
    margin_bottom = String.duplicate(@newline, margin.bottom)
    margin_left = String.duplicate(@padding, margin.left)

    title =
      if title do
        placeholder = String.duplicate(box.top, content_width)
        make_title(title, placeholder, title_alignment, border_color)
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

  defp apply_border_color(box, color) do
    %Boxen.Box{
      top_left: color <> box.top_left <> IO.ANSI.reset(),
      top: color <> box.top <> IO.ANSI.reset(),
      top_right: color <> box.top_right <> IO.ANSI.reset(),
      right: color <> box.right <> IO.ANSI.reset(),
      bottom_right: color <> box.bottom_right <> IO.ANSI.reset(),
      bottom: color <> box.bottom <> IO.ANSI.reset(),
      bottom_left: color <> box.bottom_left <> IO.ANSI.reset(),
      left: color <> box.left <> IO.ANSI.reset()
    }
  end

  defp apply_text_color(text, color) do
    if color do
      # text_color overrides colors already present in text
      text = Helpers.strip_ansi(text)
      color <> text <> IO.ANSI.reset()
    else
      text
    end
  end

  defp set_map_value(val) when is_number(val) do
    %{top: val, right: val * 3, bottom: val, left: val * 3}
  end

  defp set_map_value(val) when is_map(val) do
    default_val = %{top: 0, right: 0, bottom: 0, left: 0}
    Map.merge(default_val, val)
  end
end
