import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vvs_app/screens/message_screen/widget/MessageListItem.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/services/chat_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final rtdb.Query _conversationsQuery;

  @override
  void initState() {
    super.initState();
    _conversationsQuery = ChatService.conversationsIndexQuery();
  }

  String _formatTs(dynamic ts) {
    if (ts == null) return '';
    try {
      if (ts is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(ts);
        final now = DateTime.now();
        if (now.difference(date).inDays < 1) {
          return DateFormat.jm().format(date);
        } else {
          return DateFormat.MMMd().format(date);
        }
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<rtdb.DatabaseEvent>(
        stream: _conversationsQuery.onValue,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 60,
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start chatting with other members!',
                    style: TextStyle(color: AppColors.subtitle),
                  ),
                ],
              ),
            );
          }

          final map = Map<String, dynamic>.from(
            snap.data!.snapshot.value as Map,
          );
          final items = <Map<String, dynamic>>[];

          map.forEach((k, v) {
            final m = Map<String, dynamic>.from(v as Map);
            m['peerKey'] = k;
            items.add(m);
          });

          items.sort((a, b) {
            final ta = (a['timestamp'] is int) ? a['timestamp'] as int : 0;
            final tb = (b['timestamp'] is int) ? b['timestamp'] as int : 0;
            return tb.compareTo(ta);
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final it = items[i];
              final peerId = it['peerId'] ?? it['peerKey'];
              final peerName = it['peerName'] ?? 'Unknown';
              final peerPhoto = it['peerPhoto'] ?? '';
              final last = it['lastMessage'] ?? '';
              final ts = _formatTs(it['timestamp']);

              // Using custom list item or building one here for better control
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Messagelistitem(
                  peerId: peerId,
                  peerName: peerName,
                  peerPhoto: peerPhoto,
                  lastMessage: last,
                  timestamp: ts,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
