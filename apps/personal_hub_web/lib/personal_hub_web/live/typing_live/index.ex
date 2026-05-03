defmodule PersonalHubWeb.TypingLive.Index do
  use PersonalHubWeb, :live_view

  @words ~w(
    the quick brown fox jumps over lazy dog pack my box with five dozen liquor jugs
    how vexingly daft quirky zebras jump sphinx of black quartz judge vow
    two driven jocks help fax big quiz waltz nymph quaff vexed glyph buxom
    bright waves crash shore distant thunder fades soft breeze moves tall grass
    silver moon rises calm forest hums night birds call hollow trees echo
    sharp cliffs drop ocean deep currents pull drift cold salt spray mist
    ancient maps hold secrets faded ink marks forgotten paths lead nowhere
    copper wires spark blue flame circuit board hums voltage flows signal lost
    glass towers reflect clouds invisible threads connect distant minds speak
    frozen rivers crack spring thaw floods plains seeds sprout green shoots rise
    crumbled walls tell stories broken roads lead somewhere stranger things wait
    bold travelers find hidden valleys written words outlast all memory fades
    random bursts color paint silence golden hum vibrates hollow space fills
  )

  @total_words 60
  @duration 60

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Typing Game")
     |> assign_fresh_game()}
  end

  @impl true
  def handle_event("typing", %{"typed" => typed}, socket) do
    socket =
      if socket.assigns.status == :idle and typed != "" do
        Process.send_after(self(), :tick, 1000)
        assign(socket, status: :running)
      else
        socket
      end

    if socket.assigns.status == :finished do
      {:noreply, socket}
    else
      target = socket.assigns.target_text
      graphemes = String.graphemes(typed)
      target_graphemes = String.graphemes(target)

      {correct, errors} =
        graphemes
        |> Enum.zip(target_graphemes)
        |> Enum.reduce({0, 0}, fn {t, g}, {c, e} ->
          if t == g, do: {c + 1, e}, else: {c, e + 1}
        end)

      elapsed = @duration - socket.assigns.time_left
      wpm = if elapsed > 0, do: round(correct / 5 / (elapsed / 60)), else: 0

      {:noreply,
       socket
       |> assign(typed_text: typed)
       |> assign(correct_chars: correct)
       |> assign(error_chars: errors)
       |> assign(wpm: wpm)}
    end
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> assign_fresh_game()
     |> push_event("clear-input", %{})}
  end

  @impl true
  def handle_info(:tick, %{assigns: %{status: :running}} = socket) do
    time_left = socket.assigns.time_left - 1

    if time_left <= 0 do
      correct = socket.assigns.correct_chars
      errors = socket.assigns.error_chars
      total = correct + errors
      accuracy = if total > 0, do: round(correct / total * 100), else: 100
      wpm = round(correct / 5 / (@duration / 60))

      {:noreply,
       socket
       |> assign(time_left: 0)
       |> assign(status: :finished)
       |> assign(wpm: wpm)
       |> assign(accuracy: accuracy)}
    else
      Process.send_after(self(), :tick, 1000)
      elapsed = @duration - time_left
      wpm = if elapsed > 0, do: round(socket.assigns.correct_chars / 5 / (elapsed / 60)), else: 0

      {:noreply,
       socket
       |> assign(time_left: time_left)
       |> assign(wpm: wpm)}
    end
  end

  def handle_info(:tick, socket), do: {:noreply, socket}

  defp assign_fresh_game(socket) do
    socket
    |> assign(target_text: generate_text())
    |> assign(typed_text: "")
    |> assign(status: :idle)
    |> assign(time_left: @duration)
    |> assign(wpm: 0)
    |> assign(accuracy: 100)
    |> assign(correct_chars: 0)
    |> assign(error_chars: 0)
  end

  defp generate_text do
    @words
    |> Enum.shuffle()
    |> Stream.cycle()
    |> Enum.take(@total_words)
    |> Enum.join(" ")
  end

  defp char_class(nil, _target), do: "text-gray-300"
  defp char_class(t, g) when t == g, do: "text-green-600 bg-green-50 rounded-sm"
  defp char_class(_t, _g), do: "text-red-500 bg-red-100 rounded-sm"

  defp get_char(text, idx) do
    case String.at(text, idx) do
      nil -> nil
      c -> c
    end
  end

  defp cursor_here?(typed_text, idx),
    do: String.length(typed_text) == idx

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-3xl mx-auto space-y-6">
        <.link
          navigate={~p"/"}
          class="inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Dashboard
        </.link>

        <div class="flex items-center justify-between">
          <h1 class="text-2xl font-semibold text-gray-900">Typing Game</h1>
          <button
            phx-click="reset"
            class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors"
          >
            <.icon name="hero-arrow-path" class="size-4" /> New Text
          </button>
        </div>

        <div class="grid grid-cols-3 gap-4">
          <div class={[
            "bg-white rounded-2xl border p-4 text-center transition-colors",
            if(@status == :running, do: "border-green-200 bg-green-50", else: "border-gray-200")
          ]}>
            <p class={[
              "text-3xl font-bold tabular-nums",
              if(@time_left <= 10 and @status == :running, do: "text-red-500", else: "text-gray-900")
            ]}>
              {@time_left}
            </p>
            <p class="text-xs text-gray-500 mt-1">Seconds Left</p>
          </div>

          <div class="bg-white rounded-2xl border border-gray-200 p-4 text-center">
            <p class="text-3xl font-bold text-gray-900 tabular-nums">{@wpm}</p>
            <p class="text-xs text-gray-500 mt-1">WPM</p>
          </div>

          <div class="bg-white rounded-2xl border border-gray-200 p-4 text-center">
            <p class="text-3xl font-bold text-gray-900 tabular-nums">
              {@correct_chars + @error_chars}
            </p>
            <p class="text-xs text-gray-500 mt-1">Characters</p>
          </div>
        </div>

        <%= if @status == :finished do %>
          <div class="bg-white rounded-2xl border border-gray-200 p-8 text-center space-y-5">
            <div class="text-5xl">🏁</div>
            <h2 class="text-xl font-semibold text-gray-900">Time's Up!</h2>

            <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 max-w-lg mx-auto">
              <div class="bg-green-50 rounded-xl p-4">
                <p class="text-2xl font-bold text-green-700">{@wpm}</p>
                <p class="text-xs text-gray-500 mt-1">WPM</p>
              </div>
              <div class="bg-blue-50 rounded-xl p-4">
                <p class="text-2xl font-bold text-blue-700">{@accuracy}%</p>
                <p class="text-xs text-gray-500 mt-1">Accuracy</p>
              </div>
              <div class="bg-gray-50 rounded-xl p-4">
                <p class="text-2xl font-bold text-gray-700">{@correct_chars}</p>
                <p class="text-xs text-gray-500 mt-1">Correct</p>
              </div>
              <div class="bg-red-50 rounded-xl p-4">
                <p class="text-2xl font-bold text-red-600">{@error_chars}</p>
                <p class="text-xs text-gray-500 mt-1">Errors</p>
              </div>
            </div>

            <button
              phx-click="reset"
              class="px-6 py-3 rounded-xl text-sm font-medium text-white bg-primary hover:bg-primary/90 transition-colors"
            >
              Play Again
            </button>
          </div>
        <% else %>
          <div class="bg-white rounded-2xl border border-gray-200 p-6">
            <%= if @status == :idle do %>
              <p class="text-xs text-center text-gray-400 mb-4">
                Click inside the text area below and start typing to begin
              </p>
            <% end %>

            <div class="relative rounded-xl bg-gray-50 p-5 cursor-text" id="text-display">
              <p class="font-mono text-base leading-relaxed tracking-wide select-none break-all">
                <%= for {char, idx} <- Enum.with_index(String.graphemes(@target_text)) do %>
                  <span class={[
                    char_class(get_char(@typed_text, idx), char),
                    "relative"
                  ]}>
                    <%= if cursor_here?(@typed_text, idx) do %>
                      <span class="absolute left-0 top-0 bottom-0 w-0.5 bg-gray-800 animate-pulse">
                      </span>
                    <% end %>
                    {if char == " ", do: "\u00A0", else: char}
                  </span>
                <% end %>
                <%= if cursor_here?(@typed_text, String.length(@target_text)) do %>
                  <span class="inline-block w-0.5 h-5 bg-gray-800 animate-pulse align-text-bottom">
                  </span>
                <% end %>
              </p>

              <textarea
                id="typing-area"
                phx-hook=".TypingArea"
                phx-update="ignore"
                disabled={@status == :finished}
                class="absolute inset-0 opacity-0 resize-none cursor-text w-full h-full p-0 m-0 border-0 outline-none"
              ></textarea>
            </div>

            <script :type={Phoenix.LiveView.ColocatedHook} name=".TypingArea">
              export default {
                mounted() {
                  this.el.focus()
                  this.el.addEventListener("input", e => {
                    if (!this.el.disabled) {
                      this.pushEvent("typing", { typed: e.target.value })
                    }
                  })
                  this.el.addEventListener("paste", e => e.preventDefault())
                  this.handleEvent("clear-input", () => {
                    this.el.value = ""
                    this.el.focus()
                  })
                  document.getElementById("text-display").addEventListener("click", () => {
                    this.el.focus()
                  })
                }
              }
            </script>

            <div class="mt-3 flex justify-between items-center text-xs text-gray-400">
              <span>{String.length(@typed_text)} / {String.length(@target_text)} characters</span>
              <span class="text-green-600">{@correct_chars} correct</span>
              <span class="text-red-500">{@error_chars} errors</span>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
