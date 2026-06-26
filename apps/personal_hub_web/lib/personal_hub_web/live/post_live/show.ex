defmodule PersonalHubWeb.PostLive.Show do
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
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto space-y-6">
        <%= if @post do %>
          <div class="flex justify-between items-center">
            <.link
              navigate={~p"/posts"}
              class="inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors"
            >
              <.icon name="hero-arrow-left" class="size-4" /> Back to Posts
            </.link>
            <div class="flex items-center gap-2">
              <.link
                navigate={~p"/posts/#{@post["id"]}/edit"}
                class="px-4 py-2 rounded-xl text-sm font-medium text-gray-700 border border-gray-200 hover:bg-gray-50 transition-colors"
              >
                <.icon name="hero-pencil" class="size-4 inline mr-1" /> Edit
              </.link>
            </div>
          </div>

          <article class="blog-article bg-white border border-gray-200 rounded-2xl overflow-hidden">
            <%!-- Post header --%>
            <div class="p-8 pb-0">
              <h1 class="text-3xl font-bold text-gray-900">{@post["title"]}</h1>

              <div class="flex items-center gap-3 mt-3 mb-6">
                <%= if @post["published"] do %>
                  <span class="rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-50 text-green-700">
                    Published
                  </span>
                <% else %>
                  <span class="rounded-full px-2.5 py-0.5 text-xs font-medium bg-amber-50 text-amber-700">
                    Draft
                  </span>
                <% end %>
                <span class="rounded-full px-2 py-0.5 text-xs font-medium bg-indigo-50 text-indigo-600">
                  {(@theme && @theme.name) || "Minimal"} theme
                </span>
                <span class="text-sm text-gray-400" title={format_datetime(@post["inserted_at"])}>
                  <.icon name="hero-clock" class="size-3.5 inline mr-0.5" />
                  {format_date(@post["inserted_at"])}
                </span>
                <%= if @post["updated_at"] do %>
                  <span class="text-sm text-gray-400" title={format_datetime(@post["updated_at"])}>
                    (edited {relative_time(@post["updated_at"])})
                  </span>
                <% end %>
              </div>
            </div>

            <hr class="border-gray-100" />

            <%!-- Themed content --%>
            <div class="p-8">
              <%= Phoenix.HTML.raw(@theme_css) %>
              <div class="blog-content">
                <%= Phoenix.HTML.raw(@rendered_html) %>
              </div>
            </div>
          </article>
        <% else %>
          <div class="text-center py-16">
            <.icon name="hero-arrow-path" class="size-8 mx-auto text-gray-300 animate-spin mb-3" />
            <p class="text-lg font-medium text-gray-400">Loading post...</p>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
