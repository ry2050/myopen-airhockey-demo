import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lan_play/lan_play.dart';
import 'package:uuid/uuid.dart';

import '../game/air_hockey_state.dart';
import '../game/physics.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  final GameRoom room;
  const GameScreen({super.key, required this.room});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  GameRoom get room => widget.room;

  late AirHockeyState _state;
  late Size _fieldSize;
  bool _sizeKnown = false;

  Physics? _physics;
  Timer? _gameLoop;

  // 插值用：上次收到的球位置 + 目標位置
  Offset _ballRender = Offset.zero;
  Offset _ballTarget = Offset.zero;
  DateTime _lastBallUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCallbacks();
  }

  void _setupCallbacks() {
    room.onStateUpdate = (playerId, state) {
      if (!_sizeKnown) return; // _state not yet initialised
      final paddleX = (state['paddleX'] as num?)?.toDouble();
      if (paddleX == null) return;
      setState(() {
        if (room.me.number == 1) {
          _state.p2PaddleX = paddleX;
        } else {
          _state.p1PaddleX = paddleX;
        }
      });
    };

    room.onEvent = (playerId, type, data) {
      switch (type) {
        case 'ball_update':
          final x = (data['x'] as num).toDouble();
          final y = (data['y'] as num).toDouble();
          final vx = (data['vx'] as num).toDouble();
          final vy = (data['vy'] as num).toDouble();
          setState(() {
            _ballTarget = Offset(x, y);
            _state.ball.vx = vx;
            _state.ball.vy = vy;
            _lastBallUpdate = DateTime.now();
          });
        case 'score':
          final scorer = data['scorer'] as int;
          setState(() {
            if (scorer == 1) {
              _state.p1Score++;
            } else {
              _state.p2Score++;
            }
          });
          _checkWin();
      }
    };

    room.onStateSnapshotRequested = (playerId) => _state.toSnapshot();

    room.onPlayerDisconnected = (player) {
      if (!mounted) return;
      // Air Hockey: 對手斷線直接結算，我方獲勝
      final myScore = room.me.number == 1 ? _state.p1Score : _state.p2Score;
      final oppScore = room.me.number == 1 ? _state.p2Score : _state.p1Score;
      final result = GameResult(
        gameId: const Uuid().v4(),
        endedAt: DateTime.now(),
        players: [
          PlayerResult(
            playerId: room.me.id,
            playerName: room.me.name,
            number: room.me.number,
            score: myScore,
            isWinner: true,
          ),
          PlayerResult(
            playerId: player.id,
            playerName: player.name,
            number: player.number,
            score: oppScore,
            isWinner: false,
          ),
        ],
      );
      if (room.isHost) {
        // endGame broadcasts and triggers onGameEnd → _goToResult
        room.endGame(result);
      } else {
        _goToResult(result);
      }
    };

    room.onGameEnd = (result) {
      if (mounted) _goToResult(result);
    };
  }

  void _initGame(Size size) {
    if (_sizeKnown) return; // guard against multiple LayoutBuilder callbacks
    _fieldSize = size;
    _state = AirHockeyState.initial(size.width, size.height);
    _ballRender = Offset(_state.ball.x, _state.ball.y);
    _ballTarget = _ballRender;
    _sizeKnown = true;

    if (room.isHost) {
      _physics = Physics(
        width: size.width,
        height: size.height,
        onScore: (scorer) {
          // Update host's own score (client updates via onEvent)
          if (scorer == 1) {
            _state.p1Score++;
          } else {
            _state.p2Score++;
          }
          room.sendEvent('score', {'scorer': scorer});
          _checkWin();
        },
        onBallUpdate: (ball) {
          room.sendEvent('ball_update', {
            'x': ball.x,
            'y': ball.y,
            'vx': ball.vx,
            'vy': ball.vy,
          });
        },
      );

      const fps = Duration(milliseconds: 16); // ~60fps
      DateTime last = DateTime.now();
      _gameLoop = Timer.periodic(fps, (_) {
        final now = DateTime.now();
        final dt = now.difference(last).inMilliseconds / 1000.0;
        last = now;
        _physics!.update(_state, dt.clamp(0, 0.05));
        if (mounted) setState(() {});
      });
    } else {
      // Client: 球做插值動畫
      _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
        final elapsed = DateTime.now().difference(_lastBallUpdate).inMilliseconds / 1000.0;
        setState(() {
          _ballRender = Offset.lerp(
            _ballRender,
            _ballTarget + Offset(_state.ball.vx * elapsed, _state.ball.vy * elapsed),
            0.3,
          )!;
        });
      });
    }
  }

  void _checkWin() {
    if (_state.p1Score >= AirHockeyState.winScore || _state.p2Score >= AirHockeyState.winScore) {
      if (!room.isHost) return;
      final p1Wins = _state.p1Score >= AirHockeyState.winScore;
      final opponents = room.players.where((p) => !p.isHost).toList();
      final opp = opponents.isNotEmpty ? opponents.first : room.me;
      final result = GameResult(
        gameId: const Uuid().v4(),
        endedAt: DateTime.now(),
        players: [
          PlayerResult(
            playerId: room.me.id,
            playerName: room.me.name,
            number: 1,
            score: _state.p1Score,
            isWinner: p1Wins,
          ),
          PlayerResult(
            playerId: opp.id,
            playerName: opp.name,
            number: 2,
            score: _state.p2Score,
            isWinner: !p1Wins,
          ),
        ],
      );
      room.endGame(result);
    }
  }

  void _goToResult(GameResult result) {
    _gameLoop?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(room: room, result: result),
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_sizeKnown) return;
    final x = details.localPosition.dx.clamp(
      AirHockeyState.paddleRadius,
      _fieldSize.width - AirHockeyState.paddleRadius,
    );
    setState(() {
      if (room.me.number == 1) {
        _state.p1PaddleX = x;
      } else {
        _state.p2PaddleX = x;
      }
    });
    room.updateState({'paddleX': x});
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p1 = room.players.firstWhere((p) => p.number == 1, orElse: () => room.me);
    final p2 = room.players.firstWhere(
      (p) => p.number == 2,
      orElse: () => Player(id: '', name: '?', number: 2, isHost: false),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 對手資訊列（上方）
            _InfoBar(player: p2, score: _sizeKnown ? _state.p2Score : 0),
            // 遊戲場地
            Expanded(
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    if (!_sizeKnown) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _initGame(size);
                      });
                    }
                    if (!_sizeKnown) return const SizedBox.expand();
                    return CustomPaint(
                      size: size,
                      painter: _HockeyPainter(
                        state: _state,
                        ballRender: room.isHost
                            ? Offset(_state.ball.x, _state.ball.y)
                            : _ballRender,
                        myNumber: room.me.number,
                      ),
                    );
                  },
                ),
              ),
            ),
            // 自己資訊列（下方）
            _InfoBar(player: p1, score: _sizeKnown ? _state.p1Score : 0),
          ],
        ),
      ),
    );
  }
}

