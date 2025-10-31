// lib/screens/chat/messages_screen.dart
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/services/chat_service.dart';
// If you don't use Firestore here, remove this line
// import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_screen.dart'; // ensure ChatScreen is imported if it’s in another file

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
        return DateFormat.jm().format(DateTime.fromMillisecondsSinceEpoch(ts));
      }
      if (ts is Map) return ''; // unresolved ServerValue.timestamp
      return ts.toString();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages'), backgroundColor: AppColors.primary),
      body: StreamBuilder<rtdb.DatabaseEvent>(
        stream: _conversationsQuery.onValue,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return const Center(child: Text('No conversations yet'));
          }

          final map = Map<String, dynamic>.from(snap.data!.snapshot.value as Map);
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
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final it = items[i];
              final peerId = it['peerId'] ?? it['peerKey'];
              final peerName = it['peerName'] ?? 'Unknown';
              final peerPhoto = it['peerPhoto'] ?? '';
              final last = it['lastMessage'] ?? '';
              final ts = _formatTs(it['timestamp']);

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        peerId: peerId,
                        peerName: peerName,
                        peerPhoto: peerPhoto,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundImage: (peerPhoto.isNotEmpty) ? NetworkImage(peerPhoto) : null,
                  child: (peerPhoto.isEmpty) ? const Icon(Icons.person) : null,
                ),
                title: Text(peerName),
                subtitle: Text(last.toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(ts, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              );
            },
          );
        },
      ),
    );
  }
}
