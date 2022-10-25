%lang starknet
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

const HEIGHT = 8;
const WIDTH = 8;

const EMPTY = 0;
const SHIP = 1;
const SHIP_HITTED = 2;
const VISITED = 3;

struct Game{
    player1: felt,
    player2: felt,
    board1: felt,
    board2: felt,
    life1: felt,
    life2: felt,
    turn: felt,
    winner: felt,
}

@storage_var
func games_count() -> (res : felt) {
}

@storage_var
func boards_count() -> (res : felt) {
}

@storage_var
func boards(id_board: felt, id_grid: felt) -> (status: felt) {
}

@storage_var
func games(id_game: felt) -> (game: Game) {
}

@external
func create_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player1: felt, player2: felt, board1: felt, board2: felt) {
    let (id_game) = games_count.read();
    games.write(id_game, Game(player1, player2, board1, board2, 16, 16, player1, 0));
    games_count.write(id_game + 1);
    return ();
}

@external
func create_board{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ships_len: felt, ships: felt*) {
    alloc_locals;
    let (id_board) = boards_count.read();
    _create_board(id_board, ships_len, ships);
    boards_count.write(id_board + 1);
    return ();
}

@external
func attack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    id_game: felt, id_grid: felt) {
    alloc_locals;
    
    let (game) = games.read(id_game);
    let (player_id) = get_caller_address();

    with_attr error_message("Not your turn or you are not in the game") {
        assert game.turn = player_id;
    }

    if (game.turn == game.player1) {
        let (status) = boards.read(game.board2, id_grid);
        with_attr error_message("You already attacked this cell") {
            assert status = VISITED;
        }
        if (status == SHIP) {
            boards.write(game.board2, id_grid, SHIP_HITTED);
            game.life2 = game.life2 - 1;
        } else {
            boards.write(game.board2, id_grid, VISITED);
        }
        game.turn = game.player2;
    } else {
        let (status) = boards.read(game.board1, id_grid);
        with_attr error_message("You already attacked this cell") {
            assert status = VISITED;
        }
        if (status == SHIP) {
            boards.write(game.board1, id_grid, SHIP_HITTED);
            game.life1 = game.life1 - 1;
        } else {
            boards.write(game.board1, id_grid, VISITED);
        }
        game.turn = game.player1;
    }

    if (game.life1 == 0) {
        game.winner = game.player2;
    } else {
        if (game.life2 == 0) {
            game.winner = game.player1;
        }
    }
    
    games.write(id_game, Game(game.player1, game.player2, game.board1, game.board2, game.life1, game.life2, game.turn, game.winner));
    return ();
    
    // let board_enemy_id = get_enemy_board(game, player_id);
    // let (status) = boards.read(board_enemy_id, id_grid);
    // if (status == EMPTY) {
    //     boards.write(board_enemy_id, id_grid, VISITED);
    //     return ();
    // } else {
    //     if (status == SHIP) {
    //         boards.write(board_enemy_id, id_grid, SHIP_HITTED);
    //         return ();
    //     } else {
    //         return ();
    //     }
    // }
}

func get_player_attributes(game: Game, player_id: felt) -> (felt, felt, felt) {
    if (game.player1 == player_id) {
        return (game.player1, game.board1, game.life1);
    } else {
        return (game.player2, game.board2, game.life2);
    }
}

func _create_board{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(id_board: felt, ships_len: felt, ships: felt*) {
    if(ships_len == 0) {
        return ();
    }
    boards.write(id_board, [ships], SHIP);
    return _create_board(id_board, ships_len - 1, ships + 1);
}