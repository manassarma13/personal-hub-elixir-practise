defmodule PersonalHubWeb.PostLive.Show do
  use PersonalHubWeb, :live_view

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok, assign(socket, post: nil, post_id: id, page_title: "Loading...")}
  end

  @impl true
  def handle_event("ls:loaded", %{"posts" => posts}, socket) do
    case Enum.find(posts || [], fn p -> p["id"] == socket.assigns.post_id end) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Post not found")
         |> push_navigate(to: ~p"/posts")}

      post ->
        {:noreply, assign(socket, post: post, page_title: post["title"])}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="local-store" phx-hook="LocalStore" phx-update="ignore" data-collections="posts"></div>
      <div class="max-w-3xl mx-auto space-y-6">
        <%= if @post do %>
          <div class="flex justify-between items-center">
            <.link
              navigate={~p"/posts"}
              class="inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors"
            >
              <.icon name="hero-arrow-left" class="size-4" /> Back to Posts
            </.link>
            <.link
              navigate={~p"/posts/#{@post["id"]}/edit"}
              class="px-4 py-2 rounded-xl text-sm font-medium text-gray-700 border border-gray-200 hover:bg-gray-50 transition-colors"
            >
              Edit
            </.link>
          </div>

          <article class="bg-white border border-gray-200 rounded-2xl p-8">
            <h1 class="text-2xl font-bold text-gray-900">{@post["title"]}</h1>

            <div class="flex items-center gap-3 mt-3">
              <%= if @post["published"] do %>
                <span class="rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-50 text-green-700">
                  Published
                </span>
              <% else %>
                <span class="rounded-full px-2.5 py-0.5 text-xs font-medium bg-amber-50 text-amber-700">
                  Draft
                </span>
              <% end %>
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

            <hr class="my-6 border-gray-100" />

            <div class="prose max-w-none text-gray-700 leading-relaxed">
              <p class="whitespace-pre-wrap">{@post["body"]}</p>
            </div>
          </article>
        <% else %>
          <div class="text-center py-16">
            <p class="text-lg font-medium text-gray-400">Loading post...</p>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
