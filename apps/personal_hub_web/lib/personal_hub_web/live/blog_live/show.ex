defmodule PersonalHubWeb.BlogLive.Show do
  @moduledoc """
  Public-facing blog page that renders a fully themed blog post.
  Accessible at /blog/:id — designed for sharing/viewing.
  """
  use PersonalHubWeb, :live_view

  alias PersonalHub.{Markdown, BlogThemes, BlogStore}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case BlogStore.get_post(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Post not found")
         |> push_navigate(to: ~p"/posts")}

      post ->
        theme = BlogThemes.get(post["theme_id"] || "minimal")
        theme_css = BlogThemes.to_scoped_css(theme)

        rendered_html =
          case Markdown.to_html(post["body"]) do
            {:safe, html} -> html
            _ -> ""
          end

        {:ok,
         assign(socket,
           post: post,
           post_id: id,
           page_title: post["title"],
           theme: theme,
           theme_css: theme_css,
           rendered_html: rendered_html
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @post do %>
      <article class="blog-public-page">
        <%= Phoenix.HTML.raw(@theme_css) %>

        <div class="blog-public-header">
          <div class="max-w-3xl mx-auto px-6 py-12">
            <h1 class="blog-public-title">{@post["title"]}</h1>
            <div class="blog-public-meta">
              <span>{format_date(@post["inserted_at"])}</span>
              <%= if @post["updated_at"] do %>
                <span>· Updated {relative_time(@post["updated_at"])}</span>
              <% end %>
            </div>
          </div>
        </div>

        <div class="max-w-3xl mx-auto px-6 py-8">
          <div class="blog-content">
            <%= Phoenix.HTML.raw(@rendered_html) %>
          </div>
        </div>

        <footer class="blog-public-footer">
          <div class="max-w-3xl mx-auto px-6 py-6 flex items-center justify-between">
            <.link
              navigate={~p"/posts"}
              class="text-sm text-gray-500 hover:text-gray-900 transition-colors"
            >
              ← Back to all posts
            </.link>
            <span class="text-xs text-gray-400">Personal Hub Blog</span>
          </div>
        </footer>
      </article>
    <% else %>
      <div class="flex items-center justify-center min-h-screen">
        <div class="text-center">
          <.icon name="hero-arrow-path" class="size-8 mx-auto text-gray-300 animate-spin mb-3" />
          <p class="text-lg font-medium text-gray-400">Loading...</p>
        </div>
      </div>
    <% end %>
    """
  end
end
