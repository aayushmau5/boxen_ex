defmodule Boxen.Helpers do
  @moduledoc """
  Helpers for manipulating text
  """

  @spec text_representation_length(text :: String.t()) :: non_neg_integer()
  def text_representation_length(text) do
    # https://github.com/sindresorhus/string-width
    # TODO: fix this function
    # TODO: handle asian characters
    # TODO: remove control characters
    text = text |> strip_ansi() |> remove_emoji()
    String.length(text)
  end

  @doc """
  Stripes ANSI characters from text
  """
  @spec strip_ansi(text :: String.t()) :: String.t()
  def strip_ansi(text) do
    # Taken from: https://github.com/chalk/strip-ansi/blob/main/index.js
    # Original regex from https://github.com/chalk/ansi-regex/blob/02fa893d619d3da85411acc8fd4e2eea0e95a9d9/index.js#L2 contained \u
    # But PCRE doesn't support \u, it uses \x instead
    # See: https://stackoverflow.com/questions/3538293/regular-expression-pcre-does-not-support-l-l-n-p
    ansi_regex =
      ~r/[\x{001B}\x{009B}][[\]()#;?]*(?:(?:(?:(?:;[-a-zA-Z\d\/#&.:=?%@~_]+)*|[a-zA-Z\d]+(?:;[-a-zA-Z\d\/#&.:=?%@~_]*)*)?\x{0007})|(?:(?:\d{1,4}(?:;\d{0,4})*)?[\dA-PR-TZcf-nq-uy=><~]))/

    String.replace(text, ansi_regex, "")
  end

  @doc """
  Removes emojis from text and replace it with 2 blank spaces
  """
  @spec remove_emoji(text :: String.t()) :: String.t()
  def remove_emoji(text) do
    emoji_regex = ~r/\p{So}/u
    Regex.replace(emoji_regex, text, "  ")
  end

  @doc """
  Gets the length of widest line in a text
  """
  @spec widest_line(text :: String.t()) :: non_neg_integer()
  def widest_line(text) do
    String.split(text, "\n")
    |> Enum.reduce(0, fn text, width ->
      max(width, text_representation_length(text))
    end)
  end

  @doc """
  Gets the terminal columns
  """
  @spec get_terminal_columns() :: pos_integer()
  def get_terminal_columns() do
    case :io.columns() do
      {:ok, width} -> width
      # default 80 columns
      {:error, _} -> 120
    end
  end

  @doc """
  Aligns a text
  """
  @spec ansi_align_text(text :: String.t(), alignment :: :left | :right | :center) :: String.t()
  def ansi_align_text(text, alignment) do
    padding = " "
    max_width = widest_line(text)

    case alignment do
      :center ->
        text
        |> String.split("\n")
        |> Enum.map(fn line ->
          padding_length = floor((max_width - text_representation_length(line)) / 2)
          String.duplicate(padding, padding_length) <> line
        end)
        |> Enum.join("\n")

      :right ->
        text
        |> String.split("\n")
        |> Enum.map(fn line ->
          padding_length = max_width - text_representation_length(line)
          String.duplicate(padding, padding_length) <> line
        end)
        |> Enum.join("\n")

      _ ->
        text
    end
  end
end

defmodule Boxen.Helpers.WrapText do
  @doc """
  Word wraps a text with ANSI escape codes
  """

  alias Boxen.Helpers

  # def wrap(text, columns) do
  #   text
  #   |> String.replace(~r/\r\n/, "\n")
  #   |> String.split("\n")
  #   |> Enum.map(fn line -> wrap_line(line, columns) end)
  #   |> Enum.join("\n")
  # end

  # def wrap_line(line, columns) do
  #   String.split(line, " ")
  #   |> Enum.with_index(fn word, index ->
  #     {index, word}
  #   end)
  #   |> Enum.reduce([''], fn {index, word}, rows ->
  #     word_length = Helpers.text_representation_length(word)

  #     row_length = Helpers.text_representation_length(rows[length(rows) - 1])

  #     # if index != 0 do
  #     #   if row_length >= columns && ()
  #     # end

  #     if word_length > columns do
  #       remaining_columns = columns - row_length
  #       breaks_starting_this_line = 1 + floor((word_length - remaining_columns - 1) / columns)
  #       breaks_starting_next_line = floor((word_length - 1) / columns)

  #       if breaks_starting_next_line < breaks_starting_this_line do
  #         rows ++ ['']
  #       end
  #     end
  #   end)
  # end

  # defp wrap_word(rows, word, columns) do
  #   characters = String.split(word)

  # end

  # def wrap(text, max_line_length) do
  #   text
  #   |> String.split("\n")
  #   |> Enum.map(fn line -> wrap_line(line, max_line_length) end)
  #   |> Enum.join("\n")
  # end

  # def wrap_line(string, max_line_length) do
  #   [word | rest] = String.split(string, ~r/\s+/, trim: true)

  #   lines_assemble(rest, max_line_length, Helpers.text_representation_length(word), word, [])
  #   |> Enum.join("\n")
  # end

  # defp lines_assemble([], max, word_length, line, acc), do: [line | acc] |> Enum.reverse()

  # defp lines_assemble([word | rest], max, word_length, line, acc) do
  #   if word_length + 1 + Helpers.text_representation_length(word) > max do
  #     lines_assemble(rest, max, Helpers.text_representation_length(word), word, [line | acc])
  #   else
  #     lines_assemble(
  #       rest,
  #       max,
  #       word_length + 1 + Helpers.text_representation_length(word),
  #       line <> " " <> word,
  #       acc
  #     )
  #   end
  # end
  # def wrap(text, max_line_length) do
  #   text
  #   |> String.split("\n")
  #   |> Enum.map(fn line -> wrap_line(line, max_line_length) end)
  #   |> Enum.join("\n")
  # end

  # def wrap_line(string, max_line_length) do
  #   [word | rest] = String.split(string, ~r/\s+/, trim: true)

  #   lines_assemble(rest, max_line_length, Helpers.text_representation_length(word), word)
  # end

  # defp lines_assemble([], max, word_length, line) do
  #   break_line(line, word_length, max)
  # end

  # defp lines_assemble([next_word | rest], max, word_length, line) do
  #   break_line(line, word_length, max) <>
  #     "\n" <>
  #     lines_assemble(
  #       rest,
  #       max,
  #       Helpers.text_representation_length(next_word),
  #       next_word
  #     )
  # end

  # defp break_line(line, word_length, max) do
  #   if word_length > max do
  #     {first, second} = String.split_at(line, max)
  #     first <> "\n" <> break_line(second, Helpers.text_representation_length(second), max)
  #   else
  #     line
  #   end
  # end

  def wrap(text, max_line_length) do
    text
    |> String.split("\n", trim: true)
    |> Enum.map(fn line -> wrap_line(line, max_line_length) end)
    |> Enum.join("\n")
  end

  def wrap_line(string, max_line_length) do
    [word | rest] = String.split(string, ~r/\s+/, trim: true)
    break_line(word, Helpers.text_representation_length(word), max_line_length, rest)
  end

  defp break_line(word, word_length, max, []) do
    if word_length > max do
      {first, second} = String.split_at(word, max)
      first <> "\n" <> break_line(second, Helpers.text_representation_length(second), max, [])
    else
      word
    end
  end

  defp break_line(word, word_length, max, next_words) do
    if word_length > max do
      {first, second} = String.split_at(word, max)

      first <>
        "\n" <> break_line(second, Helpers.text_representation_length(second), max, next_words)
    else
      [next_word | rest] = next_words
      next_word_length = Helpers.text_representation_length(next_word)
      combined_word_length = word_length + 1 + next_word_length
      combined_word = word <> " " <> next_word

      break_line(combined_word, combined_word_length, max, rest)
    end
  end
end
