defmodule PersonalHubWeb.PostLive.Index do
  use PersonalHubWeb, :live_view

  alias PersonalHubWeb.PostLive.BlogEditor

  alias PersonalHub.BlogStore

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       posts: BlogStore.list_posts(),
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
    form =
      to_form(
        %{"title" => "", "body" => "", "published" => false, "theme_id" => "minimal"},
        as: :post
      )

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
              "published" => post["published"] || false,
              "theme_id" => post["theme_id"] || "minimal"
            },
            as: :post
          )

        assign(socket, post: post, form: form)
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    BlogStore.delete_post(id)
    
    {:noreply,
     socket
     |> assign(posts: BlogStore.list_posts())
     |> put_flash(:info, "Post deleted")}
  end

  @impl true
  def handle_event("update_form", %{"post" => post_params}, socket) do
    form = to_form(post_params, as: :post)
    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.live_action, post_params)
  end

  defp save_post(socket, :new, params) do
    id = generate_id()
    
    post = %{
      "id" => id,
      "title" => params["title"],
      "body" => params["body"],
      "published" => params["published"] == "true",
      "theme_id" => params["theme_id"] || "minimal"
    }

    BlogStore.save_post(post)

    {:noreply,
     socket
     |> assign(posts: BlogStore.list_posts())
     |> put_flash(:info, "Post created!")
     |> push_navigate(to: ~p"/posts")}
  end

  defp save_post(socket, :edit, params) do
    # Get existing post to keep inserted_at
    existing_post = BlogStore.get_post(socket.assigns.edit_id) || %{}
    
    post = %{
      "id" => socket.assigns.edit_id,
      "title" => params["title"],
      "body" => params["body"],
      "published" => params["published"] == "true",
      "theme_id" => params["theme_id"] || "minimal",
      "inserted_at" => existing_post["inserted_at"]
    }

    BlogStore.save_post(post)

    {:noreply,
     socket
     |> assign(posts: BlogStore.list_posts())
     |> put_flash(:info, "Post updated!")
     |> push_navigate(to: ~p"/posts")}
  end

  defp generate_id do
    # Create a URL-friendly slug based on title if possible, else unique string
    :crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false) |> String.downcase()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-6xl mx-auto space-y-6">
        <.link
          navigate={~p"/"}
          class="inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Dashboard
        </.link>

        <div class="flex justify-between items-center">
          <h1 class="text-2xl font-semibold text-gray-900">{@page_title}</h1>
          <%= if @live_action == :index do %>
            <.link
              navigate={~p"/posts/new"}
              class="px-4 py-2 rounded-xl text-sm font-medium text-white bg-primary hover:bg-primary/90 transition-colors"
            >
              New Post
            </.link>
          <% end %>
        </div>

        <%!-- Editor form (new/edit) --%>
        <%= if @live_action in [:new, :edit] and @form do %>
          <div class="blog-editor-wrapper bg-white border border-gray-200 rounded-2xl overflow-hidden">
            <.form for={@form} id="post-form" phx-submit="save" phx-change="update_form" class="space-y-0">
              <div class="p-5 pb-3 border-b border-gray-100">
                <.input field={@form[:title]} type="text" label="Post Title" placeholder="Enter your blog post title…" required />
                <div class="flex items-center gap-4 mt-3">
                  <.input field={@form[:published]} type="checkbox" label="Published" />
                </div>
              </div>

              <.live_component
                module={BlogEditor}
                id="blog-editor"
                form={@form}
              />

              <div class="flex items-center gap-3 p-5 pt-3 border-t border-gray-100 bg-gray-50">
                <button
                  type="submit"
                  class="px-5 py-2.5 rounded-xl text-sm font-semibold text-white bg-primary hover:bg-primary/90 transition-colors shadow-sm"
                >
                  <.icon name="hero-check" class="size-4 inline mr-1" /> Save Post
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

        <%!-- Post list --%>
        <%= if @live_action == :index do %>
          <div class="space-y-4">
            <%= for post <- @posts do %>
              <div class="bg-white border border-gray-200 rounded-2xl p-5 hover:shadow-md transition-shadow">
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
                      <%= if post["theme_id"] do %>
                        <span class="rounded-full px-2 py-0.5 text-xs font-medium bg-indigo-50 text-indigo-600">
                          {post["theme_id"]}
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
                      class="text-sm font-medium text-indigo-600 hover:text-indigo-800 transition-colors"
                    >
                      <.icon name="hero-eye" class="size-4 inline mr-0.5" /> View
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
                <.icon name="hero-document-text" class="size-12 mx-auto text-gray-300 mb-3" />
                <p class="text-lg font-medium text-gray-400">No posts yet</p>
                <p class="mt-1 text-sm text-gray-400">Create your first blog post with the Markdown editor!</p>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
