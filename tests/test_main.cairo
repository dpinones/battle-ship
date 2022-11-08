%lang starknet
from src.main import Game, create_game, create_board, attack, get_game
from starkware.cairo.common.cairo_builtins import HashBuiltin
from tests.helpers.constants import PLAYER1, PLAYER2


@external
func test_attack{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;
    tempvar ships_player1: felt* = cast(new(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15),  felt*);
    let (board_player1) = create_board(16, ships_player1);

    tempvar ships_player2: felt* = cast(new(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15),  felt*);
    let (board_player2) = create_board(16, ships_player2);

    let (id_game) = create_game(PLAYER1, PLAYER2, board_player1, board_player2);

    let (game) = get_game(id_game);

    // magic
    %{ end_prank = start_prank(ids.PLAYER1) %}
    attack(id_game, 1);
    %{ end_prank() %}

    %{ end_prank = start_prank(ids.PLAYER2) %}
    attack(id_game, 32);
    %{ end_prank() %}

    return ();
}