import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _googleInitialized = false;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized || kIsWeb) {
      return;
    }

    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});
      await _auth.signInWithPopup(provider);
      return;
    }

    await _ensureGoogleInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'Đăng nhập Google chỉ hỗ trợ trên web, Android, iOS và macOS.',
      );
    }

    final googleUser = await _googleSignIn.authenticate();
    final idToken = googleUser.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Không thể lấy thông tin xác thực từ Google.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await _auth.signInWithCredential(credential);
  }

  static Future<void> signOut() {
    if (!kIsWeb && _googleInitialized) {
      _googleSignIn.signOut();
    }
    return _auth.signOut();
  }

  static String messageFromException(Object error) {
    if (error is UnsupportedError) {
      return error.message ?? 'Tính năng này chưa được hỗ trợ trên nền tảng hiện tại.';
    }

    if (error is! FirebaseAuthException) {
      return 'Đăng nhập thất bại. Vui lòng thử lại.';
    }

    switch (error.code) {
      case 'invalid-email':
        return 'Email không đúng định dạng.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu phải có ít nhất 6 ký tự.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được bật trong Firebase Authentication.';
      case 'configuration-not-found':
        return 'Firebase Authentication của project chưa được cấu hình. Vào Firebase Console > Authentication > Get started rồi bật Email/Password và Google.';
      case 'unauthorized-domain':
        return 'Domain hiện tại chưa được cho phép trong Firebase Authentication. Hãy thêm localhost vào Authorized domains.';
      case 'network-request-failed':
        return 'Không thể kết nối tới Firebase. Hãy kiểm tra mạng và thử lại.';
      case 'popup-blocked':
        return 'Trình duyệt đã chặn cửa sổ đăng nhập Google. Hãy cho phép popup và thử lại.';
      case 'popup-closed-by-user':
        return 'Bạn đã đóng cửa sổ đăng nhập Google.';
      case 'account-exists-with-different-credential':
        return 'Email này đã tồn tại với phương thức đăng nhập khác.';
      case 'missing-google-id-token':
        return 'Không lấy được thông tin đăng nhập Google.';
      case 'too-many-requests':
        return 'Bạn thao tác quá nhiều lần. Hãy thử lại sau.';
      default:
        return error.message ?? 'Xác thực thất bại. Vui lòng thử lại.';
    }
  }
}