defmodule PersonalHub.Frontmatter do
  @moduledoc """
  Parses and formats simple YAML-like frontmatter for markdown files.
  """

  @doc """
  Parses a file content string into {metadata_map, body_string}.
  """
  def parse(content) do
    case Regex.run(~r/^---\r?\n(.*?)\r?\n---\r?\n(.*)$/s, content) do
      [_, fm, body] ->
        {parse_yaml_ish(fm), String.trim_leading(body)}
      _ ->
        {%{}, content}
    end
  end

  @doc """
  Formats a metadata map and a body string into a full markdown file string.
  """
  def format(metadata, body) do
    fm =
      metadata
      |> Enum.map(fn {k, v} -> "#{k}: #{format_val(v)}" end)
      |> Enum.join("\n")

    "---\n#{fm}\n---\n#{body}"
  end

  defp parse_yaml_ish(fm_string) do
    fm_string
    |> String.split(["\r\n", "\n"], trim: true)
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, ":", parts: 2) do
        [key, val] ->
          key = String.trim(key)
          val = String.trim(val) |> parse_val()
          Map.put(acc, key, val)
        _ ->
          acc
      end
    end)
  end

  defp parse_val("true"), do: true
  defp parse_val("false"), do: false
  defp parse_val(val) do
    # Remove surrounding quotes if they exist
    val
    |> String.trim_leading("\"")
    |> String.trim_trailing("\"")
    |> String.trim_leading("'")
    |> String.trim_trailing("'")
  end

  defp format_val(true), do: "true"
  defp format_val(false), do: "false"
  defp format_val(val), do: to_string(val)
end
