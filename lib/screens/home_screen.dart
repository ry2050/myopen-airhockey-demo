import 'package:flutter/material.dart';

import 'create_room_screen.dart';
import 'join_room_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _goCreate() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showNameError();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateRoomScreen(playerName: name)),
    );
  }

  void _goJoin() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showNameError();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JoinRoomScreen(playerName: name)),
    );
  }

  void _showNameError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('請輸入暱稱')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '🏒 Air Hockey',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '暱稱',
                  border: OutlineInputBorder(),
                ),
                maxLength: 20,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _goCreate,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('建立房間', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _goJoin,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('加入房間', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
