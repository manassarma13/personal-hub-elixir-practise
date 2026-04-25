defmodule PersonalHubWeb.DropLive.Index do
  use PersonalHubWeb, :live_view

  alias PersonalHub.Drop.RoomServer

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Drop",
       room_code: nil,
       join_code: "",
       clip_text: "",
       mode: :lobby
     )
     |> stream(:clips, [])}
  end

  @impl true
  def handle_event("create_room", _, socket) do
    code = RoomServer.generate_code()

    case RoomServer.create_room(code) do
      {:ok, _pid} ->
        join_room(socket, code)

      {:error, {:already_started, _}} ->
        join_room(socket, code)
    end
  end

  def handle_event("join_room", %{"code" => code}, socket) do
    code = String.trim(code)

    cond do
      byte_size(code) != 6 ->
        {:noreply, put_flash(socket, :error, "Enter a 6-digit room code.")}

      RoomServer.room_exists?(code) ->
        join_room(socket, code)

      true ->
        {:noreply, put_flash(socket, :error, "Room not found. Check the code.")}
    end
  end

  def handle_event("update_join_code", %{"code" => code}, socket) do
    {:noreply, assign(socket, join_code: code)}
  end

  def handle_event("add_clip", %{"text" => text}, socket) do
    text = String.trim(text)

    if text != "" and socket.assigns.room_code do
      try do
        RoomServer.add_clip(socket.assigns.room_code, text)
      catch
        :exit, _ ->
          :room_dead
      end
    end

    {:noreply, assign(socket, clip_text: "")}
  end

  def handle_event("update_clip_text", %{"text" => text}, socket) do
    {:noreply, assign(socket, clip_text: text)}
  end

  def handle_event("delete_clip", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)

    if socket.assigns.room_code do
      try do
        RoomServer.delete_clip(socket.assigns.room_code, id)
      catch
        :exit, _ -> :room_dead
      end
    end

    {:noreply, socket}
  end

  def handle_event("leave_room", _, socket) do
    if socket.assigns.room_code do
      Phoenix.PubSub.unsubscribe(PersonalHub.PubSub, "drop:#{socket.assigns.room_code}")
    end

    {:noreply,
     socket
     |> assign(room_code: nil, mode: :lobby, clip_text: "", join_code: "")
     |> stream(:clips, [], reset: true)}
  end

  @impl true
  def handle_info({:clip_added, clip}, socket) do
    {:noreply, stream_insert(socket, :clips, clip, at: 0)}
  end

  def handle_info({:clip_deleted, clip_id}, socket) do
    {:noreply, stream_delete_by_dom_id(socket, :clips, "clips-#{clip_id}")}
  end

  defp join_room(socket, code) do
    Phoenix.PubSub.subscribe(PersonalHub.PubSub, "drop:#{code}")
    clips = RoomServer.get_clips(code)

    {:noreply,
     socket
     |> assign(room_code: code, mode: :room, clip_text: "")
     |> stream(:clips, clips, reset: true)}
  end

  defp format_clip_time(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _} ->
        hour = dt.hour |> Integer.to_string() |> String.pad_leading(2, "0")
        minute = dt.minute |> Integer.to_string() |> String.pad_leading(2, "0")
        "#{hour}:#{minute}"

      _ ->
        ""
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".CopyClip">
        export default {
          mounted() {
            this.el.addEventListener("click", () => {
              const text = this.el.dataset.text
              navigator.clipboard.writeText(text).then(() => {
                this.el.classList.add("!text-green-500")
                setTimeout(() => this.el.classList.remove("!text-green-500"), 1200)
              })
            })
          }
        }
      </script>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".CopyCode">
        export default {
          mounted() {
            this.el.addEventListener("click", () => {
              const code = this.el.dataset.code
              navigator.clipboard.writeText(code).then(() => {
                const label = this.el.querySelector("[data-label]")
                if (label) {
                  const orig = label.textContent
                  label.textContent = "Copied!"
                  setTimeout(() => { label.textContent = orig }, 1200)
                }
              })
            })
          }
        }
      </script>

      <%= if @mode == :lobby do %>
        <%!-- ═══════ LOBBY ═══════ --%>
        <div class="flex flex-col items-center justify-center min-h-[70vh] px-4">
          <div class="text-center mb-10">
            <div class="inline-flex items-center justify-center w-20 h-20 rounded-3xl bg-gradient-to-br from-violet-500 to-indigo-600 mb-6 shadow-lg shadow-violet-500/25">
              <.icon name="hero-paper-airplane" class="size-10 text-white -rotate-45" />
            </div>
            <h1 class="text-4xl sm:text-5xl font-bold text-gray-900 tracking-tight">Drop</h1>
            <p class="text-lg text-gray-500 mt-3 max-w-md mx-auto">
              Share text between devices. No app. No signup. Just a code.
            </p>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 w-full max-w-lg">
            <button
              id="create-room-btn"
              phx-click="create_room"
              class="flex flex-col items-center gap-3 p-8 rounded-2xl border-2 border-dashed border-violet-300 bg-violet-50/50 hover:bg-violet-100/70 hover:border-violet-400 transition-all cursor-pointer group"
            >
              <span class="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-gradient-to-br from-violet-500 to-indigo-600 shadow-md group-hover:shadow-lg group-hover:scale-105 transition-all">
                <.icon name="hero-plus" class="size-7 text-white" />
              </span>
              <span class="font-semibold text-gray-900">Create Room</span>
              <span class="text-xs text-gray-500">Get a 6-digit code</span>
            </button>

            <form
              id="join-room-form"
              phx-submit="join_room"
              class="flex flex-col items-center gap-3 p-8 rounded-2xl border-2 border-gray-200 bg-white hover:border-indigo-300 transition-all"
            >
              <span class="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-gray-100 group-hover:bg-gray-200 transition-colors">
                <.icon name="hero-arrow-right-end-on-rectangle" class="size-7 text-gray-600" />
              </span>
              <span class="font-semibold text-gray-900">Join Room</span>
              <input
                type="text"
                name="code"
                value={@join_code}
                phx-change="update_join_code"
                placeholder="6-digit code"
                maxlength="6"
                inputmode="numeric"
                autocomplete="off"
                class="w-full text-center text-2xl font-mono tracking-[0.4em] py-3 px-4 rounded-xl border border-gray-300 focus:border-violet-500 focus:ring-2 focus:ring-violet-200 outline-none transition-all placeholder:text-gray-300 placeholder:tracking-[0.2em] placeholder:text-base"
              />
              <button
                type="submit"
                class="w-full py-2.5 rounded-xl bg-gray-900 text-white text-sm font-medium hover:bg-gray-800 transition-colors cursor-pointer"
              >
                Join
              </button>
            </form>
          </div>

          <p class="text-xs text-gray-400 mt-8 text-center max-w-sm">
            Rooms auto-expire after 10 minutes of inactivity. Nothing is stored on any server.
          </p>
        </div>
      <% else %>
        <%!-- ═══════ ROOM ═══════ --%>
        <div class="max-w-2xl mx-auto space-y-6 pb-8">
          <%!-- Room Header --%>
          <div class="text-center pt-4 sm:pt-6">
            <p class="text-sm font-medium text-violet-600 mb-2">Room Code</p>
            <button
              id="room-code-display"
              phx-hook=".CopyCode"
              phx-update="ignore"
              data-code={@room_code}
              class="inline-flex items-center gap-3 px-6 py-3 rounded-2xl bg-gray-900 cursor-pointer hover:bg-gray-800 transition-colors group"
            >
              <span class="text-3xl sm:text-4xl font-mono font-bold tracking-[0.5em] text-white">
                {@room_code}
              </span>
              <span class="flex flex-col items-center">
                <.icon
                  name="hero-clipboard-document"
                  class="size-5 text-gray-400 group-hover:text-white transition-colors"
                />
                <span
                  data-label
                  class="text-[10px] text-gray-500 group-hover:text-gray-300 transition-colors"
                >
                  Copy
                </span>
              </span>
            </button>
            <p class="text-xs text-gray-400 mt-2">Share this code with your other device</p>
          </div>

          <%!-- Input Area --%>
          <form id="clip-form" phx-submit="add_clip" class="relative">
            <textarea
              name="text"
              value={@clip_text}
              phx-change="update_clip_text"
              placeholder="Paste or type anything — links, text"
              rows="3"
              class="w-full p-4 pr-16 rounded-2xl border border-gray-200 focus:border-violet-400 focus:ring-2 focus:ring-violet-100 outline-none resize-none text-gray-800 placeholder:text-gray-400 transition-all"
            />
            <button
              type="submit"
              class="absolute right-3 bottom-3 inline-flex items-center justify-center w-10 h-10 rounded-xl bg-gradient-to-br from-violet-500 to-indigo-600 text-white shadow-md hover:shadow-lg hover:scale-105 transition-all cursor-pointer"
            >
              <.icon name="hero-paper-airplane" class="size-5 -rotate-45" />
            </button>
          </form>

          <%!-- Clips List --%>
          <div>
            <div id="clips" phx-update="stream" class="space-y-3">
              <div class="hidden only:flex flex-col items-center justify-center py-16 text-gray-400">
                <.icon name="hero-inbox" class="size-12 mb-3 text-gray-300" />
                <p class="text-sm">No clips yet. Drop something!</p>
              </div>

              <div
                :for={{id, clip} <- @streams.clips}
                id={id}
                class="group flex items-start gap-3 p-4 rounded-2xl bg-white border border-gray-100 hover:border-violet-200 hover:shadow-sm transition-all"
              >
                <div class="flex-1 min-w-0">
                  <p class="text-gray-800 whitespace-pre-wrap break-words text-sm sm:text-base">
                    {clip.text}
                  </p>
                  <p class="text-[11px] text-gray-400 mt-1.5">{format_clip_time(clip.timestamp)}</p>
                </div>
                <div class="flex items-center gap-1 shrink-0 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button
                    id={"copy-" <> id}
                    phx-hook=".CopyClip"
                    phx-update="ignore"
                    data-text={clip.text}
                    class="p-2 rounded-lg text-gray-400 hover:text-violet-600 hover:bg-violet-50 transition-colors cursor-pointer"
                  >
                    <.icon name="hero-clipboard-document" class="size-4" />
                  </button>
                  <button
                    phx-click="delete_clip"
                    phx-value-id={clip.id}
                    class="p-2 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 transition-colors cursor-pointer"
                  >
                    <.icon name="hero-trash" class="size-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          <%!-- Leave Button --%>
          <div class="text-center pt-2">
            <button
              id="leave-room-btn"
              phx-click="leave_room"
              class="text-sm text-gray-400 hover:text-red-500 transition-colors cursor-pointer"
            >
              Leave Room
            </button>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end
end
