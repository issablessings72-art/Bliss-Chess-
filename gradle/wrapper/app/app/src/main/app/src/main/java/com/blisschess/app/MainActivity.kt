package com.blisschess.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private val DarkSquare = Color(0xFF6B8F71)
private val LightSquare = Color(0xFFF2EAD3)
private val SelectedColor = Color(0xFFE7C24D)
private val MoveHintColor = Color(0xFF3D5A45)
private val BoardBorder = Color(0xFF2E2A22)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize(), color = Color(0xFFFAF6EC)) {
                    BlissChessApp()
                }
            }
        }
    }
}

@Composable
fun BlissChessApp() {
    var board by remember { mutableStateOf(ChessBoard()) }
    var selected by remember { mutableStateOf<Pos?>(null) }
    var legalTargets by remember { mutableStateOf<List<Pos>>(emptyList()) }
    var pendingPromotion by remember { mutableStateOf<Pos?>(null) }
    var statusText by remember { mutableStateOf("White to move") }
    var gameOver by remember { mutableStateOf(false) }

    fun refreshStatus() {
        val status = board.status()
        gameOver = status == GameStatus.CHECKMATE || status == GameStatus.STALEMATE
        val turnName = if (board.currentTurn == PieceColor.WHITE) "White" else "Black"
        statusText = when (status) {
            GameStatus.CHECKMATE -> {
                val winner = if
