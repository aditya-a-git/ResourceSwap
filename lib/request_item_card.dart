import 'package:flutter/material.dart';
import 'package:new_proj/request_item_page.dart';

class RequestItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const RequestItemCard({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    final imageUrls = List<String>.from(item['imageUrls'] ?? []);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return RequestItemPage(item: item);
          },
        ),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: imageUrls.isNotEmpty
                      ? Image.network(
                          imageUrls[0],
                          fit: BoxFit.cover,
                          height: 100,
                          width: double.infinity,
                        )
                      : Container(
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 40),
                        ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "${item['name']}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Icon(Icons.currency_rupee, size: 16, color: Colors.grey[700]),
                  Text("${item['rent']} /hr"),
                ],
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return RequestItemPage(item: item);
                    },
                  ),
                ),
                style: ButtonStyle(
                  splashFactory: NoSplash.splashFactory,
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  minimumSize: WidgetStatePropertyAll(
                    Size(double.infinity, 30),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return const Color.fromARGB(255, 68, 38, 121);
                    }
                    return Colors.deepPurple;
                  }),
                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                ),
                icon: Icon(Icons.visibility_outlined, size: 18),
                label: Text("View Details"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
