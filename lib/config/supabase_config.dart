/// Supabase bağlantı ayarları.
///
/// Değerler kaynak koda gömülü değildir; build/run sırasında
/// --dart-define ile sağlanır. Örnek:
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
///
/// Anahtarlar .env veya CI secret olarak tutulmalı, repoya
/// commit edilmemelidir.
class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Çalışma zamanında eksik config'i yakalamak için doğrulama.
  static void validate() {
    if (url.isEmpty) {
      throw StateError(
        'SUPABASE_URL tanımlı değil.\n'
        'Uygulamayı şu şekilde başlatın:\n'
        '  flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>',
      );
    }
    if (anonKey.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY tanımlı değil.\n'
        'Uygulamayı şu şekilde başlatın:\n'
        '  flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>',
      );
    }
  }
}
