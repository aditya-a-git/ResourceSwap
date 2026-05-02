import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:new_proj/signup.dart";
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(LoginPage());
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "login_page",
      theme: ThemeData(
        // useSystemColors: true,
        fontFamily: 'Google Sans',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MyLoginPage(),
    );
  }
}

class MyLoginPage extends StatefulWidget {
  const MyLoginPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MyLoginPage();
  }
}

class _MyLoginPage extends State {
  late TextEditingController emailcontroller;
  late TextEditingController passcontroller;

  @override
  void initState() {
    emailcontroller = TextEditingController();
    passcontroller = TextEditingController();
    super.initState();
  }

  Future<void> loginUser() async {
    if (emailcontroller.text.trim().isEmpty ||
        passcontroller.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill all the details")));
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailcontroller.text.trim(),
        password: passcontroller.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      print(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 20, title: Text("Login"), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: emailcontroller,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.deepPurple,
                      width: 2.0,
                    ),
                  ),
                  label: Text("Email"),
                  floatingLabelStyle: TextStyle(color: Colors.deepPurple),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              TextField(
                controller: passcontroller,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.deepPurple,
                      width: 2.0,
                    ),
                  ),
                  label: Text("Password"),
                  floatingLabelStyle: TextStyle(color: Colors.deepPurple),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  minimumSize: WidgetStatePropertyAll(
                    Size(double.infinity, 50),
                  ),
                  elevation: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return 0.0;
                    }
                    return 5.0;
                  }),
                  backgroundColor: WidgetStatePropertyAll(Colors.deepPurple),
                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                ),
                onPressed: () async {
                  await loginUser();
                },
                icon: Icon(Icons.login),
                label: Text("Login", style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 32),
              Text("New User?"),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return SignupPage();
                      },
                    ),
                  );
                },
                icon: Icon(Icons.person_add_alt_1_outlined),
                label: Text("Click here to SignUp"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
