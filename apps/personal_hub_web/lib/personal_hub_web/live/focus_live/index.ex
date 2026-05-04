defmodule PersonalHubWeb.FocusLive.Index do
  use PersonalHubWeb, :live_view

  alias PersonalHub.Focus.RoomServer

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Focus Rooms", code: "")}
  end

  @impl true
  def handle_event("update_code", %{"code" => code}, socket) do
    {:noreply, assign(socket, code: String.upcase(code))}
  end

  @impl true
  def handle_event("create_room", _params, socket) do
    code = RoomServer.generate_code()
    RoomServer.create_room(code)
    {:noreply, push_navigate(socket, to: ~p"/focus/#{code}")}
  end

  @impl true
  def handle_event("join_room", _params, socket) do
    code = socket.assigns.code
    if RoomServer.room_exists?(code) do
      {:noreply, push_navigate(socket, to: ~p"/focus/#{code}")}
    else
      {:noreply, put_flash(socket, :error, "Focus room not found")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-md mx-auto mt-12 space-y-8 text-center">
        <div>
          <div class="w-16 h-16 bg-rose-100 text-rose-600 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <.icon name="hero-clock" class="size-8" />
          </div>
          <h1 class="text-3xl font-bold text-gray-900 tracking-tight">Focus Rooms</h1>
          <p class="text-gray-500 mt-2">Multiplayer Pomodoro sessions. Sync your deep work with friends.</p>
        </div>

        <div class="bg-white p-6 rounded-3xl border border-gray-200 shadow-sm space-y-6">
          <button
            phx-click="create_room"
            class="w-full py-3.5 bg-gray-900 text-white rounded-xl font-medium hover:bg-gray-800 transition-colors cursor-pointer"
          >
            Create New Room
          </button>

          <div class="relative flex items-center py-2">
            <div class="flex-grow border-t border-gray-200"></div>
            <span class="flex-shrink-0 mx-4 text-gray-400 text-sm">or join with code</span>
            <div class="flex-grow border-t border-gray-200"></div>
          </div>

          <form phx-submit="join_room" class="space-y-3">
            <input
              type="text"
              name="code"
              value={@code}
              phx-keyup="update_code"
              placeholder="Enter 6-digit code"
              maxlength="6"
              class="w-full text-center tracking-[0.2em] font-mono text-xl py-3 rounded-xl border border-gray-300 focus:ring-2 focus:ring-rose-500 focus:border-rose-500"
            />
            <button
              type="submit"
              disabled={String.length(@code) < 6}
              class="w-full py-3.5 bg-rose-50 text-rose-700 rounded-xl font-medium hover:bg-rose-100 disabled:opacity-50 transition-colors cursor-pointer"
            >
              Join Room
            </button>
          </form>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
