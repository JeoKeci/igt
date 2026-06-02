import 'package:supabase_flutter/supabase_flutter.dart';

/// Kimlik doğrulama servisi
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// E-posta ve şifre ile giriş
  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return response;
  }

  /// Çıkış yap
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Mevcut kullanıcı
  User? get currentUser => _client.auth.currentUser;

  /// Auth durumu değişiklikleri stream'i
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Kullanıcı oturumu var mı?
  bool get isLoggedIn => _client.auth.currentUser != null;

  /// Mevcut oturum
  Session? get currentSession => _client.auth.currentSession;
}
