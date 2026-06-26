defmodule PersonalHub.Markdown do
  @moduledoc """
  Pure Elixir Markdown → HTML converter.

  Supports: headings, bold, italic, strikethrough, inline code, fenced code blocks,
  blockquotes, horizontal rules, ordered/unordered lists, links, images, tables,
  embedded videos (YouTube/Vimeo), and audio (!audio[caption](url)).
  """

  @doc """
  Converts a Markdown string to an HTML string.
  Returns `{:safe, html}` for direct Phoenix rendering.
  """
  def to_html(nil), do: {:safe, ""}
  def to_html(""), do: {:safe, ""}

  def to_html(markdown) when is_binary(markdown) do
    html =
      markdown
      |> String.replace("\r\n", "\n")
      |> parse_blocks()
      |> Enum.map(&render_block/1)
      |> Enum.join("\n")

    {:safe, html}
  end

  @doc """
  Like to_html/1 but returns raw HTML string (no {:safe, ...} wrapper).
  """
  def to_html_raw(nil), do: ""
  def to_html_raw(""), do: ""

  def to_html_raw(markdown) do
    markdown
    |> String.replace("\r\n", "\n")
    |> parse_blocks()
    |> Enum.map(&render_block/1)
    |> Enum.join("\n")
  end

  # ── Block Parser ──────────────────────────────────────────────

  defp parse_blocks(text) do
    text
    |> String.split("\n")
    |> parse_lines([])
    |> Enum.reverse()
  end

  defp parse_lines([], acc), do: acc

  # Fenced code blocks
  defp parse_lines(["```" <> lang | rest], acc) do
    {code_lines, remaining} = take_until_fence(rest, [])
    lang = String.trim(lang)
    block = {:code_block, lang, Enum.join(code_lines, "\n")}
    parse_lines(remaining, [block | acc])
  end

  # Tables (detect by | in current line AND next line having |---|)
  defp parse_lines([line | rest], acc) when is_binary(line) do
    cond do
      # Horizontal rule
      String.match?(line, ~r/^\s*([-*_])\s*\1\s*\1[\s\1]*$/) and String.trim(line) != "" ->
        parse_lines(rest, [{:hr} | acc])

      # Heading
      match = Regex.run(~r/^(\#{1,6})\s+(.+)$/, line) ->
        [_, hashes, text] = match
        level = String.length(hashes)
        parse_lines(rest, [{:heading, level, String.trim(text)} | acc])

      # Table detection
      is_table_start?(line, rest) ->
        {table_lines, remaining} = take_table_lines([line | rest], [])
        block = parse_table(table_lines)
        parse_lines(remaining, [block | acc])

      # Blockquote
      String.match?(line, ~r/^>\s?/) ->
        {bq_lines, remaining} = take_blockquote([line | rest], [])
        content = Enum.join(bq_lines, "\n")
        parse_lines(remaining, [{:blockquote, content} | acc])

      # Unordered list
      String.match?(line, ~r/^\s*[-*+]\s+/) ->
        {list_items, remaining} = take_unordered_list([line | rest], [])
        parse_lines(remaining, [{:ul, list_items} | acc])

      # Ordered list
      String.match?(line, ~r/^\s*\d+\.\s+/) ->
        {list_items, remaining} = take_ordered_list([line | rest], [])
        parse_lines(remaining, [{:ol, list_items} | acc])

      # Empty line
      String.trim(line) == "" ->
        parse_lines(rest, acc)

      # Paragraph
      true ->
        {para_lines, remaining} = take_paragraph([line | rest], [])
        text = Enum.join(para_lines, "\n")
        parse_lines(remaining, [{:paragraph, text} | acc])
    end
  end

  # ── Fenced code fence collection ──────────────────────────────

  defp take_until_fence([], acc), do: {Enum.reverse(acc), []}

  defp take_until_fence(["```" <> _ | rest], acc) do
    {Enum.reverse(acc), rest}
  end

  defp take_until_fence([line | rest], acc) do
    take_until_fence(rest, [line | acc])
  end

  # ── Blockquote collection ─────────────────────────────────────

  defp take_blockquote([], acc), do: {Enum.reverse(acc), []}

  defp take_blockquote([line | rest], acc) do
    if String.match?(line, ~r/^>\s?/) do
      stripped = Regex.replace(~r/^>\s?/, line, "")
      take_blockquote(rest, [stripped | acc])
    else
      {Enum.reverse(acc), [line | rest]}
    end
  end

  # ── Unordered list collection ─────────────────────────────────

  defp take_unordered_list([], acc), do: {Enum.reverse(acc), []}

  defp take_unordered_list([line | rest], acc) do
    if String.match?(line, ~r/^\s*[-*+]\s+/) do
      item = Regex.replace(~r/^\s*[-*+]\s+/, line, "")
      take_unordered_list(rest, [item | acc])
    else
      {Enum.reverse(acc), [line | rest]}
    end
  end

  # ── Ordered list collection ───────────────────────────────────

  defp take_ordered_list([], acc), do: {Enum.reverse(acc), []}

  defp take_ordered_list([line | rest], acc) do
    if String.match?(line, ~r/^\s*\d+\.\s+/) do
      item = Regex.replace(~r/^\s*\d+\.\s+/, line, "")
      take_ordered_list(rest, [item | acc])
    else
      {Enum.reverse(acc), [line | rest]}
    end
  end

  # ── Paragraph collection ──────────────────────────────────────

  defp take_paragraph([], acc), do: {Enum.reverse(acc), []}

  defp take_paragraph([line | rest], acc) do
    cond do
      String.trim(line) == "" ->
        {Enum.reverse(acc), rest}

      String.match?(line, ~r/^\#{1,6}\s+/) ->
        {Enum.reverse(acc), [line | rest]}

      String.match?(line, ~r/^>\s?/) ->
        {Enum.reverse(acc), [line | rest]}

      String.match?(line, ~r/^\s*[-*+]\s+/) ->
        {Enum.reverse(acc), [line | rest]}

      String.match?(line, ~r/^\s*\d+\.\s+/) ->
        {Enum.reverse(acc), [line | rest]}

      String.match?(line, ~r/^\s*([-*_])\s*\1\s*\1[\s\1]*$/) ->
        {Enum.reverse(acc), [line | rest]}

      String.starts_with?(line, "```") ->
        {Enum.reverse(acc), [line | rest]}

      true ->
        take_paragraph(rest, [line | acc])
    end
  end

  # ── Table detection & parsing ─────────────────────────────────

  defp is_table_start?(line, [next | _]) do
    String.contains?(line, "|") and String.match?(next, ~r/^\|?\s*[-:]+[-| :]*$/)
  end

  defp is_table_start?(_, _), do: false

  defp take_table_lines([], acc), do: {Enum.reverse(acc), []}

  defp take_table_lines([line | rest], acc) do
    if String.contains?(line, "|") and String.trim(line) != "" do
      take_table_lines(rest, [line | acc])
    else
      {Enum.reverse(acc), [line | rest]}
    end
  end

  defp parse_table([header_line, _separator | body_lines]) do
    headers = parse_table_row(header_line)
    rows = Enum.map(body_lines, &parse_table_row/1)
    {:table, headers, rows}
  end

  defp parse_table([header_line, _separator]) do
    headers = parse_table_row(header_line)
    {:table, headers, []}
  end

  defp parse_table(lines) do
    rows = Enum.map(lines, &parse_table_row/1)
    {:table, List.first(rows) || [], Enum.drop(rows, 1)}
  end

  defp parse_table_row(line) do
    line
    |> String.trim()
    |> String.trim("|")
    |> String.split("|")
    |> Enum.map(&String.trim/1)
  end

  # ── Block Renderers ───────────────────────────────────────────

  defp render_block({:heading, level, text}) do
    tag = "h#{level}"
    "<#{tag}>#{inline(text)}</#{tag}>"
  end

  defp render_block({:paragraph, text}) do
    # Check for special embeds before wrapping in <p>
    trimmed = String.trim(text)

    cond do
      # Audio embed: !audio[caption](url)
      match = Regex.run(~r/^!audio\[([^\]]*)\]\(([^)]+)\)$/, trimmed) ->
        [_, caption, url] = match
        render_audio(caption, url)

      # Standalone image on its own line → render as figure, not inside <p>
      match = Regex.run(~r/^!\[([^\]]*)\]\(([^)]+)\)$/, trimmed) ->
        [_, alt, src] = match
        ~s(<figure class="blog-figure"><img src="#{escape(src)}" alt="#{escape(alt)}" loading="lazy"><figcaption>#{escape(alt)}</figcaption></figure>)

      # YouTube/Vimeo URL on its own line
      is_video_url?(trimmed) ->
        render_video_embed(trimmed)

      true ->
        "<p>#{inline(text)}</p>"
    end
  end

  defp render_block({:code_block, lang, code}) do
    lang_attr = if lang != "", do: ~s( class="language-#{escape(lang)}"), else: ""
    lang_label = if lang != "", do: ~s(<span class="code-lang">#{escape(lang)}</span>), else: ""
    "#{lang_label}<pre><code#{lang_attr}>#{escape(code)}</code></pre>"
  end

  defp render_block({:blockquote, content}) do
    inner = to_html_raw(content)
    "<blockquote>#{inner}</blockquote>"
  end

  defp render_block({:ul, items}) do
    lis = Enum.map(items, fn item -> "<li>#{inline(item)}</li>" end)
    "<ul>#{Enum.join(lis, "\n")}</ul>"
  end

  defp render_block({:ol, items}) do
    lis = Enum.map(items, fn item -> "<li>#{inline(item)}</li>" end)
    "<ol>#{Enum.join(lis, "\n")}</ol>"
  end

  defp render_block({:hr}) do
    "<hr>"
  end

  defp render_block({:table, headers, rows}) do
    thead =
      "<thead><tr>" <>
        (Enum.map(headers, fn h -> "<th>#{inline(h)}</th>" end) |> Enum.join()) <>
        "</tr></thead>"

    tbody =
      if rows == [] do
        ""
      else
        "<tbody>" <>
          (Enum.map(rows, fn row ->
             "<tr>" <>
               (Enum.map(row, fn cell -> "<td>#{inline(cell)}</td>" end) |> Enum.join()) <>
               "</tr>"
           end)
           |> Enum.join()) <>
          "</tbody>"
      end

    "<div class=\"table-wrapper\"><table>#{thead}#{tbody}</table></div>"
  end

  # ── Inline Formatting ─────────────────────────────────────────

  defp inline(text) do
    text
    |> escape()
    |> replace_inline_code()
    |> replace_images()
    |> replace_links()
    |> replace_bold()
    |> replace_italic()
    |> replace_strikethrough()
    |> String.replace("\n", "<br>")
  end

  defp replace_inline_code(text) do
    Regex.replace(~r/`([^`]+)`/, text, "<code>\\1</code>")
  end

  defp replace_bold(text) do
    text
    |> then(&Regex.replace(~r/\*\*(.+?)\*\*/, &1, "<strong>\\1</strong>"))
    |> then(&Regex.replace(~r/__(.+?)__/, &1, "<strong>\\1</strong>"))
  end

  defp replace_italic(text) do
    text
    |> then(&Regex.replace(~r/\*(.+?)\*/, &1, "<em>\\1</em>"))
    |> then(&Regex.replace(~r/_(.+?)_/, &1, "<em>\\1</em>"))
  end

  defp replace_strikethrough(text) do
    Regex.replace(~r/~~(.+?)~~/, text, "<del>\\1</del>")
  end

  defp replace_links(text) do
    Regex.replace(~r/\[([^\]]+)\]\(([^)]+)\)/, text, fn _, label, url ->
      ~s(<a href="#{url}" target="_blank" rel="noopener">#{label}</a>)
    end)
  end

  defp replace_images(text) do
    Regex.replace(~r/!\[([^\]]*)\]\(([^)]+)\)/, text, fn _, alt, src ->
      ~s(<img src="#{src}" alt="#{alt}" loading="lazy">)
    end)
  end

  # ── Video / Audio Embeds ──────────────────────────────────────

  defp is_video_url?(url) do
    String.match?(url, ~r/(youtube\.com\/watch|youtu\.be\/|vimeo\.com\/\d)/)
  end

  defp render_video_embed(url) do
    cond do
      match = Regex.run(~r/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/, url) ->
        [_, video_id] = match
        ~s(<div class="video-embed"><iframe src="https://www.youtube.com/embed/#{escape(video_id)}" frameborder="0" allowfullscreen loading="lazy"></iframe></div>)

      match = Regex.run(~r/vimeo\.com\/(\d+)/, url) ->
        [_, video_id] = match
        ~s(<div class="video-embed"><iframe src="https://player.vimeo.com/video/#{escape(video_id)}" frameborder="0" allowfullscreen loading="lazy"></iframe></div>)

      true ->
        "<p><a href=\"#{escape(url)}\" target=\"_blank\" rel=\"noopener\">#{escape(url)}</a></p>"
    end
  end

  defp render_audio(caption, url) do
    cap = if caption != "", do: ~s(<p class="audio-caption">#{escape(caption)}</p>), else: ""
    ~s(<div class="audio-embed">#{cap}<audio controls preload="metadata"><source src="#{escape(url)}">Your browser does not support audio.</audio></div>)
  end

  # ── HTML Escaping ─────────────────────────────────────────────

  defp escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
end
