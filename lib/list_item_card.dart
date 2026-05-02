import 'package:flutter/material.dart';
import 'package:new_proj/list_item_page.dart';

class ListItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const ListItemCard({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return ListItemPage(item: item);
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
                  child: item['imageUrls'].isNotEmpty
                      ? Image.network(
                          item['imageUrls'][0],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(
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
                  Text("${item["rent"]} /hr"),
                ],
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ListItemPage(item: item);
                    },
                  ),
                ),
                style: ButtonStyle(
                  splashFactory: NoSplash.splashFactory,
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.all(
                        Radius.circular(10),
                      ),
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
                icon: Icon(Icons.edit_outlined, size: 18),
                label: Text("Edit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
