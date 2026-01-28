import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:test/home_screen.dart';
import 'package:test/login_screen.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  FirebaseAuth auth = FirebaseAuth.instance;

  // Signup
  void register(String email, String password, String name) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();

      Get.snackbar("Success", "Registration successful!");
      Get.to(() => LoginScreen());
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Something went wrong");
    } catch (e) {
      Get.snackbar("Error", "Unexpected error: $e");
    }
  }

  // Login
  void login(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      Get.snackbar("Success", "Login successful!");
      Get.offAll(() => HomeScreen());
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Something went wrong");
    } catch (e) {
      Get.snackbar("Error", "Unexpected error: $e");
    }
  }
}
