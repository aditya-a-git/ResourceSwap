import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:new_proj/home_page.dart";
import "package:new_proj/login.dart";
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(SignupPage());
}

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "signup_page",
      theme: ThemeData(
        useSystemColors: true,
        fontFamily: 'Google Sans',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MySignupPage(),
    );
  }
}

class MySignupPage extends StatefulWidget {
  const MySignupPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MySignupPage();
  }
}

class _MySignupPage extends State {
  late TextEditingController emailcontroller;
  late TextEditingController passcontroller;
  late TextEditingController namecontroller;
  late TextEditingController phcontroller;
  late TextEditingController deptcontroller;

  @override
  void initState() {
    emailcontroller = TextEditingController();
    passcontroller = TextEditingController();
    namecontroller = TextEditingController();
    phcontroller = TextEditingController();
    deptcontroller = TextEditingController();
    super.initState();
  }

  Future<void> createUser() async {
    if (namecontroller.text.trim().isEmpty ||
        deptcontroller.text.trim().isEmpty ||
        phcontroller.text.trim().isEmpty ||
        emailcontroller.text.trim().isEmpty ||
        passcontroller.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill all the details")));
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailcontroller.text.trim(),
            password: passcontroller.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({
            "name": namecontroller.text.trim(),
            "department": deptcontroller.text.trim(),
            "phone": phcontroller.text.trim(),
            "email": emailcontroller.text.trim(),
          });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return HomePage();
            },
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "An error occurred")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 20, title: Text("SignUp"), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: namecontroller,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.deepPurple,
                        width: 2.0,
                      ),
                    ),
                    label: Text("Full Name"),
                    floatingLabelStyle: TextStyle(color: Colors.deepPurple),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: deptcontroller,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.school_outlined),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.deepPurple,
                        width: 2.0,
                      ),
                    ),
                    label: Text("Department"),
                    floatingLabelStyle: TextStyle(color: Colors.deepPurple),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
                SizedBox(height: 16),
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
                  controller: phcontroller,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.deepPurple,
                        width: 2.0,
                      ),
                    ),
                    label: Text("Phone number"),
                    floatingLabelStyle: TextStyle(color: Colors.deepPurple),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  keyboardType: TextInputType.numberWithOptions(),
                  obscureText: false,
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
                    label: Text("Create Password"),
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
                    await createUser();
                  },
                  icon: Icon(Icons.person_add_alt_1_outlined),
                  label: Text("SignUp", style: TextStyle(fontSize: 18)),
                ),
                SizedBox(height: 32),
                Text("Already a user?"),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  icon: Icon(Icons.login),
                  label: Text("Click here to Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
