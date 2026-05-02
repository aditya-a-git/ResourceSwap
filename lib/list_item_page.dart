import 'package:flutter/material.dart';
import 'package:new_proj/add_edit_item.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'full_screen_image.dart';

class ListItemPage extends StatelessWidget {
  final Map<String, dynamic> item;
  const ListItemPage({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return MyListItemPage(item: item);
  }
}

class MyListItemPage extends StatefulWidget {
  final Map<String, dynamic> item;
  const MyListItemPage({required this.item, super.key});

  @override
  State<MyListItemPage> createState() => _MyListItemPageState();
}

class _MyListItemPageState extends State<MyListItemPage> {
  late List<String> images;
  late Map<String, dynamic> _itemData;
  String? name, dept, ph, email;

  PageController controller = PageController();

  @override
  void initState() {
    super.initState();
    _itemData = Map<String, dynamic>.from(widget.item);
    images = List<String>.from(_itemData['imageUrls']);
    getUser();
  }

  bool _isLoadingUser = true;

  Future<void> getUser() async {
    final map = await FirebaseFirestore.instance
        .collection('users')
        .doc(_itemData['userId'])
        .get();
    final user = map.data();
    setState(() {
      name = user!['name'];
      dept = user['department'];
      ph = user['phone'];
      email = user['email'];
      _isLoadingUser = false;
    });
  }

  Future<void> _reloadItem() async {
    final uid = _itemData['userId'];

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('items')
        .doc(_itemData['itemId'])
        .get();

    final data = doc.data();

    if (data == null) return;

    setState(() {
      _itemData = {...data, "itemId": _itemData['itemId'], "userId": uid};

      images = List<String>.from(_itemData['imageUrls']);
    });
  }

  Future<void> _deleteItem() async {
    final uid = _itemData['userId'];
    final itemId = _itemData['itemId'];
    final files = await Supabase.instance.client.storage
        .from('images')
        .list(path: '$uid/$itemId');
    final imagePaths = files
        .map((file) => "$uid/$itemId/${file.name}")
        .toList();

    if (imagePaths.isNotEmpty) {
      await Supabase.instance.client.storage.from('images').remove(imagePaths);
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('items')
        .doc(itemId)
        .delete();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Item Details"), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      controller: controller,
                      itemCount: images.length,
                      itemBuilder: (context, idx) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) {
                                  return FullScreenImageViewer(
                                    images: images,
                                    initialIndex: idx,
                                  );
                                },
                              ),
                            );
                          },
                          child: Image.network(images[idx], fit: BoxFit.cover),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 5),
                  SmoothPageIndicator(
                    controller: controller,
                    count: images.length,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      paintStyle: PaintingStyle.stroke,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.deepPurple,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadiusGeometry.circular(8),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${_itemData['name']}",
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.currency_rupee, size: 20),
                                  Text(
                                    "${_itemData['rent']} /hr",
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.deepPurple,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadiusGeometry.circular(8),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.notes_outlined, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    "Description:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text("${_itemData['desc']}"),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.deepPurple,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadiusGeometry.circular(8),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person_outline),
                                  SizedBox(width: 8),
                                  Text(
                                    "Owner Details:",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              _isLoadingUser
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : Text(
                                      "Name: $name\nDepartment: $dept\nPh no: $ph\nEmail: $email",
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) {
                                    return AddEdit(
                                      add: false,
                                      itemId: _itemData['itemId'],
                                    );
                                  },
                                ),
                              ).then((_) {
                                _reloadItem();
                              });
                            },
                            icon: Icon(Icons.edit),
                            label: Text("Edit", style: TextStyle(fontSize: 16)),
                            style: ButtonStyle(
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                              ),
                              backgroundColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.pressed)) {
                                  return const Color.fromARGB(255, 68, 38, 121);
                                }
                                return Colors.deepPurple;
                              }),
                              foregroundColor: WidgetStatePropertyAll(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text("Delete item?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteItem();
                                          Navigator.of(context).pop();
                                        },
                                        child: Text("Confirm"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: Icon(Icons.delete),
                            label: Text(
                              "Delete",
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ButtonStyle(
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                              ),
                              backgroundColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.pressed)) {
                                  return const Color.fromARGB(255, 200, 50, 50);
                                }
                                return Colors.red;
                              }),
                              foregroundColor: WidgetStatePropertyAll(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

