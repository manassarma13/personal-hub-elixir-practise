defmodule PersonalHubWeb.FlashcardsLive.Index do
  use PersonalHubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Flashcards")
     |> assign(decks: [])
     |> assign(current_view: :list) # :list, :deck, :review
     |> assign(active_deck_id: nil)
     |> assign(new_deck_name: "")
     |> assign(new_card_front: "")
     |> assign(new_card_back: "")
     |> assign(review_queue: [])
     |> assign(show_back: false)}
  end

  @impl true
  def handle_event("ls:loaded", data, socket) do
    decks = data["flashcards_decks"] || []
    {:noreply, assign(socket, decks: decks)}
  end

  @impl true
  def handle_event("update_deck_name", %{"name" => name}, socket) do
    {:noreply, assign(socket, new_deck_name: name)}
  end

  @impl true
  def handle_event("create_deck", _params, socket) do
    name = socket.assigns.new_deck_name
    if name != "" do
      deck = %{
        "id" => System.unique_integer([:positive]) |> Integer.to_string(),
        "name" => name,
        "cards" => []
      }
      decks = [deck | socket.assigns.decks]
      
      {:noreply,
       socket
       |> assign(decks: decks, new_deck_name: "")
       |> push_store(decks)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_deck", %{"id" => id}, socket) do
    decks = Enum.reject(socket.assigns.decks, fn d -> d["id"] == id end)
    {:noreply,
     socket
     |> assign(decks: decks)
     |> push_store(decks)}
  end

  @impl true
  def handle_event("open_deck", %{"id" => id}, socket) do
    {:noreply, assign(socket, current_view: :deck, active_deck_id: id)}
  end

  @impl true
  def handle_event("back_to_list", _params, socket) do
    {:noreply, assign(socket, current_view: :list, active_deck_id: nil, review_queue: [])}
  end

  @impl true
  def handle_event("update_card", %{"front" => front, "back" => back}, socket) do
    {:noreply, assign(socket, new_card_front: front, new_card_back: back)}
  end

  @impl true
  def handle_event("add_card", _params, socket) do
    front = socket.assigns.new_card_front
    back = socket.assigns.new_card_back
    deck_id = socket.assigns.active_deck_id

    if front != "" and back != "" do
      card = %{
        "id" => System.unique_integer([:positive]) |> Integer.to_string(),
        "front" => front,
        "back" => back,
        "next_review" => Date.utc_today() |> Date.to_iso8601()
      }

      decks = Enum.map(socket.assigns.decks, fn d ->
        if d["id"] == deck_id do
          %{d | "cards" => [card | d["cards"]]}
        else
          d
        end
      end)

      {:noreply,
       socket
       |> assign(decks: decks, new_card_front: "", new_card_back: "")
       |> push_store(decks)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_card", %{"id" => card_id}, socket) do
    deck_id = socket.assigns.active_deck_id
    decks = Enum.map(socket.assigns.decks, fn d ->
      if d["id"] == deck_id do
        %{d | "cards" => Enum.reject(d["cards"], fn c -> c["id"] == card_id end)}
      else
        d
      end
    end)
    {:noreply,
     socket
     |> assign(decks: decks)
     |> push_store(decks)}
  end

  @impl true
  def handle_event("start_review", _params, socket) do
    deck = Enum.find(socket.assigns.decks, fn d -> d["id"] == socket.assigns.active_deck_id end)
    today = Date.utc_today() |> Date.to_iso8601()
    
    # Simple algorithm: queue cards that are due today or earlier
    queue = Enum.filter(deck["cards"], fn c -> c["next_review"] <= today end) |> Enum.shuffle()

    {:noreply, assign(socket, current_view: :review, review_queue: queue, show_back: false)}
  end

  @impl true
  def handle_event("reveal", _params, socket) do
    {:noreply, assign(socket, show_back: true)}
  end

  @impl true
  def handle_event("answer", %{"rating" => rating}, socket) do
    [current_card | remaining_queue] = socket.assigns.review_queue
    
    days_to_add = case rating do
      "hard" -> 1
      "good" -> 3
      "easy" -> 5
      _ -> 0 # again
    end

    next_date = Date.utc_today() |> Date.add(days_to_add) |> Date.to_iso8601()
    deck_id = socket.assigns.active_deck_id

    decks = Enum.map(socket.assigns.decks, fn d ->
      if d["id"] == deck_id do
        updated_cards = Enum.map(d["cards"], fn c ->
          if c["id"] == current_card["id"], do: %{c | "next_review" => next_date}, else: c
        end)
        %{d | "cards" => updated_cards}
      else
        d
      end
    end)

    queue = if rating == "again", do: remaining_queue ++ [current_card], else: remaining_queue

    socket = socket
      |> assign(decks: decks, review_queue: queue, show_back: false)
      |> push_store(decks)

    if queue == [] do
      {:noreply, assign(socket, current_view: :deck) |> put_flash(:info, "Review complete!")}
    else
      {:noreply, socket}
    end
  end

  defp push_store(socket, decks) do
    push_event(socket, "ls:store", %{collection: "flashcards_decks", data: decks})
  end

  defp get_active_deck(assigns) do
    Enum.find(assigns.decks, fn d -> d["id"] == assigns.active_deck_id end)
  end

  defp due_count(deck) do
    today = Date.utc_today() |> Date.to_iso8601()
    Enum.count(deck["cards"], fn c -> c["next_review"] <= today end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="flashcards-store" phx-hook="LocalStore" phx-update="ignore" data-collections="flashcards_decks"></div>

      <div class="space-y-6 max-w-4xl mx-auto">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl sm:text-3xl font-bold text-gray-900 tracking-tight">Flashcards</h1>
            <p class="text-gray-500 mt-1">Spaced repetition for long-term memory.</p>
          </div>
        </div>

        <%= if @current_view == :list do %>
          <div class="bg-white border border-gray-200 rounded-2xl p-5">
            <form phx-submit="create_deck" class="flex gap-2 mb-6">
              <input
                type="text"
                name="name"
                phx-keyup="update_deck_name"
                value={@new_deck_name}
                placeholder="New Deck Name (e.g., Elixir Core, Spanish Verbs)"
                class="flex-1 rounded-xl border border-gray-200 px-4 py-2 text-sm focus:ring-primary focus:border-primary"
              />
              <button
                type="submit"
                disabled={@new_deck_name == ""}
                class="px-4 py-2 bg-gray-900 text-white rounded-xl text-sm font-medium hover:bg-gray-800 disabled:opacity-50 transition-colors"
              >
                Create Deck
              </button>
            </form>

            <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
              <%= for deck <- @decks do %>
                <div class="border border-gray-200 rounded-2xl p-5 hover:border-primary/30 hover:shadow-md transition-all group flex flex-col justify-between">
                  <div>
                    <h3 class="font-bold text-gray-900 text-lg mb-1">{deck["name"]}</h3>
                    <p class="text-sm text-gray-500">{length(deck["cards"])} cards total</p>
                    <% due = due_count(deck) %>
                    <p class={["text-sm font-medium mt-2", if(due > 0, do: "text-rose-500", else: "text-emerald-500")]}>
                      {due} cards due
                    </p>
                  </div>
                  <div class="mt-4 flex gap-2">
                    <button phx-click="open_deck" phx-value-id={deck["id"]} class="flex-1 py-2 bg-gray-100 text-gray-800 rounded-lg text-sm font-medium hover:bg-gray-200 transition-colors cursor-pointer">
                      Manage
                    </button>
                    <button phx-click="delete_deck" phx-value-id={deck["id"]} class="px-3 py-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors cursor-pointer">
                      <.icon name="hero-trash" class="size-4" />
                    </button>
                  </div>
                </div>
              <% end %>
              <%= if @decks == [] do %>
                <div class="col-span-full py-12 text-center text-gray-500 text-sm">
                  No decks yet. Create your first deck above.
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <%= if @current_view == :deck do %>
          <% deck = get_active_deck(assigns) %>
          <div class="space-y-4">
            <button phx-click="back_to_list" class="text-sm font-medium text-gray-500 hover:text-gray-900 flex items-center gap-1">
              <.icon name="hero-arrow-left" class="size-4" /> Back to Decks
            </button>
            
            <div class="bg-white border border-gray-200 rounded-2xl p-6 flex items-center justify-between">
              <div>
                <h2 class="text-2xl font-bold text-gray-900">{deck["name"]}</h2>
                <p class="text-gray-500">{length(deck["cards"])} cards • {due_count(deck)} due</p>
              </div>
              <button 
                phx-click="start_review" 
                disabled={due_count(deck) == 0}
                class="px-6 py-3 bg-emerald-600 text-white rounded-xl font-bold hover:bg-emerald-700 disabled:bg-gray-200 disabled:text-gray-400 disabled:cursor-not-allowed transition-colors cursor-pointer"
              >
                Review Now
              </button>
            </div>

            <div class="bg-white border border-gray-200 rounded-2xl p-6">
              <h3 class="font-bold text-gray-900 mb-4">Add Card</h3>
              <form phx-submit="add_card" phx-change="update_card" class="space-y-4">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <textarea name="front" value={@new_card_front} placeholder="Front (Question/Term)" rows="3" class="w-full rounded-xl border border-gray-200 p-3 text-sm focus:ring-primary focus:border-primary resize-none"></textarea>
                  <textarea name="back" value={@new_card_back} placeholder="Back (Answer/Definition)" rows="3" class="w-full rounded-xl border border-gray-200 p-3 text-sm focus:ring-primary focus:border-primary resize-none"></textarea>
                </div>
                <div class="flex justify-end">
                  <button type="submit" disabled={@new_card_front == "" or @new_card_back == ""} class="px-5 py-2 bg-gray-900 text-white rounded-xl text-sm font-medium hover:bg-gray-800 disabled:opacity-50 transition-colors cursor-pointer">
                    Add Card
                  </button>
                </div>
              </form>
            </div>

            <div class="bg-white border border-gray-200 rounded-2xl p-6">
              <h3 class="font-bold text-gray-900 mb-4">Cards</h3>
              <div class="space-y-2">
                <%= for card <- deck["cards"] do %>
                  <div class="flex items-start justify-between p-4 rounded-xl border border-gray-100 bg-gray-50">
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 flex-1">
                      <div>
                        <span class="text-xs font-bold text-gray-400 uppercase block mb-1">Front</span>
                        <p class="text-sm text-gray-900 whitespace-pre-wrap">{card["front"]}</p>
                      </div>
                      <div>
                        <span class="text-xs font-bold text-gray-400 uppercase block mb-1">Back</span>
                        <p class="text-sm text-gray-700 whitespace-pre-wrap">{card["back"]}</p>
                      </div>
                    </div>
                    <div class="ml-4 flex flex-col items-end gap-2">
                      <span class="text-xs text-gray-400">Next: {card["next_review"]}</span>
                      <button phx-click="delete_card" phx-value-id={card["id"]} class="text-gray-400 hover:text-red-500 cursor-pointer">
                        <.icon name="hero-trash" class="size-4" />
                      </button>
                    </div>
                  </div>
                <% end %>
                <%= if deck["cards"] == [] do %>
                  <p class="text-sm text-gray-500 text-center py-4">No cards in this deck yet.</p>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>

        <%= if @current_view == :review do %>
          <% current_card = List.first(@review_queue) %>
          <div class="max-w-2xl mx-auto space-y-6">
            <div class="flex items-center justify-between text-sm font-medium text-gray-500">
              <button phx-click="back_to_list" class="hover:text-gray-900 cursor-pointer">End Review</button>
              <span>{length(@review_queue)} cards remaining</span>
            </div>

            <div class="bg-white rounded-3xl border border-gray-200 shadow-sm overflow-hidden min-h-[300px] flex flex-col relative">
              <div class="p-8 sm:p-12 flex-1 flex items-center justify-center border-b border-gray-100">
                <p class="text-xl sm:text-2xl font-medium text-gray-900 text-center whitespace-pre-wrap leading-relaxed">
                  {current_card["front"]}
                </p>
              </div>

              <%= if @show_back do %>
                <div class="p-8 sm:p-12 bg-amber-50/30 flex-1 flex items-center justify-center">
                  <p class="text-lg sm:text-xl text-gray-800 text-center whitespace-pre-wrap leading-relaxed">
                    {current_card["back"]}
                  </p>
                </div>
              <% end %>
            </div>

            <div class="flex justify-center">
              <%= if not @show_back do %>
                <button phx-click="reveal" class="w-full sm:w-auto px-8 py-4 bg-gray-900 text-white rounded-xl font-bold hover:bg-gray-800 transition-colors cursor-pointer shadow-sm">
                  Show Answer
                </button>
              <% else %>
                <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 w-full">
                  <button phx-click="answer" phx-value-rating="again" class="py-3 bg-red-50 text-red-700 rounded-xl font-medium hover:bg-red-100 transition-colors cursor-pointer">
                    Again <span class="block text-xs font-normal opacity-70">&lt; 1m</span>
                  </button>
                  <button phx-click="answer" phx-value-rating="hard" class="py-3 bg-orange-50 text-orange-700 rounded-xl font-medium hover:bg-orange-100 transition-colors cursor-pointer">
                    Hard <span class="block text-xs font-normal opacity-70">1d</span>
                  </button>
                  <button phx-click="answer" phx-value-rating="good" class="py-3 bg-emerald-50 text-emerald-700 rounded-xl font-medium hover:bg-emerald-100 transition-colors cursor-pointer">
                    Good <span class="block text-xs font-normal opacity-70">3d</span>
                  </button>
                  <button phx-click="answer" phx-value-rating="easy" class="py-3 bg-blue-50 text-blue-700 rounded-xl font-medium hover:bg-blue-100 transition-colors cursor-pointer">
                    Easy <span class="block text-xs font-normal opacity-70">5d</span>
                  </button>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
