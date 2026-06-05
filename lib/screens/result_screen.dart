import 'package:flutter/material.dart';
import 'package:lan_play/lan_play.dart';

import 'lobby_screen.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final GameRoom room;
  final GameResult result;
  const ResultScreen({super.key, required this.room, required this.result});

  PlayerResult? get _myResult {
    try {
      return result.players.firstWhere((p) => p.playerId == room.me.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _myResult;
    final iWon = me?.isWinner ?? false;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                iWon ? '🎉 你贏了！' : '😅 你輸了',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ...result.players.map((p) => Card(
                    color: p.isWinner ? Colors.green.shade900 : null,
                    child: ListTile(
                      leading: CircleAvatar(child: Text('P${p.number}')),
                      title: Text(p.playerName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${p.score} 分',
                              style: const TextStyle(fontSize: 18)),
                          if (p.isWinner)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.emoji_events,
                                  color: Colors.amber),
                            ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 48),
              FilledButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LobbyScreen(room: room)),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('再來一局', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  room.dispose();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (_) => false,
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('離開', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
