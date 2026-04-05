defmodule PersonalHub.Chess.GameServer do
  use GenServer

  alias PersonalHub.Chess

  defstruct [
    :game_id,
    :board,
    :turn,
    :white_player,
    :black_player,
    :status,
    :winner,
    moves: []
  ]

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via(game_id))
  end

  def join(game_id, player_id, player_name) do
    GenServer.call(via(game_id), {:join, player_id, player_name})
  end

  def move(game_id, player_id, from, to) do
    GenServer.call(via(game_id), {:move, player_id, from, to})
  end

  def get_state(game_id) do
    GenServer.call(via(game_id), :get_state)
  end

  def game_exists?(game_id) do
    case Registry.lookup(PersonalHub.Chess.Registry, game_id) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  def create_game(game_id) do
    DynamicSupervisor.start_child(
      PersonalHub.Chess.GameSupervisor,
      {__MODULE__, game_id}
    )
  end

  @impl true
  def init(game_id) do
    state = %__MODULE__{
      game_id: game_id,
      board: Chess.new_board(),
      turn: :white,
      status: :waiting
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:join, player_id, player_name}, _from, state) do
    cond do
      state.white_player == nil ->
        new_state = %{state | white_player: {player_id, player_name}}
        broadcast(state.game_id, {:player_joined, :white, player_name})
        {:reply, {:ok, :white}, new_state}

      state.black_player == nil and state.white_player |> elem(0) != player_id ->
        new_state = %{state | black_player: {player_id, player_name}, status: :playing}
        broadcast(state.game_id, {:player_joined, :black, player_name})
        broadcast(state.game_id, {:game_started, serialize(new_state)})
        {:reply, {:ok, :black}, new_state}

      state.white_player |> elem(0) == player_id ->
        {:reply, {:ok, :white}, state}

      state.black_player != nil and state.black_player |> elem(0) == player_id ->
        {:reply, {:ok, :black}, state}

      true ->
        {:reply, {:error, :game_full}, state}
    end
  end

  @impl true
  def handle_call({:move, player_id, from, to}, _from, state) do
    player_color = player_color(state, player_id)

    cond do
      state.status != :playing ->
        {:reply, {:error, :game_not_active}, state}

      player_color != state.turn ->
        {:reply, {:error, :not_your_turn}, state}

      true ->
        case Map.get(state.board, from) do
          {^player_color, _type} ->
            if to in Chess.valid_moves(state.board, from) do
              notation = Chess.move_notation(state.board, from, to)
              new_board = Chess.apply_move(state.board, from, to)
              next_turn = Chess.opposite(state.turn)
              game_status = Chess.game_status(new_board, next_turn)

              {new_status, winner} =
                case game_status do
                  {:checkmate, color} -> {:finished, color}
                  :stalemate -> {:finished, nil}
                  _ -> {:playing, nil}
                end

              new_state = %{state |
                board: new_board,
                turn: next_turn,
                status: new_status,
                winner: winner,
                moves: state.moves ++ [notation]
              }

              broadcast(state.game_id, {:move_made, serialize(new_state)})
              {:reply, {:ok, serialize(new_state)}, new_state}
            else
              {:reply, {:error, :invalid_move}, state}
            end

          _ ->
            {:reply, {:error, :not_your_piece}, state}
        end
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, serialize(state), state}
  end

  defp player_color(%{white_player: {id, _}}, id), do: :white
  defp player_color(%{black_player: {id, _}}, id), do: :black
  defp player_color(_, _), do: nil

  defp broadcast(game_id, message) do
    Phoenix.PubSub.broadcast(PersonalHub.PubSub, "chess:#{game_id}", message)
  end

  defp serialize(state) do
    %{
      game_id: state.game_id,
      board: state.board,
      turn: state.turn,
      white_player: state.white_player,
      black_player: state.black_player,
      status: state.status,
      winner: state.winner,
      moves: state.moves
    }
  end

  defp via(game_id) do
    {:via, Registry, {PersonalHub.Chess.Registry, game_id}}
  end
end
