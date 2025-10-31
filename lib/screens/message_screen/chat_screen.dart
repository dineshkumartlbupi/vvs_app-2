// lib/screens/chat/chat_screen.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vvs_app/services/chat_service.dart';
import 'package:vvs_app/theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String? peerPhoto;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.peerPhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  late final Query _messagesQuery;
  StreamSubscription<DatabaseEvent>? _messagesSub;
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    ChatService.ensureConversation(peerId: widget.peerId, peerName: widget.peerName, peerPhoto: widget.peerPhoto);
    _messagesQuery = ChatService.messagesQuery(peerId: widget.peerId);
    _listen();
  }

  void _listen() {
    _messagesSub = _messagesQuery.onValue.listen((event) {
      _messages.clear();
      final snapVal = event.snapshot.value;
      if (snapVal == null) {
        setState(() {});
        return;
      }
      final m = Map<String, dynamic>.from(snapVal as Map);
      final v = m.values.toList();
      // convert to list of maps, sort by timestamp
      for (final x in v) {
        final map = Map<String, dynamic>.from(x as Map);
        _messages.add(map);
      }
      _messages.sort((a, b) {
        final ta = (a['timestamp'] is int) ? a['timestamp'] as int : 0;
        final tb = (b['timestamp'] is int) ? b['timestamp'] as int : 0;
        return ta.compareTo(tb);
      });
      setState(() {});
      // scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    });
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    try {
      final t = DateTime.fromMillisecondsSinceEpoch(ts);
      return DateFormat.jm().format(t);
    } catch (_) {
      return '';
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ChatService.sendMessage(peerId: widget.peerId, text: text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ChatService.uuid; // internal getter
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: (widget.peerPhoto != null && widget.peerPhoto!.isNotEmpty) ? NetworkImage(widget.peerPhoto!) : null,
              child: (widget.peerPhoto == null || widget.peerPhoto!.isEmpty) ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peerName),
                // optionally show online / last seen using Firestore presence
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet — say hi 👋'))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final from = (m['from'] ?? '').toString();
                      final isMe = from == myUid;
                      final txt = (m['text'] ?? '').toString();
                      final ts = m['timestamp'];
                      final time = ts is int ? _formatTime(ts) : '';
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          child: Card(
                            color: isMe ? AppColors.primary.withOpacity(0.95) : Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    txt,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    time,
                                    style: TextStyle(
                                      color: (isMe ? Colors.white70 : Colors.black45),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _send,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
