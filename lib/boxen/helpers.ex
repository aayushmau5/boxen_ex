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
  @moduledoc """
  Module for wrapping text
  """
  alias Boxen.Helpers

  @doc """
  Wraps a given text inside the given max length

  This function can take multiple lines separated by `\n`
  """
  @spec wrap(text :: String.t(), max_line_length :: non_neg_integer()) :: String.t()
  def wrap(text, max_line_length) do
    text
    |> String.split("\n", trim: true)
    |> Enum.map(fn line -> wrap_line(line, max_line_length) end)
    |> Enum.join("\n")
  end

  defp wrap_line(string, max_line_length) do
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

defmodule Boxen.Helpers.Validate do
  # Title validation
  @spec title(title_input :: any()) :: {:ok, nil | String.t()} | {:error, String.t()}
  def title(title_input) when is_nil(title_input), do: {:ok, title_input}
  def title(title_input) when is_binary(title_input), do: {:ok, title_input}
  def title(_), do: {:error, "Title must be nil or a string"}

  # Title alignment validation
  @spec title_alignment(alignment :: any()) :: {:ok, atom()} | {:error, String.t()}
  def title_alignment(alignment) when alignment in [:left, :center, :right], do: {:ok, alignment}
  def title_alignment(_), do: {:error, "Invalid title alignment input"}

  # Input text validation
  @spec input_text(text :: any()) :: {:ok, String.t()} | {:error, String.t()}
  def input_text(text) when is_binary(text), do: {:ok, text}
  def input_text(text) when is_integer(text), do: {:ok, Integer.to_string(text)}
  def input_text(_), do: {:error, "Invalid input value"}

  # Input text alignment validation
  @spec text_alignment(alignment :: any()) :: {:ok, atom()} | {:error, String.t()}
  def text_alignment(alignment) when alignment in [:left, :center, :right], do: {:ok, alignment}
  def text_alignment(_), do: {:error, "Invalid alignment value"}

  # Padding validation
  @spec padding(padding_input :: any()) :: {:ok, integer() | map()} | {:error, String.t()}
  def padding(padding_input) when is_map(padding_input), do: {:ok, padding_input}

  def padding(padding_input) when is_integer(padding_input) do
    if padding_input >= 0,
      do: {:ok, padding_input},
      else: {:error, "Padding must be a positive value"}
  end

  def padding(_), do: {:error, "Invalid padding value"}

  # Margin validation
  @spec margin(margin_input :: any()) :: {:ok, integer() | map()} | {:error, String.t()}
  def margin(margin_input) when is_map(margin_input), do: {:ok, margin_input}

  def margin(margin_input) when is_integer(margin_input) do
    if margin_input >= 0,
      do: {:ok, margin_input},
      else: {:error, "Margin must be a positive value"}
  end

  def margin(_), do: {:error, "Invalid margin value"}

  # Width validation
  @spec width(width_input :: any()) :: {:ok, nil | integer()} | {:error, String.t()}
  def width(width_input) when is_nil(width_input), do: {:ok, width_input}

  def width(width_input) when is_integer(width_input) do
    if width_input >= 0, do: {:ok, width_input}, else: {:error, "Width must be a positive value"}
  end

  def width(_), do: {:error, "Invalid margin value"}

  # Box type validation
  @spec box_type(box_input :: any()) :: {:ok, atom()} | {:error, String.t()}
  def box_type(box_input) when is_atom(box_input) do
    if box_input in Boxen.Boxes.get_box_types() do
      {:ok, box_input}
    else
      {:error, "Box type doesn't exist by default."}
    end
  end

  def box_type(_), do: {:error, "Invalid box type value"}

  # Box input validation
  @spec box_input(box :: any()) :: {:ok, nil | map()} | {:error, String.t()}
  def box_input(box) when is_nil(box), do: {:ok, box}
  def box_input(box) when is_map(box), do: {:ok, box}
  def box_input(_), do: {:error, "Invalid box value"}
end
