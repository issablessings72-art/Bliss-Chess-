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
            PieceType.KING, PieceType.BISHOP, PieceType.KNIGHT, PieceType.ROOK
        )
        for (row in listOf(0, 7)) {
            val color = if (row == 0) PieceColor.WHITE else PieceColor.BLACK
            for (col in 0 until 8) {
                board[row][col] = ChessPiece(backRank[col], color)
            }
        }
        currentTurn = PieceColor.WHITE
    }

    private fun isValidPosition(row: Int, col: Int) = row in 0..7 && col in 0..7

    private fun isPathClear(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int): Boolean {
        val rowStep = (toRow - fromRow).let { if (it > 0) 1 else if (it < 0) -1 else 0 }
        val colStep = (toCol - fromCol).let { if (it > 0) 1 else if (it < 0) -1 else 0 }
        var row = fromRow + rowStep
        var col = fromCol + colStep
        while (row != toRow || col != toCol) {
            if (!board[row][col].isEmpty) return false
            row += rowStep
            col += colStep
        }
        return true
    }

    private fun isLegalMoveWithoutKingCheck(
        fromRow: Int, fromCol: Int, toRow: Int, toCol: Int, color: PieceColor
    ): Boolean {
        if (!isValidPosition(fromRow, fromCol) || !isValidPosition(toRow, toCol)) return false
        val piece = board[fromRow][fromCol]
        if (piece.isEmpty || piece.color != color) return false
        val target = board[toRow][toCol]
        if (!target.isEmpty && target.color == color) return false

        val dr = toRow - fromRow
        val dc = toCol - fromCol
        val adr = Math.abs(dr)
        val adc = Math.abs(dc)

        return when (piece.type) {
            PieceType.PAWN -> {
                val dir = if (color == PieceColor.WHITE) 1 else -1
                when {
                    dr == dir && dc == 0 && target.isEmpty -> true
                    dr == 2 * dir && dc == 0 && !piece.hasMoved &&
                        board[fromRow + dir][fromCol].isEmpty && target.isEmpty -> true
                    dr == dir && adc == 1 && !target.isEmpty -> true
                    else -> false
                }
            }
            PieceType.KNIGHT -> (adr == 2 && adc == 1) || (adr == 1 && adc == 2)
            PieceType.BISHOP -> adr == adc && isPathClear(fromRow, fromCol, toRow, toCol)
            PieceType.ROOK -> (adr == 0 || adc == 0) && isPathClear(fromRow, fromCol, toRow, toCol)
            PieceType.QUEEN -> (adr == adc || adr == 0 || adc == 0) && isPathClear(fromRow, fromCol, toRow, toCol)
            PieceType.KING -> adr <= 1 && adc <= 1 && (adr + adc > 0)
            else -> false
        }
    }

    private fun findKing(color: PieceColor): Pos? {
        for (r in 0 until 8) for (c in 0 until 8) {
            val p = board[r][c]
            if (p.type == PieceType.KING && p.color == color) return Pos(r, c)
        }
        return null
    }

    private fun isKingInCheck(color: PieceColor): Boolean {
        val king = findKing(color) ?: return false
        val opponent = if (color == PieceColor.WHITE) PieceColor.BLACK else PieceColor.WHITE
        for (r in 0 until 8) for (c in 0 until 8) {
            val p = board[r][c]
            if (!p.isEmpty && p.color == opponent) {
                if (isLegalMoveWithoutKingCheck(r, c, king.row, king.col, opponent)) return true
            }
        }
        return false
    }

    /** Returns true if the move from->to is fully legal (does not expose own king). */
    fun isLegalMove(from: Pos, to: Pos): Boolean {
        val piece = board[from.row][from.col]
        if (piece.isEmpty || piece.color != currentTurn) return false
        if (!isLegalMoveWithoutKingCheck(from.row, from.col, to.row, to.col, currentTurn)) return false

        val captured = board[to.row][to.col]
        board[to.row][to.col] = piece
        board[from.row][from.col] = ChessPiece()
        val exposesCheck = isKingInCheck(currentTurn)
        board[from.row][from.col] = piece
        board[to.row][to.col] = captured
        return !exposesCheck
    }

    /** Returns list of legal destination squares for the piece at [from]. */
    fun legalMovesFrom(from: Pos): List<Pos> {
        val piece = board[from.row][from.col]
        if (piece.isEmpty || piece.color != currentTurn) return emptyList()
        val moves = mutableListOf<Pos>()
        for (r in 0 until 8) for (c in 0 until 8) {
            val to = Pos(r, c)
            if (isLegalMove(from, to)) moves.add(to)
        }
        return moves
    }

    /**
     * Attempts the move. Returns a PendingPromotion pos if a pawn promotion choice
     * is needed (caller must then call resolvePromotion), otherwise completes the move.
     */
    fun makeMove(from: Pos, to: Pos): MoveResult {
        val piece = board[from.row][from.col]
        if (piece.isEmpty || piece.color != currentTurn) {
            lastMessage = "Not your piece!"
            return MoveResult.ILLEGAL
        }
        if (!isLegalMove(from, to)) {
            lastMessage = "Illegal move!"
            return MoveResult.ILLEGAL
        }

        val movedPiece = piece.copy(hasMoved = true)
        board[to.row][to.col] = movedPiece
        board[from.row][from.col] = ChessPiece()

        if (piece.type == PieceType.PAWN && (to.row == 7 || to.row == 0)) {
            lastMessage = "Promote pawn"
            return MoveResult.NEEDS_PROMOTION
        }

        endTurn()
        return MoveResult.OK
    }

    fun resolvePromotion(at: Pos, newType: PieceType) {
        val piece = board[at.row][at.col]
        board[at.row][at.col] = piece.copy(type = newType)
        endTurn()
    }

    private fun endTurn() {
        currentTurn = if (currentTurn == PieceColor.WHITE) PieceColor.BLACK else PieceColor.WHITE
        lastMessage = "Move successful!"
    }

    private fun hasAnyLegalMove(color: PieceColor): Boolean {
        for (r in 0 until 8) for (c in 0 until 8) {
            val p = board[r][c]
            if (!p.isEmpty && p.color == color) {
                for (tr in 0 until 8) for (tc in 0 until 8) {
                    val from = Pos(r, c)
                    val to = Pos(tr, tc)
                    if (isLegalMoveWithoutKingCheck(r, c, tr, tc, color)) {
                        val captured = board[tr][tc]
                        val movingPiece = board[r][c]
                        board[tr][tc] = movingPiece
                        board[r][c] = ChessPiece()
                        val stillInCheck = isKingInCheck(color)
                        board[r][c] = movingPiece
                        board[tr][tc] = captured
                        if (!stillInCheck) return true
                    }
                }
            }
        }
        return false
    }

    fun status(): GameStatus {
        val inCheck = isKingInCheck(currentTurn)
        val hasMove = hasAnyLegalMove(currentTurn)
        return when {
            inCheck && !hasMove -> GameStatus.CHECKMATE
            !inCheck && !hasMove -> GameStatus.STALEMATE
            inCheck -> GameStatus.CHECK
            else -> GameStatus.ONGOING
        }
    }

    fun reset() {
        initBoard()
        lastMessage = ""
    }
}

enum class MoveResult { OK, ILLEGAL, NEEDS_PROMOTION }
