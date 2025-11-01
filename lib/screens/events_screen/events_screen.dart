import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vvs_app/screens/events_screen/AddEventScreen.dart';
import 'package:vvs_app/theme/app_colors.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _deleteEvent(String id) async {
    await _firestore.collection('events').doc(id).delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Event deleted successfully')));
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Community Events'),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
              dividerHeight: 0,
          labelColor: Colors.white, // active tab text color
          unselectedLabelColor: Colors.white70, // inactive tab text color
            tabs: [
              Tab(text: "All Events"),
              Tab(text: "My Events"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEventScreen()),
            );
          },
          child: const Icon(Icons.add,color: Colors.white,),
        ),
        body: TabBarView(
          children: [
            _buildEventList(
              query: _firestore
                  .collection('events')
                  .orderBy('createdAt', descending: true),
              showActions: false,
              uid: uid,
            ),
            _buildEventList(
              query: _firestore
                  .collection('events')
                  .where('organizerId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true),
              showActions: true,
              uid: uid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList({
    required Query query,
    required bool showActions,
    required String? uid,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No events found.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;

            final title = data['title'] ?? '';
            final description = data['description'] ?? '';
            final location = data['location'] ?? '';
            final date = (data['eventDate'] as Timestamp?)?.toDate();
            final imageUrl = data['imageUrl'];
            final organizer = data['organizerName'] ?? 'Unknown';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      if (showActions)
                       if (showActions)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                  Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddEventScreen(
                                      eventId: id,
                                      existingData: data,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      width: 1, color: AppColors.primary),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit,
                                        size: 18, color: Colors.blueAccent),
                                    SizedBox(width: 4),
                                    Text("Edit",
                                        style: TextStyle(color: Colors.blue)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                             onTap: () => _deleteEvent(id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      width: 1, color: AppColors.primary),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 18, color: Colors.redAccent),
                                    SizedBox(width: 4),
                                    Text("Delete",
                                        style:
                                            TextStyle(color: Colors.redAccent)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    

                       
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'By $organizer${createdAt != null ? ' • ${_formatDate(createdAt)}' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    const SizedBox(height: 10),
                  if (date != null)
                    Text(
                      '📅 ${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (location.isNotEmpty)
                    Text(
                      '📍 $location',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  const SizedBox(height: 10),
                  Text(description, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
