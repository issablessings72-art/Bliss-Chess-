package com.blisschess.app

enum class PieceType { EMPTY, PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }
enum class PieceColor { WHITE, BLACK }

data class ChessPiece(
    val type: PieceType = PieceType.EMPTY,
    val color: PieceColor = PieceColor.WHITE,
    val hasMoved: Boolean = false
) {
    val isEmpty: Boolean get() = type == PieceType.EMPTY

    fun symbol(): String {
        if (isEmpty) return ""
        val letter = when (type) {
            PieceType.PAWN -> "P"
            PieceType.KNIGHT -> "N"
            PieceType.BISHOP -> "B"
            PieceType.ROOK -> "R"
            PieceType.QUEEN -> "Q"
            PieceType.KING -> "K"
            else -> ""
        }
        return letter
    }

    // Unicode glyph for rendering
    fun glyph(): String {
        if (isEmpty) return ""
        val white = color == PieceColor.WHITE
        return when (type) {
            PieceType.PAWN -> if (white) "\u2659" else "\u265F"
            PieceType.KNIGHT -> if (white) "\u2658" else "\u265E"
            PieceType.BISHOP -> if (white) "\u2657" else "\u265D"
            PieceType.ROOK -> if (white) "\u2656" else "\u265C"
            PieceType.QUEEN -> if (white) "\u2655" else "\u265B"
            PieceType.KING -> if (white) "\u2654" else "\u265A"
            else -> ""
        }
    }
}

data class Pos(val row: Int, val col: Int)

enum class GameStatus { ONGOING, CHECK, CHECKMATE, STALEMATE }

/**
 * Kotlin port of the original C++ ChessBoard class: same board representation,
 * move legality rules, check / checkmate detection and turn management.
 */
class ChessBoard {
    // board[row][col], row 0 = rank 1 (white side), row 7 = rank 8
    private val board: Array<Array<ChessPiece>> = Array(8) { Array(8) { ChessPiece() } }
    var currentTurn: PieceColor = PieceColor.WHITE
        private set

    var lastMessage: String = ""
        private set

    init {
        initBoard()
    }

    fun pieceAt(row: Int, col: Int): ChessPiece = board[row][col]

    private fun initBoard() {
        for (r in 0 until 8) for (c in 0 until 8) board[r][c] = ChessPiece()

        for (col in 0 until 8) {
            board[1][col] = ChessPiece(PieceType.PAWN, PieceColor.WHITE)
            board[6][col] = ChessPiece(PieceType.PAWN, PieceColor.BLACK)
        }

        val backRank = listOf(
            PieceType.ROOK, PieceType.KNIGHT, PieceType.BISHOP, PieceType.QUEEN,
            PieceType.KING, PieceType.BISHOP, PieceType.KNIGHT,
