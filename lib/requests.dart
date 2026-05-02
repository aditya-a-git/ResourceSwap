import 'package:flutter/material.dart';
import 'package:new_proj/request_item_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Requests extends StatelessWidget {
  const Requests({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyRequests();
  }
}

class MyRequests extends StatefulWidget {
  const MyRequests({super.key});

  @override
  State<MyRequests> createState() => _MyRequestsState();
}

class _MyRequestsState extends State<MyRequests>
    with AutomaticKeepAliveClientMixin {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  @override
  bool get wantKeepAlive => true;

  Stream<List<Map<String, dynamic>>> getItems() {
    return FirebaseFirestore.instance
        .collection('requests')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final items = await Future.wait(
            snapshot.docs.map((doc) async {
              final requestData = doc.data();
              final userId = requestData['ownerId']?.toString();
              final itemId = requestData['itemId']?.toString();
              final requesterId = requestData['requesterId']?.toString();

              if (userId == null || itemId == null || requesterId == null) {
                return null;
              }

              Map<String, dynamic>? itemData;

              try {
                final itemDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('items')
                    .doc(itemId)
                    .get();

                itemData = itemDoc.data();
              } catch (_) {
                itemData = null;
              }

              itemData ??= {
                'name': requestData['name'],
                'rent': requestData['rent'],
                'desc': requestData['desc'],
                'imageUrls': requestData['imageUrls'] ?? [],
              };

              if (itemData['name'] == null ||
                  itemData['rent'] == null ||
                  itemData['desc'] == null) {
                return null;
              }

              return {
                ...itemData,
                'requestId': doc.id,
                'itemId': itemId,
                'userId': userId,
                'ownerId': userId,
                'requesterId': requesterId,
                'status': requestData['status'],
                'otp': requestData['otp'],
                'createdAt': requestData['createdAt'],
                'acceptedAt': requestData['acceptedAt'],
              };
            }),
          );

          return items.whereType<Map<String, dynamic>>().toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No requests available'));
          } else {
            final items = snapshot.data!;
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 0.7,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return RequestItemCard(item: items[index]);
              },
            );
          }
        },
      ),
    );
  }
}
