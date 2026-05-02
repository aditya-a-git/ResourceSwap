import 'package:flutter/material.dart';
import 'package:new_proj/listings.dart';
import 'package:new_proj/marketplace.dart';
import 'package:new_proj/requests.dart';
import "package:firebase_auth/firebase_auth.dart";

void main() {
  runApp(const HomePage());
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "home_page",
      theme: ThemeData(
        useSystemColors: true,
        fontFamily: 'Google Sans',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                return _showLogoutDialog(context);
              },
              icon: Icon(Icons.logout),
            ),
          ],
          title: Text("Resource Swap"),
          centerTitle: true,
          bottom: TabBar.secondary(
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: const Color.fromARGB(255, 170, 160, 196),
            splashFactory: InkSplash.splashFactory,
            tabs: [
              Tab(icon: Icon(Icons.storefront_outlined), text: "Marketplace"),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: "Your Listings"),
              Tab(icon: Icon(Icons.assignment_outlined), text: "Requests"),
            ],
          ),
        ),
        body: TabBarView(children: [MarketPlace(), Listings(), Requests()]),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }
}
