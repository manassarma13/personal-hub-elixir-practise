defmodule PersonalHubWeb.PostLive.Index do
  use PersonalHubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       posts: [],
       page_title: "Blog Posts",
       post: nil,
       form: nil,
       edit_id: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, post: nil, form: nil, edit_id: nil)
  end

  defp apply_action(socket, :new, _params) do
    form = to_form(%{"title" => "", "body" => "", "published" => false}, as: :post)

    socket
    |> assign(page_title: "New Post")
    |> assign(post: nil, edit_id: nil)
    |> assign(form: form)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(page_title: "Edit Post", edit_id: id)
    |> setup_edit_form()
  end

  defp setup_edit_form(%{assigns: %{edit_id: nil}} = socket), do: socket

  defp setup_edit_form(%{assigns: %{edit_id: id, posts: posts}} = socket) do
    case Enum.find(posts, fn p -> p["id"] == id end) do
      nil ->
        socket

      post ->
        form =
          to_form(
            %{
              "title" => post["title"] || "",
              "body" => post["body"] || "",
              "published" => post["published"] || false
            },
            as: :post
          )

        assign(socket, post: post, form: form)
    end
  end

  @impl true
  def handle_event("ls:loaded", %{"posts" => posts}, socket) do
    socket =
      socket
      |> assign(posts: posts || [])
      |> setup_edit_form()

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    posts = Enum.reject(socket.assigns.posts, fn p -> p["id"] == id end)

    {:noreply,
     socket
     |> assign(posts: posts)
     |> push_event("ls:store", %{key: "posts", data: posts})}
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.live_action, post_params)
  end

  defp save_post(socket, :new, params) do
    new_post = %{
      "id" => generate_id(),
      "title" => params["title"],
      "body" => params["body"],
      "published" => params["published"] == "true",
      "inserted_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    posts = socket.assigns.posts ++ [new_post]

    {:noreply,
     socket
     |> assign(posts: posts)
     |> push_event("ls:store", %{key: "posts", data: posts})
     |> put_flash(:info, "Post created!")
     |> push_navigate(to: ~p"/posts")}
  end

  defp save_post(socket, :edit, params) do
    posts =
      Enum.map(socket.assigns.posts, fn p ->
        if p["id"] == socket.assigns.edit_id do
          Map.merge(p, %{
            "title" => params["title"],
            "body" => params["body"],
            "published" => params["published"] == "true",
            "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
          })
        else
          p
        end
      end)

    {:noreply,
     socket
     |> assign(posts: posts)
     |> push_event("ls:store", %{key: "posts", data: posts})
     |> put_flash(:info, "Post updated!")
     |> push_navigate(to: ~p"/posts")}
  end

  defp generate_id do
    :erlang.unique_integer([:positive]) |> Integer.to_string()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="local-store" phx-hook="LocalStore" phx-update="ignore" data-collections="posts"></div>
      <div class="max-w-4xl mx-auto space-y-6">
        <.link
          navigate={~p"/"}
          class="inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Dashboard
        </.link>

        <div class="flex justify-between items-center">
          <h1 class="text-2xl font-semibold text-gray-900">{@page_title}</h1>
          <.link
            navigate={~p"/posts/new"}
            class="px-4 py-2 rounded-xl text-sm font-medium text-white bg-primary hover:bg-primary/90 transition-colors"
          >
            New Post
          </.link>
        </div>

        <%= if @live_action in [:new, :edit] and @form do %>
          <div class="bg-white border border-gray-200 rounded-2xl p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-5">{@page_title}</h2>
            <.form for={@form} id="post-form" phx-submit="save" class="space-y-5">
              <.input field={@form[:title]} type="text" label="Title" required />
              <.input field={@form[:body]} type="textarea" label="Body" rows="5" required />
              <.input field={@form[:published]} type="checkbox" label="Published" />

              <div class="flex items-center gap-3 pt-2">
                <button
                  type="submit"
                  class="px-4 py-2 rounded-xl text-sm font-medium text-white bg-primary hover:bg-primary/90 transition-colors"
                >
                  Save
                </button>
                <.link
                  navigate={~p"/posts"}
                  class="text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors"
                >
                  Cancel
                </.link>
              </div>
            </.form>
          </div>
        <% end %>

        <div class="space-y-4">
          <%= for post <- @posts do %>
            <div class="bg-white border border-gray-200 rounded-2xl p-5">
              <div class="flex justify-between items-start">
                <div class="min-w-0 flex-1">
                  <div class="flex items-center gap-2.5">
                    <h2 class="text-base font-semibold text-gray-900 truncate">{post["title"]}</h2>
                    <%= if post["published"] do %>
                      <span class="rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-50 text-green-700">
                        Published
                      </span>
                    <% else %>
                      <span class="rounded-full px-2.5 py-0.5 text-xs font-medium bg-amber-50 text-amber-700">
                        Draft
                      </span>
                    <% end %>
                  </div>
                  <p class="mt-1.5 text-sm text-gray-500 line-clamp-2">
                    {String.slice(post["body"] || "", 0..200)}
                  </p>
                  <div class="flex items-center gap-3 mt-2">
                    <span class="text-xs text-gray-400" title={format_datetime(post["inserted_at"])}>
                      <.icon name="hero-clock" class="size-3 inline mr-0.5" />
                      {relative_time(post["inserted_at"])}
                    </span>
                    <%= if post["updated_at"] do %>
                      <span class="text-xs text-gray-400" title={format_datetime(post["updated_at"])}>
                        edited {relative_time(post["updated_at"])}
                      </span>
                    <% end %>
                  </div>
                </div>
                <div class="flex items-center gap-3 ml-4 shrink-0">
                  <.link
                    navigate={~p"/posts/#{post["id"]}"}
                    class="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
                  >
                    View
                  </.link>
                  <.link
                    navigate={~p"/posts/#{post["id"]}/edit"}
                    class="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
                  >
                    Edit
                  </.link>
                  <button
                    phx-click="delete"
                    phx-value-id={post["id"]}
                    class="text-sm font-medium text-red-500 hover:text-red-700 transition-colors"
                    data-confirm="Are you sure?"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          <% end %>

          <%= if @posts == [] do %>
            <div class="text-center py-16">
              <p class="text-lg font-medium text-gray-400">No posts yet</p>
              <p class="mt-1 text-sm text-gray-400">Create your first blog post!</p>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
