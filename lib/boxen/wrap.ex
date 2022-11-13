defmodule Boxen.Wrap do
  @moduledoc """
  Module for wrapping text
  """
  alias Boxen.Helpers

  @escapes ["\u001B", "\u009B"]
  @end_code 39
  @ansi_escape_bell "\u0007"
  @ansi_csi "["
  @ansi_osc "]"
  @ansi_sgr_terminator "m"
  @ansi_escape_link "]8;;"

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

  defp wrap_line(line, max_line_length) do
    words =
      String.split(line, " ")
      |> Enum.reduce([], fn word, acc ->
        index = length(acc)
        acc ++ [{index, word}]
      end)

    rows =
      Enum.reduce(words, [""], fn {index, word}, rows ->
        row_length = List.last(rows) |> Helpers.text_representation_length()
        word_length = Helpers.text_representation_length(word)

        {row_length, rows} =
          if index != 0 do
            {row_length, rows} =
              if row_length >= max_line_length do
                rows = rows ++ [""]
                row_length = 0
                {row_length, rows}
              else
                {row_length, rows}
              end

            {row_length, rows} =
              if row_length > 0 do
                rows = List.update_at(rows, length(rows) - 1, fn last -> last <> " " end)
                row_length = row_length + 1
                {row_length, rows}
              else
                {row_length, rows}
              end

            {row_length, rows}
          else
            {row_length, rows}
          end

        rows =
          if word_length > max_line_length do
            remaining_length = max_line_length - row_length

            breaks_starting_this_line =
              1 + floor((word_length - remaining_length - 1) / max_line_length)

            breaks_starting_next_line = floor((word_length - 1) / max_line_length)

            rows =
              if breaks_starting_next_line < breaks_starting_this_line do
                rows ++ [""]
              else
                rows
              end

            wrap_word(rows, word, max_line_length)
          else
            if row_length + word_length > max_line_length && row_length > 0 && word_length > 0 do
              if row_length < max_line_length do
                wrap_word(rows, word, max_line_length)
              else
                rows = rows ++ [""]
                List.update_at(rows, length(rows) - 1, fn last -> last <> word end)
              end
            else
              List.update_at(rows, length(rows) - 1, fn last -> last <> word end)
            end
          end

        rows
      end)

    pre = Enum.join(rows, "\n") |> String.split("", trim: true)
    pre_length = length(pre)

    pre_with_index = convert_list_to_list_with_index(pre)

    data =
      Enum.reduce(
        pre_with_index,
        %{return_value: "", escape_code: nil, escape_url: nil},
        fn {index, character}, acc ->
          acc = Map.update!(acc, :return_value, fn return_value -> return_value <> character end)

          acc =
            if character in @escapes do
              regex = ~r/(?:\[(?<code>\d+)m|\]8;;(?<uri>.*)#{@ansi_escape_bell})/
              sliced_pre = Enum.slice(pre, index..pre_length) |> Enum.join("")
              capture = Regex.named_captures(regex, sliced_pre)

              if capture do
                acc =
                  if capture["code"] && capture["code"] != "" do
                    code = String.to_integer(capture["code"])
                    escape_code = if code == @end_code, do: nil, else: code
                    Map.update!(acc, :escape_code, fn _ -> escape_code end)
                  else
                    if capture["uri"] && capture["uri"] != "" do
                      escape_url =
                        if String.length(capture["uri"]) == 0, do: nil, else: capture["uri"]

                      Map.update!(acc, :escape_url, fn _ -> escape_url end)
                    else
                      acc
                    end
                  end

                acc
              else
                acc
              end
            else
              acc
            end

          return_value =
            if Enum.at(pre, index + 1) == "\n" do
              return_value =
                if acc.escape_url do
                  acc.return_value <> wrapAnsiHyperlink("")
                else
                  acc.return_value
                end

              return_value =
                if acc.escape_code do
                  return_value <> wrapAnsiCode(39)
                else
                  return_value
                end

              return_value
            else
              if character == "\n" do
                return_value =
                  if acc.escape_code do
                    acc.return_value <> wrapAnsiCode(acc.escape_code)
                  else
                    acc.return_value
                  end

                return_value =
                  if acc.escape_url do
                    return_value <> wrapAnsiHyperlink(acc.escape_url)
                  else
                    return_value
                  end

                return_value
              else
                acc.return_value
              end
            end

          Map.update!(acc, :return_value, fn _ -> return_value end)
        end
      )

    data.return_value
  end

  defp wrap_word(rows, word, columns) do
    characters = String.split(word, "", trim: true)
    characters_list_length = length(characters)
    characters_with_index = convert_list_to_list_with_index(characters)

    visible = List.last(rows) |> Helpers.text_representation_length()

    %{visible: visible, rows: rows} =
      Enum.reduce(
        characters_with_index,
        %{rows: rows, is_inside_escape: false, is_inside_link_escape: false, visible: visible},
        fn {index, character}, acc ->
          character_length = Helpers.text_representation_length(character)

          acc =
            if acc.visible + character_length <= columns do
              Map.update!(acc, :rows, fn rows ->
                List.replace_at(rows, length(rows) - 1, List.last(rows) <> character)
              end)
            else
              acc
              |> Map.update!(:rows, fn rows ->
                rows ++ [character]
              end)
              |> Map.update!(:visible, fn _ -> 0 end)
            end

          acc =
            if character in @escapes do
              acc
              |> Map.update!(:is_inside_escape, fn _ -> true end)
              |> Map.update!(:is_inside_link_escape, fn _ ->
                Enum.slice(characters, (index + 1)..characters_list_length)
                |> Enum.join("")
                |> String.starts_with?(@ansi_escape_link)
              end)
            else
              acc
            end

          acc =
            if acc.is_inside_escape do
              if acc.is_inside_link_escape do
                if character == @ansi_escape_bell do
                  acc
                  |> Map.update!(:is_inside_escape, fn _ -> false end)
                  |> Map.update!(:is_inside_link_escape, fn _ -> false end)
                else
                  acc
                end
              else
                if character == @ansi_sgr_terminator do
                  acc
                  |> Map.update!(:is_inside_escape, fn _ -> false end)
                else
                  acc
                end
              end
            else
              acc =
                Map.update!(acc, :visible, fn visible ->
                  visible + character_length
                end)

              if acc.visible == columns && index < characters_list_length - 1 do
                acc
                |> Map.update!(:rows, fn rows -> rows ++ [""] end)
                |> Map.update!(:visible, fn _ -> 0 end)
              else
                acc
              end
            end

          acc
        end
      )

    if visible == 0 && String.length(Enum.at(rows, length(rows) - 1)) > 0 && length(rows) > 1 do
      rows_length = length(rows)
      {last_value, rows} = List.pop_at(rows, rows_length - 1)
      List.update_at(rows, rows_length - 2, fn val -> val <> last_value end)
    else
      rows
    end
  end

  defp wrapAnsiCode(code), do: "#{Enum.at(@escapes, 0)}#{@ansi_csi}#{code}#{@ansi_sgr_terminator}"

  defp wrapAnsiHyperlink(uri),
    do: "#{Enum.at(@escapes, 0)}#{@ansi_escape_link}#{uri}#{@ansi_escape_bell}"

  defp convert_list_to_list_with_index(list) do
    Enum.reduce(list, [], fn el, index_list ->
      index = length(index_list)
      index_list ++ [{index, el}]
    end)
  end
end
