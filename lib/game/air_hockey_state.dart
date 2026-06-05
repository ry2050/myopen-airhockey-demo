import 'dart:ui';

class Ball {
  double x;
  double y;
  double vx;
  double vy;

  Ball({required this.x, required this.y, required this.vx, required this.vy});

  Offset get offset => Offset(x, y);
}

class AirHockeyState {
  static const double paddleRadius = 30.0;
  static const double ballRadius = 15.0;
  static const int winScore = 5;

  Ball ball;
  double p1PaddleX;
  double p2PaddleX;
  int p1Score;
  int p2Score;
  bool gameOver;
  int? winnerId; // player number

  AirHockeyState({
    required this.ball,
    required this.p1PaddleX,
    required this.p2PaddleX,
    this.p1Score = 0,
    this.p2Score = 0,
    this.gameOver = false,
    this.winnerId,
  });

  factory AirHockeyState.initial(double width, double height) {
    return AirHockeyState(
      ball: Ball(x: width / 2, y: height / 2, vx: 200, vy: 300),
      p1PaddleX: width / 2,
      p2PaddleX: width / 2,
    );
  }

  Map<String, dynamic> toSnapshot() => {
    'ball': {'x': ball.x, 'y': ball.y, 'vx': ball.vx, 'vy': ball.vy},
    'p1PaddleX': p1PaddleX,
    'p2PaddleX': p2PaddleX,
    'p1Score': p1Score,
    'p2Score': p2Score,
  };

  void applySnapshot(Map<String, dynamic> snap) {
    final b = snap['ball'] as Map<String, dynamic>;
    ball = Ball(
      x: (b['x'] as num).toDouble(),
      y: (b['y'] as num).toDouble(),
      vx: (b['vx'] as num).toDouble(),
      vy: (b['vy'] as num).toDouble(),
    );
    p1PaddleX = (snap['p1PaddleX'] as num).toDouble();
    p2PaddleX = (snap['p2PaddleX'] as num).toDouble();
    p1Score = snap['p1Score'] as int;
    p2Score = snap['p2Score'] as int;
  }
}
