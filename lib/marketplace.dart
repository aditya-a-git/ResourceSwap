import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:new_proj/market_item_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketPlace extends StatelessWidget {
  const MarketPlace({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyMarket();
  }
}

class MyMarket extends StatefulWidget {
  const MyMarket({super.key});

  @override
  State<MyMarket> createState() => _MyMarketState();
}

class _MyMarketState extends State<MyMarket>
    with AutomaticKeepAliveClientMixin {
  late Stream<List<Map<String, dynamic>>> _itemsFuture;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _itemsFuture = getItems();
  }

  Stream<List<Map<String, dynamic>>> getItems() {
    return FirebaseFirestore.instance.collectionGroup('items').snapshots().map((
      snapshot,
    ) {
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
        stream: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items available'));
          } else {
            final uid = FirebaseAuth.instance.currentUser!.uid;

            final items = snapshot.data!
                .where((item) => item['userId'] != uid)
                .toList();

            if (items.isEmpty) {
              return const Center(child: Text('No items available'));
            }
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 0.7,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return MarketItemCard(item: items[index]);
              },
            );
          }
        },
      ),
    );
  }
}
