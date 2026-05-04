defmodule PersonalHubWeb.FocusLive.Room do
  use PersonalHubWeb, :live_view

  alias PersonalHub.Focus.RoomServer

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PersonalHub.PubSub, "focus:#{id}")
    end

    if RoomServer.room_exists?(id) do
      state = RoomServer.get_state(id)
      # Automatically join anonymously for simplicity
      user_id = System.unique_integer([:positive]) |> Integer.to_string()
      RoomServer.join(id, user_id, "User #{String.slice(user_id, -3..-1)}")

      {:ok,
       socket
       |> assign(page_title: "Focus Room #{id}")
       |> assign(room_id: id)
       |> assign(status: state.status)
       |> assign(time_left: state.time_left)
       |> assign(participants: state.participants)}
    else
      {:ok,
       socket
       |> put_flash(:error, "Room expired or does not exist")
       |> push_navigate(to: ~p"/focus")}
    end
  end

  @impl true
  def handle_event("start_focus", _params, socket) do
    RoomServer.start_timer(socket.assigns.room_id, :focus)
    {:noreply, socket}
  end

  @impl true
  def handle_event("start_break", _params, socket) do
    RoomServer.start_timer(socket.assigns.room_id, :break)
    {:noreply, socket}
  end

  @impl true
  def handle_event("stop_timer", _params, socket) do
    RoomServer.stop_timer(socket.assigns.room_id)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:tick, time_left}, socket) do
    {:noreply, assign(socket, time_left: time_left)}
  end

  @impl true
  def handle_info({:state_updated, state}, socket) do
    {:noreply,
     socket
     |> assign(status: state.status)
     |> assign(time_left: state.time_left)
     |> assign(participants: state.participants)}
  end

  @impl true
  def handle_info({:timer_finished, previous_status}, socket) do
    msg = if previous_status == :focus, do: "Focus session complete! Time for a break.", else: "Break over! Ready to focus?"
    {:noreply, put_flash(socket, :info, msg)}
  end

  defp format_time(seconds) do
    m = div(seconds, 60) |> Integer.to_string() |> String.pad_leading(2, "0")
    s = rem(seconds, 60) |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{m}:#{s}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-3xl mx-auto space-y-8">
        <div class="flex items-center justify-between">
          <.link navigate={~p"/focus"} class="text-sm text-gray-500 hover:text-gray-900 inline-flex items-center gap-1.5">
            <.icon name="hero-arrow-left" class="size-4" /> Leave Room
          </.link>
          <div class="bg-white px-4 py-1.5 rounded-full border border-gray-200 text-sm font-mono tracking-widest text-gray-700 shadow-sm">
            CODE: {@room_id}
          </div>
        </div>

        <div class="bg-white rounded-3xl border border-gray-200 p-8 sm:p-16 text-center shadow-sm">
          <h2 class={[
            "text-lg font-bold tracking-widest uppercase mb-4",
            @status == :idle && "text-gray-400",
            @status == :focus && "text-rose-500",
            @status == :break && "text-emerald-500"
          ]}>
            {if @status == :idle, do: "Waiting to start", else: Atom.to_string(@status)}
          </h2>

          <div class="text-7xl sm:text-9xl font-black font-mono tracking-tighter text-gray-900 mb-12 tabular-nums">
            {format_time(@time_left)}
          </div>

          <div class="flex justify-center gap-3">
            <%= if @status == :idle do %>
              <button phx-click="start_focus" class="px-8 py-4 bg-rose-600 text-white rounded-2xl font-bold text-lg hover:bg-rose-700 transition-colors shadow-sm cursor-pointer">
                Start Focus (25m)
              </button>
              <button phx-click="start_break" class="px-8 py-4 bg-emerald-600 text-white rounded-2xl font-bold text-lg hover:bg-emerald-700 transition-colors shadow-sm cursor-pointer">
                Start Break (5m)
              </button>
            <% else %>
              <button phx-click="stop_timer" class="px-8 py-4 bg-gray-100 text-gray-700 rounded-2xl font-bold text-lg hover:bg-gray-200 transition-colors cursor-pointer">
                Stop Timer
              </button>
            <% end %>
          </div>
        </div>

        <div class="bg-white rounded-2xl border border-gray-200 p-6">
          <h3 class="text-sm font-bold text-gray-900 mb-4 flex items-center gap-2">
            <.icon name="hero-users" class="size-5 text-gray-400" />
            Participants ({map_size(@participants)})
          </h3>
          <div class="flex flex-wrap gap-2">
            <%= for {_, name} <- @participants do %>
              <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                {name}
              </span>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
