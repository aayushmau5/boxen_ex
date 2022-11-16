defmodule Boxen.Helpers do
  @moduledoc """
  Helpers for manipulating text
  """

  @spec text_representation_length(text :: String.t()) :: non_neg_integer()
  def text_representation_length(text) do
    # https://github.com/sindresorhus/string-width
    # TODO: remove control characters
    text
    |> strip_ansi()
    |> remove_emoji()
    |> String.split("")
    |> Enum.reduce(0, fn
      # TODO: use regex and control characters match
      "\n", width ->
        width

      char, width ->
        width + String.length(char)
    end)
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
      # default 120 columns
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

  @doc """
  Helper method to print the directly print the result
  """
  @spec print_output(result :: {:ok, String.t()} | {:error, String.t()}) ::
          :ok | {:error, String.t()}
  def print_output(result) do
    case result do
      {:ok, box} -> IO.puts(box)
      error -> error
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
    if width_input > 0,
      do: {:ok, width_input},
      else: {:error, "Width must be greater than 0"}
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

  # Border color validation
  @spec border_color(color :: any()) :: {:ok, nil | String.t()} | {:error, String.t()}
  def border_color(color) when is_nil(color), do: {:ok, color}
  def border_color(color) when is_binary(color), do: {:ok, color}
  def border_color(_), do: {:error, "Invalid border color value"}

  # Text color validation
  @spec text_color(color :: any()) :: {:ok, nil | String.t()} | {:error, String.t()}
  def text_color(color) when is_nil(color), do: {:ok, color}
  def text_color(color) when is_binary(color), do: {:ok, color}
  def text_color(_), do: {:error, "Invalid text color value"}
end
