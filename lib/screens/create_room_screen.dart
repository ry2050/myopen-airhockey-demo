import 'package:flutter/material.dart';
import 'package:lan_play/lan_play.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'lobby_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  final String playerName;
  const CreateRoomScreen({super.key, required this.playerName});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  GameRoom? _room;
  String? _error;
  bool _canStart = false;

  @override
  void initState() {
    super.initState();
    _createRoom();
  }

  Future<void> _createRoom() async {
    try {
      final room = await GameRoom.create(
        playerName: widget.playerName,
        maxPlayers: 2,
        gameName: 'air_hockey',
        stateSync: const StateSyncConfig(intervalMs: 50),
        reconnect: const ReconnectConfig(
          strategy: ReconnectStrategy.endGame,
          timeoutSeconds: 0,
        ),
      );

      room.onPlayerJoined = (_) => setState(() {});
      room.onPlayerReadyChanged = (_) {
        setState(() {
          _canStart = room.players
              .where((p) => !p.isHost)
              .every((p) => p.isReady);
        });
      };

      if (mounted) setState(() => _room = room);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _startGame() {
    final room = _room;
    if (room == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LobbyScreen(room: room)),
    );
  }

  @override
  void dispose() {
    // 只在還沒進入 lobby 時才 dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('建立房間')),
      body: SafeArea(
        child: _error != null
            ? Center(child: Text('錯誤：$_error'))
            : _room == null
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final room = _room!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('讓對手掃描 QR Code 加入', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          QrImageView(
            data: room.qrCodeUrl,
            size: 220,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 8),
          SelectableText(
            room.qrCodeUrl,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text('等待玩家', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          ...room.players.map((p) => ListTile(
                leading: Icon(p.isHost ? Icons.star : Icons.person),
                title: Text('P${p.number}  ${p.name}'),
                trailing: p.isHost
                    ? const Text('Host')
                    : Text(p.isReady ? '✅ 準備好' : '⏳ 等待'),
              )),
          const Spacer(),
          FilledButton(
            onPressed: _canStart ? _startGame : null,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('開始遊戲', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
