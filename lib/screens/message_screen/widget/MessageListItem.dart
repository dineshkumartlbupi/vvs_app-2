import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vvs_app/screens/message_screen/chat_screen.dart';
import 'package:vvs_app/theme/app_colors.dart';

class Messagelistitem extends StatelessWidget {
  final String peerId;
  final String peerName;
  final String peerPhoto;
  final String lastMessage;
  final String timestamp;

  const Messagelistitem({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.peerPhoto,
    required this.lastMessage,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(width: 1,color: AppColors.primary.withOpacity(0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: peerPhoto.isNotEmpty
                  ? NetworkImage(peerPhoto)
                  : null,
              child: peerPhoto.isEmpty
                  ? const Icon(Icons.person, color: Colors.grey, size: 28)
                  : null,
            ),
            const SizedBox(width: 12),

            // Name and message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peerName.isNotEmpty ? peerName : "Unknown User",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Time
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timestamp,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
