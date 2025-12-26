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
    ChatService.ensureConversation(
        peerId: widget.peerId,
        peerName: widget.peerName,
        peerPhoto: widget.peerPhoto);
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
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
    final myUid = ChatService.uuid;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: (widget.peerPhoto != null && widget.peerPhoto!.isNotEmpty)
                  ? NetworkImage(widget.peerPhoto!)
                  : null,
              child: (widget.peerPhoto == null || widget.peerPhoto!.isEmpty)
                  ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.peerName,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.waving_hand_rounded,
                              color: AppColors.primary, size: 40),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Say Hello! 👋',
                          style: TextStyle(
                            color: AppColors.subtitle,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                txt,
                                style: TextStyle(
                                  color: isMe ? Colors.white : AppColors.text,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  color: isMe ? Colors.white.withOpacity(0.7) : AppColors.subtitle.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
