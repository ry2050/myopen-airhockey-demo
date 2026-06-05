import 'package:flutter/material.dart';
import 'package:lan_play/lan_play.dart';

import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final GameRoom room;
  const LobbyScreen({super.key, required this.room});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  GameRoom get room => widget.room;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    room.onPlayerJoined = (_) => setState(() {});
    room.onPlayerLeft = (_) => setState(() {});
    room.onPlayerReadyChanged = (_) => setState(() {});
    room.onGameStart = () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GameScreen(room: room)),
      );
    };

    // Host 觸發 onGameStart 後也跳轉（host 呼叫 startGame() 時）
  }

  void _setReady() {
    if (_ready) return;
    _ready = true;
    room.setReady();
    setState(() {});
  }

  void _startGame() {
    room.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final players = room.players;
    final allClientsReady = players.where((p) => !p.isHost).every((p) => p.isReady);

    return Scaffold(
      appBar: AppBar(title: const Text('等待室')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('玩家列表', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              ...players.map((p) => Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('P${p.number}')),
                      title: Text(p.name),
                      subtitle: Text(p.isHost ? 'Host' : ''),
                      trailing: p.isReady
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.radio_button_unchecked),
                    ),
                  )),
              const Spacer(),
              if (room.isHost)
                FilledButton(
                  onPressed: players.length >= 2 && allClientsReady
                      ? _startGame
                      : null,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('開始遊戲', style: TextStyle(fontSize: 18)),
                  ),
                )
              else
                FilledButton(
                  onPressed: _ready ? null : _setReady,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _ready ? '已準備好！等待 Host 開始…' : '準備好了',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
