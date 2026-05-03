defmodule PersonalHub.Chess do
  @type color :: :white | :black
  @type piece_type :: :king | :queen | :rook | :bishop | :knight | :pawn
  @type piece :: {color(), piece_type()}
  @type position :: {non_neg_integer(), non_neg_integer()}
  @type board :: %{position() => piece()}
  @type game_result :: {:checkmate, color()} | :stalemate | :check | :playing

  @initial_rank [:rook, :knight, :bishop, :queen, :king, :bishop, :knight, :rook]

  @piece_symbols %{
    {:white, :king} => "♔",
    {:white, :queen} => "♕",
    {:white, :rook} => "♖",
    {:white, :bishop} => "♗",
    {:white, :knight} => "♘",
    {:white, :pawn} => "♙",
    {:black, :king} => "♚",
    {:black, :queen} => "♛",
    {:black, :rook} => "♜",
    {:black, :bishop} => "♝",
    {:black, :knight} => "♞",
    {:black, :pawn} => "♟"
  }

  @spec new_board() :: board()
  def new_board do
    white_rank =
      for {piece, col} <- Enum.with_index(@initial_rank),
          into: %{},
          do: {{0, col}, {:white, piece}}

    white_pawns = for col <- 0..7, into: %{}, do: {{1, col}, {:white, :pawn}}
    black_pawns = for col <- 0..7, into: %{}, do: {{6, col}, {:black, :pawn}}

    black_rank =
      for {piece, col} <- Enum.with_index(@initial_rank),
          into: %{},
          do: {{7, col}, {:black, piece}}

    white_rank |> Map.merge(white_pawns) |> Map.merge(black_pawns) |> Map.merge(black_rank)
  end

  @spec piece_symbol(piece() | nil) :: String.t()
  def piece_symbol(nil), do: ""
  def piece_symbol(piece), do: Map.fetch!(@piece_symbols, piece)

  @spec on_board?(position()) :: boolean()
  def on_board?({row, col}), do: row in 0..7 and col in 0..7

  @spec opposite(color()) :: color()
  def opposite(:white), do: :black
  def opposite(:black), do: :white

  @spec apply_move(board(), position(), position()) :: board()
  def apply_move(board, from, to) do
    piece = Map.fetch!(board, from)

    board
    |> Map.delete(from)
    |> Map.put(to, promote(piece, to))
  end

  defp promote({:white, :pawn}, {7, _}), do: {:white, :queen}
  defp promote({:black, :pawn}, {0, _}), do: {:black, :queen}
  defp promote(piece, _), do: piece

  @spec find_king(board(), color()) :: position() | nil
  def find_king(board, color) do
    Enum.find_value(board, fn
      {pos, {^color, :king}} -> pos
      _ -> nil
    end)
  end

  @spec in_check?(board(), color()) :: boolean()
  def in_check?(board, color) do
    king_pos = find_king(board, color)
    opponent = opposite(color)

    Enum.any?(board, fn
      {pos, {^opponent, type}} -> king_pos in attack_squares(board, pos, opponent, type)
      _ -> false
    end)
  end

  @spec valid_moves(board(), position()) :: [position()]
  def valid_moves(board, pos) do
    case Map.get(board, pos) do
      nil ->
        []

      {color, :pawn} ->
        pawn_moves(board, pos, color)
        |> Enum.reject(fn to -> in_check?(apply_move(board, pos, to), color) end)

      {color, type} ->
        attack_squares(board, pos, color, type)
        |> Enum.reject(fn to -> match?({^color, _}, Map.get(board, to)) end)
        |> Enum.reject(fn to -> in_check?(apply_move(board, pos, to), color) end)
    end
  end

  @spec checkmate?(board(), color()) :: boolean()
  def checkmate?(board, color), do: in_check?(board, color) and no_legal_moves?(board, color)

  @spec stalemate?(board(), color()) :: boolean()
  def stalemate?(board, color), do: not in_check?(board, color) and no_legal_moves?(board, color)

  @spec game_status(board(), color()) :: game_result()
  def game_status(board, turn) do
    cond do
      checkmate?(board, turn) -> {:checkmate, opposite(turn)}
      stalemate?(board, turn) -> :stalemate
      in_check?(board, turn) -> :check
      true -> :playing
    end
  end

  @spec col_label(non_neg_integer()) :: String.t()
  def col_label(col), do: Enum.at(~w(a b c d e f g h), col)

  @spec move_notation(board(), position(), position()) :: String.t()
  def move_notation(board, from, to) do
    {_color, type} = Map.fetch!(board, from)
    capture? = Map.get(board, to) != nil
    {to_r, to_c} = to
    piece_letter = piece_letter(type)
    capture_str = if capture?, do: "x", else: ""
    "#{piece_letter}#{capture_str}#{col_label(to_c)}#{to_r + 1}"
  end

  defp piece_letter(:pawn), do: ""
  defp piece_letter(:knight), do: "N"
  defp piece_letter(:bishop), do: "B"
  defp piece_letter(:rook), do: "R"
  defp piece_letter(:queen), do: "Q"
  defp piece_letter(:king), do: "K"

  defp no_legal_moves?(board, color) do
    board
    |> Enum.filter(fn {_pos, {c, _}} -> c == color end)
    |> Enum.all?(fn {pos, _} -> valid_moves(board, pos) == [] end)
  end

  defp pawn_moves(board, {row, col}, :white) do
    forward = {row + 1, col}
    double = {row + 2, col}
    captures = [{row + 1, col - 1}, {row + 1, col + 1}]

    forward_moves =
      cond do
        not on_board?(forward) or Map.get(board, forward) != nil ->
          []

        row == 1 and Map.get(board, double) == nil ->
          [forward, double]

        true ->
          [forward]
      end

    capture_moves =
      Enum.filter(captures, fn to ->
        on_board?(to) and match?({:black, _}, Map.get(board, to))
      end)

    forward_moves ++ capture_moves
  end

  defp pawn_moves(board, {row, col}, :black) do
    forward = {row - 1, col}
    double = {row - 2, col}
    captures = [{row - 1, col - 1}, {row - 1, col + 1}]

    forward_moves =
      cond do
        not on_board?(forward) or Map.get(board, forward) != nil ->
          []

        row == 6 and Map.get(board, double) == nil ->
          [forward, double]

        true ->
          [forward]
      end

    capture_moves =
      Enum.filter(captures, fn to ->
        on_board?(to) and match?({:white, _}, Map.get(board, to))
      end)

    forward_moves ++ capture_moves
  end

  defp attack_squares(_board, {row, col}, :white, :pawn) do
    [{row + 1, col - 1}, {row + 1, col + 1}] |> Enum.filter(&on_board?/1)
  end

  defp attack_squares(_board, {row, col}, :black, :pawn) do
    [{row - 1, col - 1}, {row - 1, col + 1}] |> Enum.filter(&on_board?/1)
  end

  defp attack_squares(board, pos, _color, :rook) do
    sliding(board, pos, [{0, 1}, {0, -1}, {1, 0}, {-1, 0}])
  end

  defp attack_squares(board, pos, _color, :bishop) do
    sliding(board, pos, [{1, 1}, {1, -1}, {-1, 1}, {-1, -1}])
  end

  defp attack_squares(board, pos, _color, :queen) do
    sliding(board, pos, [{0, 1}, {0, -1}, {1, 0}, {-1, 0}, {1, 1}, {1, -1}, {-1, 1}, {-1, -1}])
  end

  defp attack_squares(_board, {row, col}, _color, :knight) do
    [
      {row + 2, col + 1},
      {row + 2, col - 1},
      {row - 2, col + 1},
      {row - 2, col - 1},
      {row + 1, col + 2},
      {row + 1, col - 2},
      {row - 1, col + 2},
      {row - 1, col - 2}
    ]
    |> Enum.filter(&on_board?/1)
  end

  defp attack_squares(_board, {row, col}, _color, :king) do
    for dr <- -1..1, dc <- -1..1, {dr, dc} != {0, 0}, on_board?({row + dr, col + dc}) do
      {row + dr, col + dc}
    end
  end

  defp sliding(board, {row, col}, directions) do
    Enum.flat_map(directions, fn {dr, dc} ->
      walk(board, {row + dr, col + dc}, {dr, dc}, [])
    end)
  end

  defp walk(board, pos, {dr, dc}, acc) do
    cond do
      not on_board?(pos) -> acc
      Map.get(board, pos) != nil -> [pos | acc]
      true -> walk(board, {elem(pos, 0) + dr, elem(pos, 1) + dc}, {dr, dc}, [pos | acc])
    end
  end
end
