import 'package:flutter/material.dart';

/// Local-only match communication. No messages leave the device.
class LocalMatchChatSheet extends StatefulWidget {
  const LocalMatchChatSheet({super.key});

  @override
  State<LocalMatchChatSheet> createState() => _LocalMatchChatSheetState();
}

class _LocalMatchChatSheetState extends State<LocalMatchChatSheet> {
  static const reactions = <String>['👏', '😂', '❤️', '🔥', '👍', '🎉'];
  final _controller = TextEditingController();
  final _messages = <String>[];

  void _send(String message) {
    final value = message.trim();
    if (value.isEmpty) return;
    setState(() {
      if (_messages.length >= 50) _messages.removeAt(0);
      _messages.add(value);
    });
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: SizedBox(
          height: 360,
          child: Column(
            children: [
              const Text(
                'Match chat · On this device',
                style: TextStyle(
                  color: Color(0xFFFFD36B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Messages and reactions are local only. Online delivery will be added with multiplayer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final reaction in reactions)
                    IconButton(
                      tooltip: 'React $reaction',
                      onPressed: () => _send(reaction),
                      icon: Text(
                        reaction,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  key: const Key('local_chat_messages'),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        _messages[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('local_chat_input'),
                      controller: _controller,
                      maxLength: 160,
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type a local message',
                        hintStyle: TextStyle(color: Colors.white54),
                        counterText: '',
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  IconButton(
                    key: const Key('local_chat_send'),
                    tooltip: 'Send local message',
                    onPressed: () => _send(_controller.text),
                    icon: const Icon(
                      Icons.send,
                      color: Color(0xFFFFD36B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
