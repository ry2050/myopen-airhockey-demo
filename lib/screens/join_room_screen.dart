import 'package:flutter/material.dart';
import 'package:lan_play/lan_play.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'lobby_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  final String playerName;
  const JoinRoomScreen({super.key, required this.playerName});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _controller = MobileScannerController();
  bool _scanned = false;
  bool _showManual = false;
  final _urlCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _joinWithUrl(String url) async {
    if (_scanned) return;
    _scanned = true;
    await _controller.stop();

    try {
      final room = await GameRoom.join(
        url: url,
        playerName: widget.playerName,
      );
      if (!mounted) {
        room.dispose();
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LobbyScreen(room: room)),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _scanned = false;
        });
        await _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('加入房間'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showManual = !_showManual),
            child: Text(_showManual ? '掃碼' : '手動輸入'),
          ),
        ],
      ),
      body: SafeArea(
        child: _showManual ? _buildManual() : _buildScanner(),
      ),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              final url = barcode?.rawValue;
              if (url != null && url.startsWith('ws://')) {
                _joinWithUrl(url);
              }
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('對準 Host 顯示的 QR Code'),
        ),
      ],
    );
  }

  Widget _buildManual() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'WebSocket URL',
              hintText: 'ws://192.168.x.x:8765',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _joinWithUrl(_urlCtrl.text.trim()),
            child: const Text('連線'),
          ),
        ],
      ),
    );
  }
}
