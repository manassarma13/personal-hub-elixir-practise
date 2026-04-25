defmodule PersonalHubWeb.ChessLive.Index do
  use PersonalHubWeb, :live_view

  alias PersonalHub.Chess
  alias PersonalHub.Chess.GameServer

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Chess")
     |> assign(screen: :lobby)
     |> assign(player_name: "")
     |> assign(player_id: nil)
     |> assign(player_color: nil)
     |> assign(game_id: nil)
     |> assign(game: nil)
     |> assign(selected: nil)
     |> assign(valid_moves: [])
     |> assign(join_code: "")
     |> assign(chat_input: "")
     |> stream(:chat_messages, [])}
  end

  @impl true
  def handle_event("set_name", %{"name" => name}, socket) do
    name = String.trim(name)

    if name == "" do
      {:noreply, socket}
    else
      player_id = Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)

      {:noreply,
       socket
       |> assign(player_name: name)
       |> assign(player_id: player_id)
       |> assign(screen: :menu)}
    end
  end

  @impl true
  def handle_event("create_game", _params, socket) do
    game_id = generate_code()

    case GameServer.create_game(game_id) do
      {:ok, _pid} ->
        {:ok, color} =
          GameServer.join(game_id, socket.assigns.player_id, socket.assigns.player_name)

        Phoenix.PubSub.subscribe(PersonalHub.PubSub, "chess:#{game_id}")
        game = GameServer.get_state(game_id)

        {:noreply,
         socket
         |> assign(screen: :game)
         |> assign(game_id: game_id)
         |> assign(player_color: color)
         |> assign(game: game)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to create game")}
    end
  end

  @impl true
  def handle_event("update_join_code", %{"code" => code}, socket) do
    {:noreply, assign(socket, join_code: String.upcase(String.trim(code)))}
  end

  @impl true
  def handle_event("join_game", %{"code" => code}, socket) do
    code = String.upcase(String.trim(code))

    if GameServer.game_exists?(code) do
      case GameServer.join(code, socket.assigns.player_id, socket.assigns.player_name) do
        {:ok, color} ->
          Phoenix.PubSub.subscribe(PersonalHub.PubSub, "chess:#{code}")
          game = GameServer.get_state(code)

          {:noreply,
           socket
           |> assign(screen: :game)
           |> assign(game_id: code)
           |> assign(player_color: color)
           |> assign(game: game)}

        {:error, :game_full} ->
          {:noreply, put_flash(socket, :error, "Game is full")}
      end
    else
      {:noreply, put_flash(socket, :error, "Game not found")}
    end
  end

  @impl true
  def handle_event("select_square", %{"row" => row, "col" => col}, socket) do
    row = String.to_integer(row)
    col = String.to_integer(col)
    pos = {row, col}
    game = socket.assigns.game
    board = game.board

    cond do
      game.status != :playing ->
        {:noreply, socket}

      socket.assigns.player_color != game.turn ->
        {:noreply, socket}

      socket.assigns.selected != nil and pos in socket.assigns.valid_moves ->
        from = socket.assigns.selected

        case GameServer.move(socket.assigns.game_id, socket.assigns.player_id, from, pos) do
          {:ok, new_game} ->
            {:noreply,
             socket
             |> assign(game: new_game)
             |> assign(selected: nil)
             |> assign(valid_moves: [])}

          {:error, _reason} ->
            {:noreply, assign(socket, selected: nil, valid_moves: [])}
        end

      true ->
        case Map.get(board, pos) do
          {color, _} when color == socket.assigns.player_color ->
            moves = Chess.valid_moves(board, pos)
            {:noreply, assign(socket, selected: pos, valid_moves: moves)}

          _ ->
            {:noreply, assign(socket, selected: nil, valid_moves: [])}
        end
    end
  end

  @impl true
  def handle_event("send_chat", %{"message" => msg}, socket) do
    msg = String.trim(msg)

    if msg != "" and socket.assigns.game_id do
      Phoenix.PubSub.broadcast(
        PersonalHub.PubSub,
        "chess:#{socket.assigns.game_id}",
        {:chat_message, socket.assigns.player_name, msg}
      )
    end

    {:noreply, assign(socket, chat_input: "")}
  end

  @impl true
  def handle_event("update_chat_input", %{"message" => value}, socket) do
    {:noreply, assign(socket, chat_input: value)}
  end

  @impl true
  def handle_event("back_to_menu", _params, socket) do
    if socket.assigns.game_id do
      Phoenix.PubSub.unsubscribe(PersonalHub.PubSub, "chess:#{socket.assigns.game_id}")
    end

    {:noreply,
     socket
     |> assign(screen: :menu)
     |> assign(game_id: nil)
     |> assign(game: nil)
     |> assign(selected: nil)
     |> assign(valid_moves: [])
     |> assign(player_color: nil)
     |> stream(:chat_messages, [], reset: true)}
  end

  @impl true
  def handle_info({:game_started, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_info({:move_made, game}, socket) do
    {:noreply, assign(socket, game: game, selected: nil, valid_moves: [])}
  end

  @impl true
  def handle_info({:chat_message, from, text}, socket) do
    msg = %{id: System.unique_integer([:positive, :monotonic]), from: from, text: text}
    {:noreply, stream_insert(socket, :chat_messages, msg)}
  end

  @impl true
  def handle_info({:player_joined, _color, _name}, socket) do
    if socket.assigns.game_id do
      game = GameServer.get_state(socket.assigns.game_id)
      {:noreply, assign(socket, game: game)}
    else
      {:noreply, socket}
    end
  end

  defp generate_code do
    for _ <- 1..6, into: "", do: <<Enum.random(~c"ABCDEFGHJKLMNPQRSTUVWXYZ23456789")>>
  end

  defp square_color(row, col) do
    if rem(row + col, 2) == 0, do: "bg-[#f0d9b5]", else: "bg-[#b58863]"
  end

  defp piece_text_color({:white, _}),
    do: "text-white [text-shadow:0_1px_3px_rgba(0,0,0,0.8),0_0_8px_rgba(0,0,0,0.3)]"

  defp piece_text_color({:black, _}),
    do:
      "text-gray-950 [text-shadow:0_1px_2px_rgba(255,255,255,0.6),0_0_6px_rgba(255,255,255,0.3)]"

  defp piece_text_color(_), do: ""

  defp board_rows(:white), do: Enum.to_list(7..0//-1)
  defp board_rows(:black), do: Enum.to_list(0..7)
  defp board_rows(_), do: Enum.to_list(7..0//-1)

  defp status_text(%{status: :waiting}), do: "Waiting for opponent..."
  defp status_text(%{status: :finished, winner: nil}), do: "Stalemate!"

  defp status_text(%{status: :finished, winner: color}),
    do: "#{String.capitalize(to_string(color))} wins!"

  defp status_text(%{status: :playing, turn: turn, board: board}) do
    check_text = if Chess.in_check?(board, turn), do: " — Check!", else: ""
    "#{String.capitalize(to_string(turn))}'s turn#{check_text}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto space-y-6">
        <.link
          navigate={~p"/"}
          class="inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Dashboard
        </.link>

        <h1 class="text-2xl font-semibold text-gray-900">Chess</h1>

        <%= cond do %>
          <% @screen == :lobby -> %>
            <div class="max-w-md mx-auto">
              <div class="bg-white border border-gray-200 rounded-2xl p-8 text-center space-y-6">
                <div class="text-6xl">♟</div>
                <h2 class="text-xl font-semibold text-gray-900">Enter Your Name</h2>
                <p class="text-sm text-gray-500">
                  If your name matches a registered user, your account will be linked
                </p>
                <form phx-submit="set_name" class="space-y-4">
                  <input
                    type="text"
                    name="name"
                    placeholder="Your name..."
                    required
                    class="w-full px-4 py-3 bg-white border border-gray-300 rounded-xl text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  />
                  <button
                    type="submit"
                    class="w-full px-4 py-3 rounded-xl text-sm font-medium text-white bg-primary hover:bg-primary/90 transition-colors"
                  >
                    Continue
                  </button>
                </form>
              </div>
            </div>
          <% @screen == :menu -> %>
            <div class="max-w-md mx-auto space-y-4">
              <div class="bg-white border border-gray-200 rounded-2xl p-6 text-center">
                <p class="text-sm text-gray-500">Playing as</p>
                <p class="text-lg font-semibold text-gray-900">{@player_name}</p>
              </div>

              <div class="bg-white border border-gray-200 rounded-2xl p-6 space-y-4">
                <h3 class="text-lg font-semibold text-gray-900">Create New Game</h3>
                <p class="text-sm text-gray-500">
                  Start a game and share the code with your opponent
                </p>
                <button
                  phx-click="create_game"
                  class="w-full px-4 py-3 rounded-xl text-sm font-medium text-white bg-primary hover:bg-primary/90 transition-colors"
                >
                  Create Game
                </button>
              </div>

              <div class="bg-white border border-gray-200 rounded-2xl p-6 space-y-4">
                <h3 class="text-lg font-semibold text-gray-900">Join Game</h3>
                <p class="text-sm text-gray-500">Enter a game code to join your opponent</p>
                <form phx-submit="join_game" class="flex gap-2">
                  <input
                    type="text"
                    name="code"
                    value={@join_code}
                    phx-keyup="update_join_code"
                    phx-value-code=""
                    placeholder="Game code..."
                    required
                    maxlength="6"
                    class="flex-1 px-4 py-3 bg-white border border-gray-300 rounded-xl text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary uppercase tracking-widest text-center font-mono"
                  />
                  <button
                    type="submit"
                    class="px-6 py-3 rounded-xl text-sm font-medium text-white bg-primary hover:bg-primary/90 transition-colors"
                  >
                    Join
                  </button>
                </form>
              </div>
            </div>
          <% @screen == :game and @game != nil -> %>
            <div class="flex flex-col lg:flex-row gap-6 items-start">
              <div class="flex-1 w-full lg:w-auto">
                <div class="bg-white border border-gray-200 rounded-2xl p-4 sm:p-6">
                  <div class="flex justify-between items-center mb-4">
                    <div>
                      <span class="text-sm font-medium text-gray-500">Game</span>
                      <span class="ml-2 font-mono text-lg font-bold tracking-widest text-primary">
                        {@game_id}
                      </span>
                    </div>
                    <span class={[
                      "rounded-full px-3 py-1 text-xs font-medium",
                      if(@game.status == :playing,
                        do: "bg-green-50 text-green-700",
                        else: "bg-gray-100 text-gray-600"
                      )
                    ]}>
                      {status_text(@game)}
                    </span>
                  </div>

                  <div class="flex justify-center">
                    <div class="inline-block border-2 border-[#6d4c2a] rounded-lg overflow-hidden shadow-lg">
                      <%= for row <- board_rows(@player_color) do %>
                        <div class="flex">
                          <div class="w-5 sm:w-6 flex items-center justify-center text-xs text-gray-400 font-mono">
                            {row + 1}
                          </div>
                          <%= for col <- 0..7 do %>
                            <button
                              phx-click="select_square"
                              phx-value-row={row}
                              phx-value-col={col}
                              class={[
                                "w-10 h-10 sm:w-12 sm:h-12 md:w-14 md:h-14 flex items-center justify-center text-2xl sm:text-3xl md:text-4xl cursor-pointer transition-all duration-100 select-none",
                                square_color(row, col),
                                @selected == {row, col} &&
                                  "ring-2 ring-inset ring-blue-500 bg-blue-300/60",
                                {row, col} in @valid_moves &&
                                  "ring-2 ring-inset ring-emerald-400 bg-emerald-200/50",
                                piece_text_color(Map.get(@game.board, {row, col}))
                              ]}
                            >
                              {Chess.piece_symbol(Map.get(@game.board, {row, col}))}
                            </button>
                          <% end %>
                        </div>
                      <% end %>
                      <div class="flex">
                        <div class="w-5 sm:w-6"></div>
                        <%= for col <- 0..7 do %>
                          <div class="w-10 sm:w-12 md:w-14 text-center text-xs text-gray-400 font-mono pt-1">
                            {Chess.col_label(col)}
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </div>

                  <div class="mt-4 flex justify-between items-center text-sm">
                    <div class="flex items-center gap-2">
                      <span class="w-3 h-3 rounded-full bg-white border border-gray-300"></span>
                      <span class={[
                        "font-medium",
                        if(@game.turn == :white and @game.status == :playing,
                          do: "text-primary",
                          else: "text-gray-600"
                        )
                      ]}>
                        {player_display_name(@game.white_player, "Waiting...")}
                      </span>
                      <%= if @player_color == :white do %>
                        <span class="text-xs text-gray-400">(you)</span>
                      <% end %>
                    </div>
                    <div class="flex items-center gap-2">
                      <%= if @player_color == :black do %>
                        <span class="text-xs text-gray-400">(you)</span>
                      <% end %>
                      <span class={[
                        "font-medium",
                        if(@game.turn == :black and @game.status == :playing,
                          do: "text-primary",
                          else: "text-gray-600"
                        )
                      ]}>
                        {player_display_name(@game.black_player, "Waiting...")}
                      </span>
                      <span class="w-3 h-3 rounded-full bg-gray-800"></span>
                    </div>
                  </div>
                </div>

                <div class="mt-4 text-center">
                  <button
                    phx-click="back_to_menu"
                    class="text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors"
                  >
                    Leave Game
                  </button>
                </div>
              </div>

              <div class="w-full lg:w-72 flex flex-col gap-4">
                <div class="bg-white border border-gray-200 rounded-2xl p-4">
                  <h3 class="text-sm font-semibold text-gray-900 mb-3">Move History</h3>
                  <div class="space-y-1 max-h-48 overflow-y-auto">
                    <%= if @game.moves == [] do %>
                      <p class="text-xs text-gray-400">No moves yet</p>
                    <% else %>
                      <%= for {move, idx} <- Enum.with_index(@game.moves) do %>
                        <div class={[
                          "flex items-center gap-2 text-xs px-2 py-1 rounded",
                          if(rem(idx, 2) == 0, do: "bg-gray-50", else: "")
                        ]}>
                          <span class="text-gray-400 w-6">{div(idx, 2) + 1}.</span>
                          <span class="font-mono font-medium text-gray-700">{move}</span>
                        </div>
                      <% end %>
                    <% end %>
                  </div>
                </div>

                <div class="bg-white border border-gray-200 rounded-2xl p-4 flex flex-col">
                  <h3 class="text-sm font-semibold text-gray-900 mb-3">Chat</h3>
                  <div
                    id="chat-messages"
                    phx-update="stream"
                    class="flex-1 space-y-2 max-h-64 overflow-y-auto mb-3 min-h-[4rem]"
                  >
                    <div class="hidden only:flex items-center justify-center h-full">
                      <p class="text-xs text-gray-400">No messages yet</p>
                    </div>
                    <%= for {id, msg} <- @streams.chat_messages do %>
                      <div
                        id={id}
                        class={[
                          "text-xs rounded-xl px-3 py-2 max-w-full break-words",
                          if(msg.from == @player_name,
                            do: "bg-green-800 text-white ml-6",
                            else: "bg-gray-100 text-gray-800 mr-6"
                          )
                        ]}
                      >
                        <span class="font-medium block opacity-70 text-[10px] mb-0.5">
                          {msg.from}
                        </span>
                        {msg.text}
                      </div>
                    <% end %>
                  </div>
                  <form phx-submit="send_chat" class="flex gap-2">
                    <input
                      type="text"
                      name="message"
                      value={@chat_input}
                      phx-change="update_chat_input"
                      placeholder="Say something..."
                      autocomplete="off"
                      class="flex-1 px-3 py-2 text-xs bg-white border border-gray-200 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-green-700/20 focus:border-green-700"
                    />
                    <button
                      type="submit"
                      class="px-3 py-2 rounded-lg text-xs font-medium text-white bg-green-800 hover:bg-green-900 transition-colors"
                    >
                      Send
                    </button>
                  </form>
                </div>
              </div>
            </div>
          <% true -> %>
            <div class="text-center py-8 text-gray-400">Loading...</div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp player_display_name(nil, default), do: default
  defp player_display_name({_id, name}, _default), do: name
end
