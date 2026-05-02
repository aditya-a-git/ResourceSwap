import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:new_proj/add_edit_item.dart';
import 'package:new_proj/list_item_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Listings extends StatelessWidget {
  const Listings({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyListings();
  }
}

class MyListings extends StatefulWidget {
  const MyListings({super.key});

  @override
  State<MyListings> createState() => _MyListingsState();
}

class _MyListingsState extends State<MyListings>
    with AutomaticKeepAliveClientMixin {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  @override
  bool get wantKeepAlive => true;

  Stream<List<Map<String, dynamic>>> getItems() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('items')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data.addAll({
              "itemId": doc.id,
              "userId": doc.reference.parent.parent!.id,
            });
            return data;
          }).toList();
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
            return const Center(child: Text('No items available'));
          } else {
            final items = snapshot.data!;
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 0.7,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListItemCard(item: items[index]);
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                return AddEdit(add: true);
              },
            ),
          );
        },
        tooltip: "Add Item",
        child: Icon(Icons.add),
      ),
    );
  }
}
