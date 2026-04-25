defmodule PersonalHubWeb.KanbanLive.Index do
  use PersonalHubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()

    {:ok,
     assign(socket,
       page_title: "Kanban Board",
       posts: [],
       notes: [],
       tasks: [],
       current_month: today,
       today: today,
       view: "kanban"
     )}
  end

  @impl true
  def handle_event("ls:loaded", data, socket) do
    {:noreply,
     assign(socket,
       posts: data["posts"] || [],
       notes: data["notes"] || [],
       tasks: data["tasks"] || []
     )}
  end

  @impl true
  def handle_event("prev_month", _params, socket) do
    current = socket.assigns.current_month
    prev = Date.add(current, -Date.days_in_month(current))
    {:noreply, assign(socket, current_month: prev)}
  end

  @impl true
  def handle_event("next_month", _params, socket) do
    current = socket.assigns.current_month
    next = Date.add(current, Date.days_in_month(current))
    {:noreply, assign(socket, current_month: next)}
  end

  @impl true
  def handle_event("today", _params, socket) do
    {:noreply, assign(socket, current_month: Date.utc_today())}
  end

  @impl true
  def handle_event("toggle_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, view: view)}
  end

  # Calendar helpers

  defp calendar_weeks(date) do
    first_of_month = Date.beginning_of_month(date)
    last_of_month = Date.end_of_month(date)

    start_day = Date.day_of_week(first_of_month, :monday)
    calendar_start = Date.add(first_of_month, -(start_day - 1))

    end_day = Date.day_of_week(last_of_month, :monday)
    calendar_end = Date.add(last_of_month, 7 - end_day)

    Date.range(calendar_start, calendar_end)
    |> Enum.chunk_every(7)
  end

  defp month_name(date) do
    month =
      case date.month do
        1 -> "January"
        2 -> "February"
        3 -> "March"
        4 -> "April"
        5 -> "May"
        6 -> "June"
        7 -> "July"
        8 -> "August"
        9 -> "September"
        10 -> "October"
        11 -> "November"
        12 -> "December"
      end

    "#{month} #{date.year}"
  end

  defp items_for_date(posts, notes, tasks, date) do
    date_str = Date.to_iso8601(date)

    task_items =
      tasks
      |> Enum.filter(fn t -> t["due_date"] == date_str end)
      |> Enum.map(fn t -> %{type: :task, title: t["title"], status: t["status"], id: t["id"]} end)

    post_items =
      posts
      |> Enum.filter(fn p -> to_date_key(p["inserted_at"]) == date_str end)
      |> Enum.map(fn p -> %{type: :post, title: p["title"], id: p["id"]} end)

    note_items =
      notes
      |> Enum.filter(fn n -> to_date_key(n["inserted_at"]) == date_str end)
      |> Enum.map(fn n -> %{type: :note, title: n["title"], id: n["id"]} end)

    task_items ++ post_items ++ note_items
  end

  defp tasks_by_status(tasks, status) do
    Enum.filter(tasks, fn t -> t["status"] == status end)
  end

  defp status_column_class("todo"), do: "border-amber-200 bg-amber-50/50"
  defp status_column_class("in_progress"), do: "border-blue-200 bg-blue-50/50"
  defp status_column_class("done"), do: "border-green-200 bg-green-50/50"
  defp status_column_class(_), do: "border-gray-200 bg-gray-50/50"

  defp status_header_class("todo"), do: "text-amber-700 bg-amber-100"
  defp status_header_class("in_progress"), do: "text-blue-700 bg-blue-100"
  defp status_header_class("done"), do: "text-green-700 bg-green-100"
  defp status_header_class(_), do: "text-gray-700 bg-gray-100"

  defp status_label("todo"), do: "To Do"
  defp status_label("in_progress"), do: "In Progress"
  defp status_label("done"), do: "Done"
  defp status_label(s), do: s

  defp priority_dot("high"), do: "bg-red-500"
  defp priority_dot("medium"), do: "bg-amber-400"
  defp priority_dot("low"), do: "bg-gray-300"
  defp priority_dot(_), do: "bg-gray-300"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div
        id="local-store"
        phx-hook="LocalStore"
        phx-update="ignore"
        data-collections="posts,notes,tasks"
      >
      </div>
      <div class="space-y-6">
        <.link
          navigate={~p"/"}
          class="inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Dashboard
        </.link>

        <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-3">
          <h1 class="text-2xl font-semibold text-gray-900">Kanban Board</h1>
          <div class="flex items-center gap-1 bg-gray-100 rounded-xl p-1">
            <button
              phx-click="toggle_view"
              phx-value-view="kanban"
              class={[
                "px-3 py-1.5 rounded-lg text-sm font-medium transition-colors",
                if(@view == "kanban",
                  do: "bg-white shadow-sm text-gray-900",
                  else: "text-gray-500 hover:text-gray-700"
                )
              ]}
            >
              <.icon name="hero-view-columns" class="size-4 inline mr-1" /> Kanban
            </button>
            <button
              phx-click="toggle_view"
              phx-value-view="calendar"
              class={[
                "px-3 py-1.5 rounded-lg text-sm font-medium transition-colors",
                if(@view == "calendar",
                  do: "bg-white shadow-sm text-gray-900",
                  else: "text-gray-500 hover:text-gray-700"
                )
              ]}
            >
              <.icon name="hero-calendar-days" class="size-4 inline mr-1" /> Calendar
            </button>
          </div>
        </div>

        <%!-- KANBAN VIEW --%>
        <%= if @view == "kanban" do %>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <%= for status <- ["todo", "in_progress", "done"] do %>
              <div class={["rounded-2xl border p-4 min-h-[400px]", status_column_class(status)]}>
                <div class="flex items-center justify-between mb-4">
                  <span class={[
                    "px-3 py-1 rounded-full text-sm font-semibold",
                    status_header_class(status)
                  ]}>
                    {status_label(status)}
                  </span>
                  <span class="text-xs text-gray-400 font-medium">
                    {length(tasks_by_status(@tasks, status))}
                  </span>
                </div>

                <div class="space-y-3">
                  <%= for task <- tasks_by_status(@tasks, status) do %>
                    <div class="bg-white rounded-xl border border-gray-200 p-4 hover:shadow-md transition-shadow">
                      <div class="flex items-start gap-2">
                        <span class={[
                          "mt-1.5 w-2 h-2 rounded-full shrink-0",
                          priority_dot(task["priority"])
                        ]}>
                        </span>
                        <div class="flex-1 min-w-0">
                          <h3 class={[
                            "text-sm font-medium text-gray-900",
                            if(status == "done", do: "line-through opacity-60")
                          ]}>
                            {task["title"]}
                          </h3>
                          <%= if task["description"] && task["description"] != "" do %>
                            <p class="text-xs text-gray-500 mt-1 line-clamp-2">
                              {task["description"]}
                            </p>
                          <% end %>
                          <div class="flex items-center gap-2 mt-2">
                            <span
                              class="text-xs text-gray-400"
                              title={format_datetime(task["inserted_at"])}
                            >
                              {relative_time(task["inserted_at"])}
                            </span>
                            <%= if task["due_date"] && task["due_date"] != "" do %>
                              <span class={[
                                "text-xs font-medium",
                                if(status != "done" && due_soon?(task["due_date"]),
                                  do: "text-red-500",
                                  else: "text-gray-400"
                                )
                              ]}>
                                <.icon name="hero-calendar" class="size-3 inline" />
                                {task["due_date"]}
                              </span>
                            <% end %>
                          </div>
                        </div>
                      </div>
                      <div class="flex items-center gap-2 mt-3 pt-2 border-t border-gray-100">
                        <%= if status == "todo" do %>
                          <.link
                            navigate={~p"/tasks"}
                            class="text-xs font-medium text-blue-600 hover:text-blue-800"
                          >
                            Start
                          </.link>
                        <% end %>
                        <%= if status != "done" do %>
                          <.link
                            navigate={~p"/tasks"}
                            class="text-xs font-medium text-green-600 hover:text-green-800"
                          >
                            Complete
                          </.link>
                        <% end %>
                        <.link
                          navigate={~p"/tasks/#{task["id"]}/edit"}
                          class="text-xs font-medium text-gray-500 hover:text-gray-700"
                        >
                          Edit
                        </.link>
                      </div>
                    </div>
                  <% end %>

                  <%= if tasks_by_status(@tasks, status) == [] do %>
                    <div class="text-center py-8">
                      <p class="text-sm text-gray-400">No tasks</p>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <%!-- Recent Posts & Notes sidebar --%>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6">
            <div class="bg-white rounded-2xl border border-gray-200 p-5">
              <div class="flex items-center justify-between mb-4">
                <h2 class="text-base font-semibold text-gray-900">
                  <.icon name="hero-document-text" class="size-4 inline mr-1 text-blue-500" />
                  Recent Posts
                </h2>
                <.link navigate={~p"/posts"} class="text-xs font-medium text-primary hover:underline">
                  View all
                </.link>
              </div>
              <div class="space-y-2">
                <%= for post <- Enum.take(@posts, 5) do %>
                  <.link
                    navigate={~p"/posts/#{post["id"]}"}
                    class="flex items-center justify-between py-2 px-3 rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    <span class="text-sm text-gray-700 truncate flex-1">{post["title"]}</span>
                    <span class="text-xs text-gray-400 shrink-0 ml-2">
                      {relative_time(post["inserted_at"])}
                    </span>
                  </.link>
                <% end %>
                <%= if @posts == [] do %>
                  <p class="text-sm text-gray-400 text-center py-4">No posts yet</p>
                <% end %>
              </div>
            </div>

            <div class="bg-white rounded-2xl border border-gray-200 p-5">
              <div class="flex items-center justify-between mb-4">
                <h2 class="text-base font-semibold text-gray-900">
                  <.icon name="hero-pencil-square" class="size-4 inline mr-1 text-amber-500" />
                  Recent Notes
                </h2>
                <.link navigate={~p"/notes"} class="text-xs font-medium text-primary hover:underline">
                  View all
                </.link>
              </div>
              <div class="space-y-2">
                <%= for note <- Enum.take(@notes, 5) do %>
                  <div class="flex items-center justify-between py-2 px-3 rounded-lg hover:bg-gray-50 transition-colors">
                    <span class="text-sm text-gray-700 truncate flex-1">
                      <%= if note["pinned"] do %>
                        <.icon name="hero-star-solid" class="size-3 inline mr-1 text-amber-400" />
                      <% end %>
                      {note["title"]}
                    </span>
                    <span class="text-xs text-gray-400 shrink-0 ml-2">
                      {relative_time(note["inserted_at"])}
                    </span>
                  </div>
                <% end %>
                <%= if @notes == [] do %>
                  <p class="text-sm text-gray-400 text-center py-4">No notes yet</p>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>

        <%!-- CALENDAR VIEW --%>
        <%= if @view == "calendar" do %>
          <div class="bg-white rounded-2xl border border-gray-200 overflow-hidden">
            <%!-- Calendar header --%>
            <div class="flex items-center justify-between p-4 border-b border-gray-100">
              <button
                phx-click="prev_month"
                class="p-1.5 rounded-lg hover:bg-gray-100 transition-colors"
              >
                <.icon name="hero-chevron-left" class="size-5 text-gray-600" />
              </button>
              <div class="flex items-center gap-3">
                <h2 class="text-lg font-semibold text-gray-900">{month_name(@current_month)}</h2>
                <button
                  phx-click="today"
                  class="px-2.5 py-1 rounded-lg text-xs font-medium border border-gray-200 text-gray-600 hover:bg-gray-50 transition-colors"
                >
                  Today
                </button>
              </div>
              <button
                phx-click="next_month"
                class="p-1.5 rounded-lg hover:bg-gray-100 transition-colors"
              >
                <.icon name="hero-chevron-right" class="size-5 text-gray-600" />
              </button>
            </div>

            <%!-- Day headers --%>
            <div class="grid grid-cols-7 border-b border-gray-100">
              <%= for day <- ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] do %>
                <div class="p-2 text-center text-xs font-semibold text-gray-500 uppercase tracking-wider">
                  {day}
                </div>
              <% end %>
            </div>

            <%!-- Calendar grid --%>
            <div class="divide-y divide-gray-100">
              <%= for week <- calendar_weeks(@current_month) do %>
                <div class="grid grid-cols-7 divide-x divide-gray-100">
                  <%= for day <- week do %>
                    <% items = items_for_date(@posts, @notes, @tasks, day) %>
                    <div class={[
                      "min-h-[100px] sm:min-h-[120px] p-1.5 sm:p-2",
                      if(day.month != @current_month.month, do: "bg-gray-50/50"),
                      if(day == @today, do: "bg-blue-50/40")
                    ]}>
                      <div class="flex items-center justify-between mb-1">
                        <span class={[
                          "text-xs sm:text-sm font-medium",
                          if(day == @today,
                            do:
                              "bg-primary text-white w-6 h-6 rounded-full flex items-center justify-center",
                            else:
                              if(day.month != @current_month.month,
                                do: "text-gray-300",
                                else: "text-gray-700"
                              )
                          )
                        ]}>
                          {day.day}
                        </span>
                      </div>

                      <div class="space-y-0.5">
                        <%= for item <- Enum.take(items, 3) do %>
                          <div class={[
                            "text-[10px] sm:text-xs px-1.5 py-0.5 rounded truncate font-medium",
                            cond do
                              item.type == :task && item[:status] == "done" ->
                                "bg-green-100 text-green-700"

                              item.type == :task && item[:status] == "in_progress" ->
                                "bg-blue-100 text-blue-700"

                              item.type == :task ->
                                "bg-amber-100 text-amber-700"

                              item.type == :post ->
                                "bg-violet-100 text-violet-700"

                              item.type == :note ->
                                "bg-sky-100 text-sky-700"

                              true ->
                                "bg-gray-100 text-gray-600"
                            end
                          ]}>
                            {item.title}
                          </div>
                        <% end %>
                        <%= if length(items) > 3 do %>
                          <div class="text-[10px] text-gray-400 font-medium pl-1">
                            +{length(items) - 3} more
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>

          <%!-- Calendar legend --%>
          <div class="flex flex-wrap items-center gap-4 px-1">
            <span class="flex items-center gap-1.5 text-xs text-gray-500">
              <span class="w-3 h-3 rounded bg-amber-100 border border-amber-200"></span> Task (todo)
            </span>
            <span class="flex items-center gap-1.5 text-xs text-gray-500">
              <span class="w-3 h-3 rounded bg-blue-100 border border-blue-200"></span>
              Task (in progress)
            </span>
            <span class="flex items-center gap-1.5 text-xs text-gray-500">
              <span class="w-3 h-3 rounded bg-green-100 border border-green-200"></span> Task (done)
            </span>
            <span class="flex items-center gap-1.5 text-xs text-gray-500">
              <span class="w-3 h-3 rounded bg-violet-100 border border-violet-200"></span> Post
            </span>
            <span class="flex items-center gap-1.5 text-xs text-gray-500">
              <span class="w-3 h-3 rounded bg-sky-100 border border-sky-200"></span> Note
            </span>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp due_soon?(due_date_str) do
    case Date.from_iso8601(due_date_str) do
      {:ok, due_date} -> Date.diff(due_date, Date.utc_today()) <= 2
      _ -> false
    end
  end
end
