%lang starknet
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc

from src.constants.ship_status import EMPTY, SHIP, SHIP_HITTED, VISITED
from src.models.game import Game

//
// Storage
//

@storage_var
func games_count() -> (res : felt) {
}

@storage_var
func games(id_game: felt) -> (game: Game) {
}

@storage_var
func boards_count() -> (res : felt) {
}

@storage_var
func boards(id_board: felt, id_grid: felt) -> (status: felt) {
}

//
// Getters
//

@view
func get_games_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = games_count.read();
    return (res,);
}

@view
func get_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(id_game: felt) -> (game: Game) {
    let (game: Game) = games.read(id_game);
    // %{
    //     from requests import post
    //     json = { # armo el json que luego se va a imprimir en el script de python
    //         "player1": f"{ids.game.player1}",
    //         "player2": f"{ids.game.player2}",
    //         "board1": f"{ids.game.board1}",
    //         "board2": f"{ids.game.board2}",
    //         "life1": f"{ids.game.life1}",
    //         "life2": f"{ids.game.life2}",
    //         "turn": f"{ids.game.turn}",
    //         "winner": f"{ids.game.winner}",
    //     }
    //     post(url="http://localhost:5000", json=json) # envio la petición a nuestro pequeño "servidor"
    // %}

    return (game,);
}

@view
func get_boards_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = boards_count.read();
    return (res,);
}

@view
func get_board{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(id_board: felt, id_grid: felt) -> (status: felt) {
    let (status) = boards.read(id_board, id_grid);
    return (status,);
}

//
// Externals
//

@external
func create_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player1: felt, player2: felt, board1: felt, board2: felt) -> (id_game: felt) {
    let (id_game) = games_count.read();
    games.write(id_game, Game(player1, player2, board1, board2, 16, 16, player1, 0));
    games_count.write(id_game + 1);
    return (id_game,);
}

func get_player_attributes(game: Game, player_id: felt) -> (felt, felt, felt) {
    if (game.player1 == player_id) {
        return (game.player1, game.board1, game.life1);
    } else {
        return (game.player2, game.board2, game.life2);
    }
}

@external
func create_board{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ships_len: felt, ships: felt*) -> (id_board: felt) {
    alloc_locals;
    let (id_board) = boards_count.read();
    _create_board(id_board, ships_len, ships);
    boards_count.write(id_board + 1);
    return (id_board,);
}

@external
func attack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    id_game: felt, id_grid: felt) {
    alloc_locals;
    
    let (game: Game) = games.read(id_game);
    let (player_id) = get_caller_address();

    // %{
    //     from requests import post
    //     json = { # armo el json que luego se va a imprimir en el script de python
    //         "attack": f"{ids.player_id}",
    //     }
    //     post(url="http://localhost:5000", json=json) # envio la petición a nuestro pequeño "servidor"
    // %}


    with_attr error_message("Not your turn or you are not in the game") {
        assert game.turn = player_id;
    }

    local turn;
    local life1;
    local life2;
    local winner;
    if (game.turn == game.player1) {
        let (status) = boards.read(game.board2, id_grid);
        // with_attr error_message("You already attacked this cell") {
        //     assert status = VISITED;
        // }
        if (status == SHIP) {
            boards.write(game.board2, id_grid, SHIP_HITTED);
            life2 = game.life2 - 1;
        } else {
            life2 = game.life2;
            boards.write(game.board2, id_grid, VISITED);
        }
        life1 = game.life1;
        turn = game.player2;
    } else {
        let (status) = boards.read(game.board1, id_grid);
        // with_attr error_message("You already attacked this cell") {
        //     assert status = VISITED;
        // }
        if (status == SHIP) {
            boards.write(game.board1, id_grid, SHIP_HITTED);
            life1 = game.life1 - 1;
        } else {
            life1 = game.life1;
            boards.write(game.board1, id_grid, VISITED);
        }
        life2 = game.life2;
        turn = game.player1;
    }

    if (life1 == 0) {
        winner = game.player2;
    } else {
        if (life2 == 0) {
            winner = game.player1;
        } else {
            winner = 0;
        }
    }
    
    games.write(id_game, Game(game.player1, game.player2, game.board1, game.board2, life1, life2, turn, winner));

    let (game: Game) = games.read(id_game);
    // %{
    //     from requests import post
    //     json = { # armo el json que luego se va a imprimir en el script de python
    //         "player1": f"{ids.game.player1}",
    //         "player2": f"{ids.game.player2}",
    //         "board1": f"{ids.game.board1}",
    //         "board2": f"{ids.game.board2}",
    //         "life1": f"{ids.game.life1}",
    //         "life2": f"{ids.game.life2}",
    //         "turn": f"{ids.game.turn}",
    //         "winner": f"{ids.game.winner}",
    //     }
    //     post(url="http://localhost:5000", json=json) # envio la petición a nuestro pequeño "servidor"
    // %}

    return ();
}

//
// Internals
//

func _create_board{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(id_board: felt, ships_len: felt, ships: felt*) {
    if(ships_len == 0) {
        return ();
    }
    boards.write(id_board, [ships], SHIP);
    return _create_board(id_board, ships_len - 1, ships + 1);
}