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
      {:error, _} -> 80
    end
  end

  def hard_wrap_text(text, max_width) do
    # TODO: implement this function
  end
end
