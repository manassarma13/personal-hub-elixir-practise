defmodule PersonalHubWeb.HabitsLive.Index do
  use PersonalHubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today() |> Date.to_iso8601()
    
    {:ok,
     socket
     |> assign(page_title: "Habit Tracker")
     |> assign(habits: [])
     |> assign(new_habit_name: "")
     |> assign(today: today)}
  end

  @impl true
  def handle_event("ls:loaded", data, socket) do
    habits = data["habits"] || []
    {:noreply, assign(socket, habits: habits)}
  end

  @impl true
  def handle_event("update_new_habit", %{"name" => name}, socket) do
    {:noreply, assign(socket, new_habit_name: name)}
  end

  @impl true
  def handle_event("add_habit", _params, socket) do
    name = socket.assigns.new_habit_name
    if name != "" do
      habit = %{
        "id" => System.unique_integer([:positive]) |> Integer.to_string(),
        "name" => name,
        "history" => [] # list of YYYY-MM-DD strings
      }
      habits = [habit | socket.assigns.habits]
      
      {:noreply,
       socket
       |> assign(habits: habits, new_habit_name: "")
       |> push_event("ls:store", %{collection: "habits", data: habits})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_habit", %{"id" => id}, socket) do
    habits = Enum.reject(socket.assigns.habits, fn h -> h["id"] == id end)
    {:noreply,
     socket
     |> assign(habits: habits)
     |> push_event("ls:store", %{collection: "habits", data: habits})}
  end

  @impl true
  def handle_event("toggle_date", %{"id" => id, "date" => date}, socket) do
    habits = Enum.map(socket.assigns.habits, fn h ->
      if h["id"] == id do
        history = h["history"]
        new_history = if date in history, do: List.delete(history, date), else: [date | history]
        %{h | "history" => new_history}
      else
        h
      end
    end)

    {:noreply,
     socket
     |> assign(habits: habits)
     |> push_event("ls:store", %{collection: "habits", data: habits})}
  end

  defp past_days() do
    today = Date.utc_today()
    for i <- 14..0//-1, do: Date.add(today, -i) |> Date.to_iso8601()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="habits-store" phx-hook="LocalStore" phx-update="ignore" data-collections="habits"></div>

      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl sm:text-3xl font-bold text-gray-900 tracking-tight">Habit Tracker</h1>
            <p class="text-gray-500 mt-1">Build streaks, build yourself.</p>
          </div>
        </div>

        <div class="bg-white border border-gray-200 rounded-2xl p-5">
          <form phx-submit="add_habit" class="flex gap-2 mb-6">
            <input
              type="text"
              name="name"
              phx-keyup="update_new_habit"
              value={@new_habit_name}
              placeholder="E.g., Read 10 pages, Code 1 hour..."
              class="flex-1 rounded-xl border border-gray-200 px-4 py-2 text-sm focus:ring-primary focus:border-primary"
            />
            <button
              type="submit"
              disabled={@new_habit_name == ""}
              class="px-4 py-2 bg-gray-900 text-white rounded-xl text-sm font-medium hover:bg-gray-800 disabled:opacity-50 transition-colors"
            >
              Add Habit
            </button>
          </form>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr>
                  <th class="p-3 text-sm font-semibold text-gray-700 min-w-[150px]">Habit</th>
                  <%= for date <- past_days() do %>
                    <th class="p-3 text-xs text-gray-400 font-medium text-center min-w-[30px]">
                      {String.slice(date, 8..9)}
                    </th>
                  <% end %>
                  <th class="p-3"></th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%= if @habits == [] do %>
                  <tr>
                    <td colspan="17" class="p-6 text-center text-sm text-gray-500">
                      No habits yet. Start building one today!
                    </td>
                  </tr>
                <% end %>
                <%= for habit <- @habits do %>
                  <tr class="hover:bg-gray-50 transition-colors">
                    <td class="p-3 text-sm font-medium text-gray-900">
                      {habit["name"]}
                    </td>
                    <%= for date <- past_days() do %>
                      <td class="p-1 text-center">
                        <button
                          phx-click="toggle_date"
                          phx-value-id={habit["id"]}
                          phx-value-date={date}
                          class={[
                            "w-6 h-6 rounded-md transition-colors cursor-pointer mx-auto",
                            if(date in habit["history"], do: "bg-emerald-500 hover:bg-emerald-600", else: "bg-gray-100 hover:bg-gray-200")
                          ]}
                        >
                        </button>
                      </td>
                    <% end %>
                    <td class="p-3 text-right">
                      <button phx-click="delete_habit" phx-value-id={habit["id"]} class="text-gray-400 hover:text-red-500 cursor-pointer">
                        <.icon name="hero-trash" class="size-4" />
                      </button>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
