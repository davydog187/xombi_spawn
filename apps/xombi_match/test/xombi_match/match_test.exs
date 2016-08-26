defmodule XombiMatch.MatchTest do
  use ExUnit.Case, async: true
  alias XombiMatch.Types.Move
  doctest XombiMatch.Match

  setup do
    {:ok, match} = XombiMatch.Match.start_link
    {:ok, match: match}
  end

  test "initializes the game with two players", %{match: match} do
    assert XombiMatch.Match.get_player_move(match, :player1) == %Move{x: 0, y: 0, z: 0}
    assert XombiMatch.Match.get_player_move(match, :player2) == %Move{x: 0, y: 0, z: 0}
  end

  test "players can be moved", %{match: match} do
    XombiMatch.Match.move_player(match, :player1, %Move{x: 1, y: 2, z: 3})
    assert XombiMatch.Match.get_player_move(match, :player1) == %Move{x: 1, y: 2, z: 3}
    assert XombiMatch.Match.get_player_move(match, :player2) == %Move{x: 0, y: 0, z: 0}
  end

end
