defmodule PersonalHubWeb.TaskLive.Index do
  use PersonalHubWeb, :live_view

  @statuses ["todo", "in_progress", "done"]
  @priorities ["low", "medium", "high"]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       tasks: [],
       page_title: "Tasks",
       task: nil,
       form: nil,
       edit_id: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, task: nil, form: nil, edit_id: nil)
  end

  defp apply_action(socket, :new, _params) do
    form =
      to_form(
        %{"title" => "", "description" => "", "status" => "todo", "priority" => "medium", "due_date" => ""},
        as: :task
      )

    socket
    |> assign(page_title: "New Task")
    |> assign(task: nil, edit_id: nil)
    |> assign(form: form)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(page_title: "Edit Task", edit_id: id)
    |> setup_edit_form()
  end

  defp setup_edit_form(%{assigns: %{edit_id: nil}} = socket), do: socket

  defp setup_edit_form(%{assigns: %{edit_id: id, tasks: tasks}} = socket) do
    case Enum.find(tasks, fn t -> t["id"] == id end) do
      nil ->
        socket

      task ->
        form =
          to_form(
            %{
              "title" => task["title"] || "",
              "description" => task["description"] || "",
              "status" => task["status"] || "todo",
              "priority" => task["priority"] || "medium",
              "due_date" => task["due_date"] || ""
            },
            as: :task
          )

        assign(socket, task: task, form: form)
    end
  end

  @impl true
  def handle_event("ls:loaded", %{"tasks" => tasks}, socket) do
    socket =
      socket
      |> assign(tasks: tasks || [])
      |> setup_edit_form()

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tasks = Enum.reject(socket.assigns.tasks, fn t -> t["id"] == id end)

    {:noreply,
     socket
     |> assign(tasks: tasks)
     |> push_event("ls:store", %{key: "tasks", data: tasks})}
  end

  @impl true
  def handle_event("complete", %{"id" => id}, socket) do
    tasks =
      Enum.map(socket.assigns.tasks, fn t ->
        if t["id"] == id, do: Map.put(t, "status", "done"), else: t
      end)

    {:noreply,
     socket
     |> assign(tasks: tasks)
     |> push_event("ls:store", %{key: "tasks", data: tasks})}
  end

  @impl true
  def handle_event("start", %{"id" => id}, socket) do
    tasks =
      Enum.map(socket.assigns.tasks, fn t ->
        if t["id"] == id, do: Map.put(t, "status", "in_progress"), else: t
      end)

    {:noreply,
     socket
     |> assign(tasks: tasks)
     |> push_event("ls:store", %{key: "tasks", data: tasks})}
  end

  @impl true
  def handle_event("save", %{"task" => task_params}, socket) do
    save_task(socket, socket.assigns.live_action, task_params)
  end

  defp save_task(socket, :new, params) do
    new_task = %{
      "id" => generate_id(),
      "title" => params["title"],
      "description" => params["description"],
      "status" => params["status"] || "todo",
      "priority" => params["priority"] || "medium",
      "due_date" => params["due_date"],
      "inserted_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    tasks = socket.assigns.tasks ++ [new_task]

    {:noreply,
     socket
     |> assign(tasks: tasks)
     |> push_event("ls:store", %{key: "tasks", data: tasks})
     |> put_flash(:info, "Task created!")
     |> push_navigate(to: ~p"/tasks")}
  end

  defp save_task(socket, :edit, params) do
    tasks =
      Enum.map(socket.assigns.tasks, fn t ->
        if t["id"] == socket.assigns.edit_id do
          Map.merge(t, %{
            "title" => params["title"],
            "description" => params["description"],
            "status" => params["status"],
            "priority" => params["priority"],
            "due_date" => params["due_date"],
            "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
          })
        else
          t
        end
      end)

    {:noreply,
     socket
     |> assign(tasks: tasks)
     |> push_event("ls:store", %{key: "tasks", data: tasks})
     |> put_flash(:info, "Task updated!")
     |> push_navigate(to: ~p"/tasks")}
  end

  defp generate_id do
    :erlang.unique_integer([:positive]) |> Integer.to_string()
  end

  defp due_soon?(due_date_str) do
    case Date.from_iso8601(due_date_str) do
      {:ok, due_date} -> Date.diff(due_date, Date.utc_today()) <= 2
      _ -> false
    end
  end

  defp status_class("todo"), do: "rounded-full px-2.5 py-0.5 text-xs font-medium bg-amber-50 text-amber-700"
  defp status_class("in_progress"), do: "rounded-full px-2.5 py-0.5 text-xs font-medium bg-blue-50 text-blue-700"
  defp status_class("done"), do: "rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-50 text-green-700"
  defp status_class(_), do: "rounded-full px-2.5 py-0.5 text-xs font-medium bg-gray-100 text-gray-600"

  defp priority_class("high"), do: "rounded-full px-2 py-0.5 text-xs font-medium bg-red-50 text-red-700"
  defp priority_class("medium"), do: "rounded-full px-2 py-0.5 text-xs font-medium bg-amber-50 text-amber-600"
  defp priority_class("low"), do: "rounded-full px-2 py-0.5 text-xs font-medium bg-gray-100 text-gray-600"
  defp priority_class(_), do: "rounded-full px-2 py-0.5 text-xs font-medium bg-gray-100 text-gray-600"

  defp status_options do
    Enum.map(@statuses, &{String.replace(&1, "_", " ") |> String.capitalize(), &1})
  end

  defp priority_options do
    Enum.map(@priorities, &{String.capitalize(&1), &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
    <div id="local-store" phx-hook="LocalStore" phx-update="ignore" data-collections="tasks"></div>
    <div class="max-w-4xl mx-auto space-y-6">
      <.link navigate={~p"/"} class="inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors">
        <.icon name="hero-arrow-left" class="size-4" />
        Dashboard
      </.link>

      <div class="flex justify-between items-center">
        <h1 class="text-2xl font-semibold text-gray-900">Tasks</h1>
        <.link navigate={~p"/tasks/new"} class="px-4 py-2 rounded-xl text-sm font-medium text-white bg-primary hover:bg-primary/90 transition-colors">
          New Task
        </.link>
      </div>

      <%= if @live_action in [:new, :edit] and @form do %>
        <div class="bg-white border border-gray-200 rounded-2xl p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-5">{@page_title}</h2>
          <.form for={@form} id="task-form" phx-submit="save" class="space-y-5">
            <.input field={@form[:title]} type="text" label="Title" required />
            <.input field={@form[:description]} type="textarea" label="Description" rows="3" />
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <.input field={@form[:status]} type="select" label="Status" options={status_options()} />
              <.input field={@form[:priority]} type="select" label="Priority" options={priority_options()} />
              <.input field={@form[:due_date]} type="date" label="Due Date" />
            </div>

            <div class="flex items-center gap-3 pt-2">
              <button type="submit" class="px-4 py-2 rounded-xl text-sm font-medium text-white bg-primary hover:bg-primary/90 transition-colors">
                Save
              </button>
              <.link navigate={~p"/tasks"} class="text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors">
                Cancel
              </.link>
            </div>
          </.form>
        </div>
      <% end %>

      <div class="space-y-3">
        <%= for task <- @tasks do %>
          <div class={[
            "bg-white border border-gray-200 rounded-2xl p-5",
            if(task["status"] == "done", do: "opacity-60")
          ]}>
            <div class="flex justify-between items-center">
              <div class="flex-1 min-w-0">
                <h3 class={[
                  "font-semibold text-gray-900",
                  if(task["status"] == "done", do: "line-through")
                ]}>
                  {task["title"]}
                </h3>
                <%= if task["description"] && task["description"] != "" do %>
                  <p class="text-sm text-gray-500 mt-1">{String.slice(task["description"], 0..100)}</p>
                <% end %>
              </div>
              <div class="flex items-center gap-2 ml-4 shrink-0">
                <span class={status_class(task["status"])}>{String.replace(task["status"] || "", "_", " ")}</span>
                <span class={priority_class(task["priority"])}>{task["priority"]}</span>
                <%= if task["due_date"] && task["due_date"] != "" do %>
                  <span class={[
                    "text-xs font-medium",
                    if(task["status"] != "done" && due_soon?(task["due_date"]), do: "text-red-500", else: "text-gray-400")
                  ]}>
                    <.icon name="hero-calendar" class="size-3 inline mr-0.5" />
                    {task["due_date"]}
                  </span>
                <% end %>
              </div>
            </div>
            <div class="flex items-center gap-2 mt-2">
              <span class="text-xs text-gray-400" title={format_datetime(task["inserted_at"])}>
                <.icon name="hero-clock" class="size-3 inline mr-0.5" />
                {relative_time(task["inserted_at"])}
              </span>
              <%= if task["updated_at"] do %>
                <span class="text-xs text-gray-400">
                  · edited {relative_time(task["updated_at"])}
                </span>
              <% end %>
            </div>
            <div class="flex items-center gap-3 mt-3 pt-3 border-t border-gray-100">
              <%= if task["status"] == "todo" do %>
                <button phx-click="start" phx-value-id={task["id"]} class="px-3 py-1 rounded-lg text-xs font-medium border border-blue-200 text-blue-600 hover:bg-blue-50 transition-colors">Start</button>
              <% end %>
              <%= if task["status"] != "done" do %>
                <button phx-click="complete" phx-value-id={task["id"]} class="px-3 py-1 rounded-lg text-xs font-medium border border-green-200 text-green-600 hover:bg-green-50 transition-colors">Done</button>
              <% end %>
              <.link navigate={~p"/tasks/#{task["id"]}/edit"} class="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors">Edit</.link>
              <button phx-click="delete" phx-value-id={task["id"]} class="text-sm font-medium text-red-500 hover:text-red-700 transition-colors"
                data-confirm="Delete this task?">Delete</button>
            </div>
          </div>
        <% end %>

        <%= if @tasks == [] do %>
          <div class="text-center py-16">
            <p class="text-lg font-medium text-gray-400">No tasks yet</p>
            <p class="mt-1 text-sm text-gray-400">Create your first task!</p>
          </div>
        <% end %>
      </div>
    </div>
    </Layouts.app>
    """
  end
end
