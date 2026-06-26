defmodule PersonalHub.BlogStore do
  @moduledoc """
  Stores and reads blog posts as .md files on the local filesystem.
  """
  
  alias PersonalHub.Frontmatter

  defp base_dir do
    # Using Path.expand to ensure it's relative to the project root
    # when running locally or in Docker.
    Path.expand("blogs", File.cwd!())
  end

  def list_posts do
    dir = base_dir()
    File.mkdir_p!(dir)

    dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".md"))
    |> Enum.map(fn filename ->
      id = Path.basename(filename, ".md")
      get_post(id)
    end)
    |> Enum.reject(&is_nil/1)
    # Sort descending by inserted_at
    |> Enum.sort_by(&(&1["inserted_at"] || &1["id"]), :desc)
  end

  def get_post(id) do
    # Clean the ID to prevent path traversal
    safe_id = Path.basename(id)
    path = Path.join(base_dir(), "#{safe_id}.md")

    if File.exists?(path) do
      content = File.read!(path)
      {meta, body} = Frontmatter.parse(content)

      # Ensure base fields
      %{
        "id" => safe_id,
        "title" => meta["title"] || safe_id,
        "body" => body,
        "published" => meta["published"] == true || meta["published"] == "true",
        "theme_id" => meta["theme_id"] || "minimal",
        "inserted_at" => meta["inserted_at"] || format_now(),
        "updated_at" => meta["updated_at"]
      }
    else
      nil
    end
  end

  def save_post(%{"id" => id} = post) do
    safe_id = Path.basename(id)
    File.mkdir_p!(base_dir())
    path = Path.join(base_dir(), "#{safe_id}.md")
    
    body = post["body"] || ""
    
    meta = %{
      "title" => post["title"] || safe_id,
      "published" => post["published"] == true || post["published"] == "true",
      "theme_id" => post["theme_id"] || "minimal",
      "inserted_at" => post["inserted_at"] || format_now(),
      "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    content = Frontmatter.format(meta, body)
    File.write!(path, content)
    
    get_post(safe_id)
  end

  def delete_post(id) do
    safe_id = Path.basename(id)
    path = Path.join(base_dir(), "#{safe_id}.md")
    if File.exists?(path) do
      File.rm!(path)
    end
    :ok
  end

  defp format_now do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end
end
