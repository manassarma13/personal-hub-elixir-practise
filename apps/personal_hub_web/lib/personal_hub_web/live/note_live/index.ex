defmodule PersonalHubWeb.NoteLive.Index do
  use PersonalHubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       notes: [],
       page_title: "Notes",
       note: nil,
       form: nil,
       edit_id: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, note: nil, form: nil, edit_id: nil)
  end

  defp apply_action(socket, :new, _params) do
    form = to_form(%{"title" => "", "content" => ""}, as: :note)

    socket
    |> assign(page_title: "New Note")
    |> assign(note: nil, edit_id: nil)
    |> assign(form: form)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(page_title: "Edit Note", edit_id: id)
    |> setup_edit_form()
  end

  defp setup_edit_form(%{assigns: %{edit_id: nil}} = socket), do: socket

  defp setup_edit_form(%{assigns: %{edit_id: id, notes: notes}} = socket) do
    case Enum.find(notes, fn n -> n["id"] == id end) do
      nil ->
        socket

      note ->
        form =
          to_form(
            %{"title" => note["title"] || "", "content" => note["content"] || ""},
            as: :note
          )

        assign(socket, note: note, form: form)
    end
  end

  @impl true
  def handle_event("ls:loaded", %{"notes" => notes}, socket) do
    socket =
      socket
      |> assign(notes: notes || [])
      |> setup_edit_form()

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    notes = Enum.reject(socket.assigns.notes, fn n -> n["id"] == id end)

    {:noreply,
     socket
     |> assign(notes: notes)
     |> push_event("ls:store", %{key: "notes", data: notes})}
  end

  @impl true
  def handle_event("toggle_pin", %{"id" => id}, socket) do
    notes =
      Enum.map(socket.assigns.notes, fn n ->
        if n["id"] == id do
          Map.put(n, "pinned", !n["pinned"])
        else
          n
        end
      end)

    {:noreply,
     socket
     |> assign(notes: notes)
     |> push_event("ls:store", %{key: "notes", data: notes})}
  end

  @impl true
  def handle_event("save", %{"note" => note_params}, socket) do
    save_note(socket, socket.assigns.live_action, note_params)
  end

  defp save_note(socket, :new, params) do
    new_note = %{
      "id" => generate_id(),
      "title" => params["title"],
      "content" => params["content"],
      "pinned" => false,
      "inserted_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    notes = socket.assigns.notes ++ [new_note]

    {:noreply,
     socket
     |> assign(notes: notes)
     |> push_event("ls:store", %{key: "notes", data: notes})
     |> put_flash(:info, "Note created!")
     |> push_navigate(to: ~p"/notes")}
  end

  defp save_note(socket, :edit, params) do
    notes =
      Enum.map(socket.assigns.notes, fn n ->
        if n["id"] == socket.assigns.edit_id do
          Map.merge(n, %{
            "title" => params["title"],
            "content" => params["content"],
            "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
          })
        else
          n
        end
      end)

    {:noreply,
     socket
     |> assign(notes: notes)
     |> push_event("ls:store", %{key: "notes", data: notes})
     |> put_flash(:info, "Note updated!")
     |> push_navigate(to: ~p"/notes")}
  end

  defp generate_id do
    :erlang.unique_integer([:positive]) |> Integer.to_string()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="local-store" phx-hook="LocalStore" phx-update="ignore" data-collections="notes"></div>
      <div class="max-w-4xl mx-auto space-y-6">
        <.link
          navigate={~p"/"}
          class="inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Dashboard
        </.link>

        <div class="flex justify-between items-center">
          <h1 class="text-2xl font-semibold text-gray-900">Notes</h1>
          <.link
            navigate={~p"/notes/new"}
            class="px-4 py-2 rounded-xl text-sm font-medium text-white bg-primary hover:bg-primary/90 transition-colors"
          >
            New Note
          </.link>
        </div>

        <%= if @live_action in [:new, :edit] and @form do %>
          <div class="bg-white border border-gray-200 rounded-2xl p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-5">{@page_title}</h2>
            <.form for={@form} id="note-form" phx-submit="save" class="space-y-5">
              <.input field={@form[:title]} type="text" label="Title" required />
              <.input field={@form[:content]} type="textarea" label="Content" rows="4" required />

              <div class="flex items-center gap-3 pt-2">
                <button
                  type="submit"
                  class="px-4 py-2 rounded-xl text-sm font-medium text-white bg-primary hover:bg-primary/90 transition-colors"
                >
                  Save
                </button>
                <.link
                  navigate={~p"/notes"}
                  class="text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors"
                >
                  Cancel
                </.link>
              </div>
            </.form>
          </div>
        <% end %>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for note <- @notes do %>
            <div class={[
              "bg-white border rounded-2xl p-5 hover:shadow-md transition-shadow",
              if(note["pinned"], do: "border-amber-300 bg-amber-50/30", else: "border-gray-200")
            ]}>
              <div class="flex items-start gap-2 mb-2">
                <%= if note["pinned"] do %>
                  <span class="rounded-full px-2 py-0.5 text-xs font-medium bg-amber-100 text-amber-700">
                    Pinned
                  </span>
                <% end %>
              </div>
              <h2 class="text-base font-semibold text-gray-900">{note["title"]}</h2>
              <p class="text-sm text-gray-500 mt-1.5 line-clamp-3">
                {String.slice(note["content"] || "", 0..150)}
              </p>
              <div class="flex items-center gap-2 mt-3">
                <span class="text-xs text-gray-400" title={format_datetime(note["inserted_at"])}>
                  <.icon name="hero-clock" class="size-3 inline mr-0.5" />
                  {relative_time(note["inserted_at"])}
                </span>
                <%= if note["updated_at"] do %>
                  <span class="text-xs text-gray-400" title={format_datetime(note["updated_at"])}>
                    · edited {relative_time(note["updated_at"])}
                  </span>
                <% end %>
              </div>
              <div class="flex items-center gap-3 mt-3 pt-3 border-t border-gray-100">
                <button
                  phx-click="toggle_pin"
                  phx-value-id={note["id"]}
                  class="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
                >
                  {if note["pinned"], do: "Unpin", else: "Pin"}
                </button>
                <.link
                  navigate={~p"/notes/#{note["id"]}/edit"}
                  class="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
                >
                  Edit
                </.link>
                <button
                  phx-click="delete"
                  phx-value-id={note["id"]}
                  class="text-sm font-medium text-red-500 hover:text-red-700 transition-colors"
                  data-confirm="Delete this note?"
                >
                  Delete
                </button>
              </div>
            </div>
          <% end %>

          <%= if @notes == [] do %>
            <div class="col-span-full text-center py-16">
              <p class="text-lg font-medium text-gray-400">No notes yet</p>
              <p class="mt-1 text-sm text-gray-400">Jot down your first quick note!</p>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
