import 'dart:math';

import 'air_hockey_state.dart';

typedef ScoreCallback = void Function(int scorerNumber);
typedef BallUpdateCallback = void Function(Ball ball);

class Physics {
  final double width;
  final double height;
  final ScoreCallback onScore;
  final BallUpdateCallback onBallUpdate;

  Physics({
    required this.width,
    required this.height,
    required this.onScore,
    required this.onBallUpdate,
  });

  // paddleY 固定行
  double get p1PaddleY => height - 80.0;
  double get p2PaddleY => 80.0;

  void update(AirHockeyState state, double dt) {
    final ball = state.ball;

    ball.x += ball.vx * dt;
    ball.y += ball.vy * dt;

    // 左右牆壁反彈
    if (ball.x - AirHockeyState.ballRadius < 0) {
      ball.x = AirHockeyState.ballRadius;
      ball.vx = ball.vx.abs();
    } else if (ball.x + AirHockeyState.ballRadius > width) {
      ball.x = width - AirHockeyState.ballRadius;
      ball.vx = -ball.vx.abs();
    }

    // 與板子碰撞
    _checkPaddleCollision(ball, state.p1PaddleX, p1PaddleY, 1);
    _checkPaddleCollision(ball, state.p2PaddleX, p2PaddleY, -1);

    // 得分判定（球越過上下邊界）
    if (ball.y - AirHockeyState.ballRadius < 0) {
      // P1 得分（球飛出 P2 那邊）
      state.p1Score++;
      onScore(1);
      _resetBall(state, towardsPlayer: 2);
      onBallUpdate(state.ball);
    } else if (ball.y + AirHockeyState.ballRadius > height) {
      // P2 得分
      state.p2Score++;
      onScore(2);
      _resetBall(state, towardsPlayer: 1);
      onBallUpdate(state.ball);
    }
  }

  void _checkPaddleCollision(Ball ball, double paddleX, double paddleY, int yDir) {
    final dx = ball.x - paddleX;
    final dy = ball.y - paddleY;
    final dist = sqrt(dx * dx + dy * dy);
    final minDist = AirHockeyState.ballRadius + AirHockeyState.paddleRadius;

    if (dist < minDist && dist > 0) {
      // 反彈：Y 方向翻轉，X 方向依碰撞偏移微調
      ball.vy = yDir * ball.vy.abs();
      ball.vx += dx * 0.5; // 增加趣味性
      // 速度限制，避免過快
      final speed = sqrt(ball.vx * ball.vx + ball.vy * ball.vy);
      if (speed > 700) {
        ball.vx = ball.vx / speed * 700;
        ball.vy = ball.vy / speed * 700;
      }
      // 推出重疊
      final overlap = minDist - dist;
      ball.x += dx / dist * overlap;
      ball.y += dy / dist * overlap;

      onBallUpdate(ball);
    }
  }

  void _resetBall(AirHockeyState state, {required int towardsPlayer}) {
    final rng = Random();
    final angle = (rng.nextDouble() * 60 - 30) * (pi / 180);
    const speed = 300.0;
    final vy = towardsPlayer == 1 ? speed * cos(angle) : -speed * cos(angle);
    state.ball = Ball(
      x: width / 2,
      y: height / 2,
      vx: speed * sin(angle),
      vy: vy,
    );
  }
}
