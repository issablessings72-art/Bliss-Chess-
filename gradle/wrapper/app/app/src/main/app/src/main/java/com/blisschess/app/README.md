# Bliss Chess (Android)

A native Android chess app, ported from the original C++ console game into
Kotlin + Jetpack Compose. Same board representation, move-legality rules,
check/checkmate detection, and turn management — now with a tappable 8x8
board UI instead of console I/O.

## How to play

- Tap a piece to select it — legal destination squares are highlighted.
- Tap a highlighted square to move there.
- Tap a different one of your own pieces to change selection.
- Pawn reaching the last rank prompts a promotion choice (Queen/Rook/Bishop/Knight).
- Status line shows whose turn it is, check, checkmate, or stalemate.
- "New Game" resets the board.

## Notes on the port

- `ChessBoard.kt` mirrors the C++ class method-for-method: `isValidPosition`,
  `isPathClear`, `isLegalMoveWithoutKingCheck`, `isKingInCheck`, `makeMove`,
  and checkmate detection via the same "simulate every move, see if king is
  still in check" approach.
- Not implemented (same as the original C++ source): castling, en passant,
  and the fifty-move/threefold-repetition draw rules. Stalemate detection
  was added since it falls out naturally from the "no legal moves" check.
