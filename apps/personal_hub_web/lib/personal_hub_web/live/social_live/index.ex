defmodule PersonalHubWeb.SocialLive.Index do
  use PersonalHubWeb, :live_view

  @platforms [
    %{key: :x, name: "X (Twitter)", max: 280, icon: "𝕏", bg: "bg-gray-900"},
    %{key: :linkedin, name: "LinkedIn", max: 3000, icon: "in", bg: "bg-blue-700"},
    %{key: :instagram, name: "Instagram", max: 2200, icon: "📷", bg: "bg-gradient-to-br from-purple-600 to-pink-500"},
    %{key: :threads, name: "Threads", max: 500, icon: "🧵", bg: "bg-gray-900"},
    %{key: :bluesky, name: "Bluesky", max: 300, icon: "🦋", bg: "bg-sky-500"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Social Composer")
     |> assign(content: "", hashtags: "", drafts: [])
     |> assign(platforms: @platforms)
     |> assign(copied_platform: nil)
     |> assign_char_count()}
  end

  @impl true
  def handle_event("update_content", %{"content" => content}, socket) do
    {:noreply,
     socket
     |> assign(content: content)
     |> assign_char_count()}
  end

  @impl true
  def handle_event("update_hashtags", %{"hashtags" => hashtags}, socket) do
    {:noreply,
     socket
     |> assign(hashtags: hashtags)
     |> assign_char_count()}
  end

  @impl true
  def handle_event("copy_for_platform", %{"platform" => platform_key}, socket) do
    platform = Enum.find(@platforms, fn p -> Atom.to_string(p.key) == platform_key end)
    text = format_for_platform(socket.assigns.content, socket.assigns.hashtags, platform.max)

    {:noreply,
     socket
     |> assign(copied_platform: platform_key)
     |> push_event("copy-text", %{text: text})}
  end

  @impl true
  def handle_event("ls:loaded", data, socket) do
    {:noreply, assign(socket, drafts: data["social_drafts"] || [])}
  end

  @impl true
  def handle_event("save_draft", _params, socket) do
    draft = %{
      "id" => System.unique_integer([:positive]) |> Integer.to_string(),
      "content" => socket.assigns.content,
      "hashtags" => socket.assigns.hashtags,
      "created_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    drafts = [draft | socket.assigns.drafts]

    {:noreply,
     socket
     |> assign(drafts: drafts)
     |> push_event("ls:store", %{collection: "social_drafts", data: drafts})}
  end

  @impl true
  def handle_event("load_draft", %{"id" => id}, socket) do
    case Enum.find(socket.assigns.drafts, fn d -> d["id"] == id end) do
      nil ->
        {:noreply, socket}

      draft ->
        {:noreply,
         socket
         |> assign(content: draft["content"] || "", hashtags: draft["hashtags"] || "")
         |> assign_char_count()}
    end
  end

  @impl true
  def handle_event("delete_draft", %{"id" => id}, socket) do
    drafts = Enum.reject(socket.assigns.drafts, fn d -> d["id"] == id end)

    {:noreply,
     socket
     |> assign(drafts: drafts)
     |> push_event("ls:store", %{collection: "social_drafts", data: drafts})}
  end

  @impl true
  def handle_event("clear_content", _params, socket) do
    {:noreply,
     socket
     |> assign(content: "", hashtags: "")
     |> assign_char_count()}
  end

  defp assign_char_count(socket) do
    count = compute_char_count(socket.assigns.content, socket.assigns.hashtags)
    assign(socket, total_chars: count)
  end

  defp compute_char_count(content, hashtags) do
    suffix = if hashtags != "", do: "\n\n#{hashtags}", else: ""
    String.length(content <> suffix)
  end

  defp format_for_platform(content, hashtags, max) do
    suffix = if hashtags != "", do: "\n\n#{hashtags}", else: ""
    full = content <> suffix

    if String.length(full) > max do
      String.slice(full, 0, max - 1) <> "…"
    else
      full
    end
  end

  defp progress_percent(count, max), do: min(round(count / max * 100), 100)

  defp progress_color(count, max) do
    ratio = count / max

    cond do
      ratio > 1.0 -> "bg-red-500"
      ratio > 0.85 -> "bg-amber-500"
      true -> "bg-emerald-500"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="social-store" phx-hook="LocalStore" phx-update="ignore" data-collections="social_drafts">
      </div>

      <div class="space-y-6">
        <.link
          navigate={~p"/"}
          class="inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Dashboard
        </.link>

        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl sm:text-3xl font-bold text-gray-900 tracking-tight">Social Composer</h1>
            <p class="text-gray-500 mt-1">Write once, post everywhere</p>
          </div>
          <div class="flex gap-2">
            <button
              phx-click="save_draft"
              disabled={@content == ""}
              class={[
                "inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-medium transition-colors cursor-pointer",
                if(@content == "", do: "bg-gray-100 text-gray-400 cursor-not-allowed", else: "bg-gray-900 text-white hover:bg-gray-800")
              ]}
            >
              <.icon name="hero-bookmark" class="size-4" /> Save Draft
            </button>
            <button
              phx-click="clear_content"
              class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors cursor-pointer"
            >
              <.icon name="hero-arrow-path" class="size-4" /> Clear
            </button>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div class="space-y-4">
            <div class="bg-white rounded-2xl border border-gray-200 p-5">
              <label class="block text-sm font-semibold text-gray-700 mb-2">Post Content</label>
              <textarea
                id="social-content"
                phx-hook=".SocialCopy"
                phx-update="ignore"
                name="content"
                rows="8"
                placeholder="Write your post here..."
                class="w-full rounded-xl border border-gray-200 px-4 py-3 text-sm text-gray-900 placeholder:text-gray-400 focus:border-primary focus:ring-1 focus:ring-primary resize-none"
              ><%= @content %></textarea>

              <label class="block text-sm font-semibold text-gray-700 mb-2 mt-4">Hashtags</label>
              <input
                type="text"
                phx-keyup="update_hashtags"
                name="hashtags"
                value={@hashtags}
                placeholder="#elixir #webdev #phoenix"
                class="w-full rounded-xl border border-gray-200 px-4 py-3 text-sm text-gray-900 placeholder:text-gray-400 focus:border-primary focus:ring-1 focus:ring-primary"
              />
            </div>

            <div class="bg-white rounded-2xl border border-gray-200 p-5 space-y-3">
              <h3 class="text-sm font-semibold text-gray-700">Character Limits</h3>
              <%= for platform <- @platforms do %>
                <div class="space-y-1">
                  <div class="flex justify-between text-xs">
                    <span class="font-medium text-gray-600">{platform.name}</span>
                    <span class={[
                      "font-mono font-bold",
                      if(@total_chars > platform.max, do: "text-red-500", else: "text-gray-500")
                    ]}>
                      {@total_chars} / {platform.max}
                    </span>
                  </div>
                  <div class="w-full bg-gray-100 rounded-full h-1.5 overflow-hidden">
                    <div
                      class={["h-full rounded-full transition-all duration-300", progress_color(@total_chars, platform.max)]}
                      style={"width: #{progress_percent(@total_chars, platform.max)}%"}
                    >
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <%= if @drafts != [] do %>
              <div class="bg-white rounded-2xl border border-gray-200 p-5 space-y-3">
                <h3 class="text-sm font-semibold text-gray-700">Saved Drafts</h3>
                <%= for draft <- @drafts do %>
                  <div class="flex items-center justify-between gap-3 p-3 rounded-xl bg-gray-50 hover:bg-gray-100 transition-colors">
                    <button phx-click="load_draft" phx-value-id={draft["id"]} class="flex-1 text-left text-sm text-gray-700 truncate cursor-pointer">
                      {String.slice(draft["content"] || "", 0..60)}...
                    </button>
                    <button phx-click="delete_draft" phx-value-id={draft["id"]} class="text-gray-400 hover:text-red-500 transition-colors cursor-pointer">
                      <.icon name="hero-trash" class="size-4" />
                    </button>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <div class="space-y-4">
            <h3 class="text-sm font-semibold text-gray-700">Platform Previews — Click to Copy</h3>
            <%= for platform <- @platforms do %>
              <button
                phx-click="copy_for_platform"
                phx-value-platform={platform.key}
                class="block w-full text-left bg-white rounded-2xl border border-gray-200 p-5 hover:shadow-md hover:border-gray-300 transition-all cursor-pointer group"
              >
                <div class="flex items-center justify-between mb-3">
                  <div class="flex items-center gap-2">
                    <span class={["inline-flex items-center justify-center w-8 h-8 rounded-lg text-white text-xs font-bold", platform.bg]}>
                      {platform.icon}
                    </span>
                    <span class="text-sm font-semibold text-gray-900">{platform.name}</span>
                  </div>
                  <span class={[
                    "text-xs font-medium px-2 py-1 rounded-full transition-colors",
                    if(@copied_platform == Atom.to_string(platform.key),
                      do: "bg-emerald-100 text-emerald-700",
                      else: "bg-gray-100 text-gray-500 group-hover:bg-gray-200")
                  ]}>
                    {if @copied_platform == Atom.to_string(platform.key), do: "✓ Copied!", else: "Click to copy"}
                  </span>
                </div>
                <p class={[
                  "text-sm whitespace-pre-wrap break-words leading-relaxed",
                  if(@content == "", do: "text-gray-300 italic", else: "text-gray-700")
                ]}>
                  {if @content == "", do: "Your post preview will appear here...", else: format_for_platform(@content, @hashtags, platform.max)}
                </p>
              </button>
            <% end %>
          </div>
        </div>
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".SocialCopy">
        export default {
          mounted() {
            this.handleEvent("copy-text", ({ text }) => {
              navigator.clipboard.writeText(text).catch(() => {});
            });
            this.el.addEventListener("input", e => {
              this.pushEvent("update_content", { content: e.target.value });
            });
          }
        }
      </script>
    </Layouts.app>
    """
  end
end
