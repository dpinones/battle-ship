%lang starknet

from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc

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

