import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/home_page.dart'; // Import from screens folder


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    FutureBuilder(
      future: _initFirebase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const MyApp();
        }
        return const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}


Future<void> _initFirebase() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}




// LOGIN PAGE
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/routeeats.png', height: 200),
            const SizedBox(height: 40),
            _buildCardInputField("Username", usernameController),
            const SizedBox(height: 20),
            _buildCardInputField("Password", passwordController, obscure: true),
            const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            final enteredUsername = usernameController.text.trim();
            final enteredPassword = passwordController.text.trim();

            if (enteredUsername.isEmpty || enteredPassword.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please fill in both fields")),
              );
              return;
            }

            try {
              // Step 1: Get email from Firestore by username
              final querySnapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .where('username', isEqualTo: enteredUsername)
                  .get();

              if (querySnapshot.docs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Username not found")),
                );
                return;
              }

              final userData = querySnapshot.docs.first.data();
              final email = userData['email'];

              // Step 2: Sign in using email
              final userCredential = await FirebaseAuth.instance
                  .signInWithEmailAndPassword(email: email, password: enteredPassword);

              print("✅ Login successful: ${userCredential.user?.email}");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(),
                ),
              );


            } on FirebaseAuthException catch (e) {
              String errorMsg = "Login failed: ${e.message}";
              if (e.code == 'wrong-password') {
                errorMsg = "Wrong password.";
              } else if (e.code == 'user-not-found') {
                errorMsg = "Account does not exist.";
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg)),
              );
            } catch (e) {
              print("❌ Error: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("An error occurred. Please try again.")),
              );
            }
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            child: Text("Log In"),
          ),
        ),


            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PersonalInfoPage()),
                );
              },
              child: const Text("Don't have an account? Sign Up"),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildCardInputField(String hint, TextEditingController controller, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// SIGN-UP STEP 1 – PERSONAL INFO
class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final username = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: (){
                    Navigator.pop(context);
                    },
                   ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children:[
                  Center(
                    child:Column(
                      children: [Text("Join Us", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    Image.asset('assets/sign-up.png', height: 200),
                     ],
                  ),
                  ),
              const SizedBox(height: 10),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _buildCardInputField("First Name", firstName),
                  ),
                  const SizedBox(width: 15,),
                  Expanded(
                    child: _buildCardInputField("Last Name", lastName),
                  ),
                ],
              ),
              const SizedBox(height: 15),
                  _buildCardInputField("Username", username),
                  const SizedBox(height: 15),
                  _buildCardInputField("Email Address", email),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (firstName.text.isNotEmpty &&
                        lastName.text.isNotEmpty &&
                        email.text.isNotEmpty &&
                        username.text.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SecureAccountPage(
                            firstName: firstName.text,
                            lastName: lastName.text,
                            email: email.text,
                            username: username.text,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    child: Text("Save & Continue"),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
      ),
    );
  }

  Widget _buildCardInputField(String hint, TextEditingController controller, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// SIGN-UP STEP 2 – SECURE ACCOUNT
class SecureAccountPage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String username;


  const SecureAccountPage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
  });

  @override
  State<SecureAccountPage> createState() => _SecureAccountPageState();
}

class _SecureAccountPageState extends State<SecureAccountPage> {
  final password1 = TextEditingController();
  final password2 = TextEditingController();
  final phone = TextEditingController();
  String? selectedDay;
  String? selectedMonth;
  String? selectedYear;
  String? errorText;
  bool showPassword = false;
  bool showConfirmPassword = false;


  List<String> days = List.generate(31, (index) => "${index + 1}");
  List<String> months = List.generate(12, (index) => "${index + 1}");
  List<String> years = List.generate(100, (index) => "${2025 - index}");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Secure Account",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Image.asset('assets/secure-acc.png', height: 200),
                const SizedBox(height: 30),
                const Text(
                  "Birthday",
                  style: TextStyle(
                    fontSize: 20,          // 👈 Set the font size
                    fontWeight: FontWeight.w500,  // 👈 Optional: font weight
                    fontFamily: 'SFPRODISPLAYREGULAR',   // 👈 Optional: custom font
                    color: Colors.black,          // 👈 Optional: text color
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown("Day", days, selectedDay, (val) {
                        setState(() => selectedDay = val);
                      }),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdown("Month", months, selectedMonth, (val) {
                        setState(() => selectedMonth = val);
                      }),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdown("Year", years, selectedYear, (val) {
                        setState(() => selectedYear = val);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: password1,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    hintText: "Password",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                TextField(
                  controller: password2,
                  obscureText: !showConfirmPassword,
                  decoration: InputDecoration(
                    hintText: "Confirm Password",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          showConfirmPassword = !showConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                _buildCardInputField("Phone Number", phone),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (password1.text != password2.text) {
                        setState(() => errorText = "Passwords do not match");
                        return;
                      }
                      if (selectedDay == null || selectedMonth == null || selectedYear == null) {
                        setState(() => errorText = "Please select birthday");
                        return;
                      }
                      if (phone.text.isEmpty) {
                        setState(() => errorText = "Phone number required");
                        return;
                      }

                      try {
                        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: widget.email,
                          password: password1.text,
                        );

                        // Save to Firestore
                        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                          'firstName': widget.firstName,
                          'lastName': widget.lastName,
                          'username': widget.username,
                          'email': widget.email,
                          'phone': phone.text,
                          'birthday': "$selectedDay/$selectedMonth/$selectedYear",
                        });

                        print("✅ Account created!");
                        Navigator.popUntil(context, (route) => route.isFirst);

                      } on FirebaseAuthException catch (e) {
                        print("❌ Firebase Auth error: ${e.code}");

                        setState(() {
                          if (e.code == 'email-already-in-use') {
                            errorText = 'Email already in use';
                          } else if (e.code == 'invalid-email') {
                            errorText = 'Invalid email format';
                          } else if (e.code == 'weak-password') {
                            errorText = 'Password should be at least 6 characters';
                          } else {
                            errorText = 'Failed to create account. ${e.message}';
                          }
                        });
                      } catch (e) {
                        print("❌ Other error: $e");
                        setState(() {
                          errorText = 'Something went wrong. Try again.';
                        });
                      }

                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      child: Text("Create Account"),
                    ),
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildDropdown(String hint, List<String> items, String? selectedValue, void Function(String?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(hint),
        value: selectedValue,
        onChanged: onChanged,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      ),
    );
  }

  Widget _buildCardInputField(String hint, TextEditingController controller, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
