defmodule PersonalHub.DocumentParser do
  def parse(binary, filename) do
    ext = filename |> Path.extname() |> String.downcase()

    case ext do
      ".pdf" -> {:ok, :pdf, Base.encode64(binary)}
      ".xlsx" -> parse_xlsx(binary)
      ".docx" -> parse_docx(binary)
      ".pptx" -> parse_pptx(binary)
      ".doc" -> {:error, "Legacy .doc format is not supported. Please convert to .docx"}
      _ -> {:error, "Unsupported file format: #{ext}"}
    end
  end

  defp parse_xlsx(binary) do
    with {:ok, files} <- extract_zip(binary) do
      shared_strings = extract_shared_strings(files)
      sheets = extract_sheets(files, shared_strings)
      {:ok, :xlsx, sheets}
    end
  end

  defp parse_docx(binary) do
    with {:ok, files} <- extract_zip(binary) do
      paragraphs = extract_docx_text(files)
      {:ok, :docx, paragraphs}
    end
  end

  defp parse_pptx(binary) do
    with {:ok, files} <- extract_zip(binary) do
      slides = extract_pptx_slides(files)
      {:ok, :pptx, slides}
    end
  end

  defp extract_zip(binary) do
    case :zip.unzip(binary, [:memory]) do
      {:ok, entries} ->
        files =
          Enum.map(entries, fn {name, content} ->
            {to_string(name), content}
          end)

        {:ok, files}

      {:error, reason} ->
        {:error, "Failed to extract archive: #{inspect(reason)}"}
    end
  end

  defp extract_shared_strings(files) do
    case find_file(files, "xl/sharedStrings.xml") do
      nil ->
        %{}

      content ->
        content
        |> parse_xml()
        |> xpath_texts("si")
        |> Enum.with_index()
        |> Enum.into(%{}, fn {text, idx} -> {idx, text} end)
    end
  end

  defp extract_sheets(files, shared_strings) do
    files
    |> Enum.filter(fn {name, _} -> String.match?(name, ~r{xl/worksheets/sheet\d+\.xml}) end)
    |> Enum.sort_by(fn {name, _} -> name end)
    |> Enum.with_index(1)
    |> Enum.map(fn {{_name, content}, idx} ->
      rows = parse_sheet_xml(content, shared_strings)
      %{name: "Sheet #{idx}", rows: rows}
    end)
  end

  defp parse_sheet_xml(content, shared_strings) do
    xml = parse_xml(content)
    row_elements = extract_elements(xml, "row")

    Enum.map(row_elements, fn row_xml ->
      cells = extract_elements(row_xml, "c")

      Enum.map(cells, fn cell ->
        type = extract_attr(cell, "t")
        value = extract_text_content(cell, "v")

        case type do
          "s" ->
            idx = String.to_integer(value || "0")
            Map.get(shared_strings, idx, "")

          _ ->
            value || ""
        end
      end)
    end)
  end

  defp extract_docx_text(files) do
    case find_file(files, "word/document.xml") do
      nil ->
        ["No document content found"]

      content ->
        content
        |> parse_xml()
        |> extract_all_text()
        |> String.split(~r{\n+}, trim: true)
    end
  end

  defp extract_pptx_slides(files) do
    files
    |> Enum.filter(fn {name, _} -> String.match?(name, ~r{ppt/slides/slide\d+\.xml}) end)
    |> Enum.sort_by(fn {name, _} ->
      case Regex.run(~r{slide(\d+)}, name) do
        [_, num] -> String.to_integer(num)
        _ -> 0
      end
    end)
    |> Enum.with_index(1)
    |> Enum.map(fn {{_name, content}, idx} ->
      text =
        content
        |> parse_xml()
        |> extract_all_text()

      %{number: idx, text: text}
    end)
  end

  defp find_file(files, target) do
    case Enum.find(files, fn {name, _} -> name == target end) do
      {_, content} -> content
      nil -> nil
    end
  end

  defp parse_xml(content) do
    content = String.replace(to_string(content), ~r/<\?xml[^?]*\?>/, "")

    try do
      {doc, _} = :xmerl_scan.string(String.to_charlist(content), quiet: true)
      doc
    rescue
      _ -> nil
    catch
      :exit, _ -> nil
    end
  end

  defp xpath_texts(nil, _), do: []

  defp xpath_texts(xml, tag_suffix) do
    all_elements = flatten_elements(xml)

    all_elements
    |> Enum.filter(fn
      {:xmlElement, name, _, _, _, _, _, _, _, _, _, _} ->
        Atom.to_string(name) |> String.ends_with?(tag_suffix)

      _ ->
        false
    end)
    |> Enum.map(&extract_all_text/1)
  end

  defp extract_elements(nil, _), do: []

  defp extract_elements(xml, tag_suffix) do
    flatten_elements(xml)
    |> Enum.filter(fn
      {:xmlElement, name, _, _, _, _, _, _, _, _, _, _} ->
        Atom.to_string(name) |> String.ends_with?(tag_suffix)

      _ ->
        false
    end)
  end

  defp extract_attr(nil, _), do: nil

  defp extract_attr({:xmlElement, _, _, _, _, _, _, attrs, _, _, _, _}, attr_name) do
    Enum.find_value(attrs, fn
      {:xmlAttribute, name, _, _, _, _, _, _, value, _} ->
        if Atom.to_string(name) == attr_name, do: to_string(value)

      _ ->
        nil
    end)
  end

  defp extract_attr(_, _), do: nil

  defp extract_text_content(xml, tag_suffix) do
    elements = extract_elements(xml, tag_suffix)

    case elements do
      [el | _] -> extract_all_text(el)
      [] -> nil
    end
  end

  defp extract_all_text(nil), do: ""

  defp extract_all_text({:xmlText, _, _, _, value, _}) do
    to_string(value) |> String.trim()
  end

  defp extract_all_text({:xmlElement, _, _, _, _, _, _, _, children, _, _, _}) do
    children
    |> Enum.map(&extract_all_text/1)
    |> Enum.join("")
  end

  defp extract_all_text(_), do: ""

  defp flatten_elements(nil), do: []

  defp flatten_elements({:xmlElement, _, _, _, _, _, _, _, children, _, _, _} = el) do
    child_elements =
      children
      |> Enum.flat_map(&flatten_elements/1)

    [el | child_elements]
  end

  defp flatten_elements({:xmlText, _, _, _, _, _}), do: []
  defp flatten_elements(_), do: []
end