// ── 資訊列 ────────────────────────────────────────────────────────────────────

class _InfoBar extends StatelessWidget {
  final Player player;
  final int score;
  const _InfoBar({required this.player, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('P${player.number}  ${player.name}',
              style: const TextStyle(fontSize: 16)),
          Text('$score 分', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

// ── CustomPainter ─────────────────────────────────────────────────────────────

class _HockeyPainter extends CustomPainter {
  final AirHockeyState state;
  final Offset ballRender;
  final int myNumber;

  _HockeyPainter({
    required this.state,
    required this.ballRender,
    required this.myNumber,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF1A237E);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 中線
    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), linePaint);

    // 中圈
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      60,
      linePaint,
    );

    final p1Y = size.height - 80.0;
    final p2Y = 80.0;

    // 板子
    final p1Paint = Paint()..color = Colors.cyanAccent;
    final p2Paint = Paint()..color = Colors.pinkAccent;

    canvas.drawCircle(
        Offset(state.p1PaddleX, p1Y), AirHockeyState.paddleRadius, p1Paint);
    canvas.drawCircle(
        Offset(state.p2PaddleX, p2Y), AirHockeyState.paddleRadius, p2Paint);

    // 球
    final ballPaint = Paint()..color = Colors.white;
    canvas.drawCircle(ballRender, AirHockeyState.ballRadius, ballPaint);
  }

  @override
  bool shouldRepaint(_HockeyPainter old) => true;
}
