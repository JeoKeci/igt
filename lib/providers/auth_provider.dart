import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:igt_masraf_takip/services/auth_service.dart';
import 'package:igt_masraf_takip/models/personel.dart';
import 'package:igt_masraf_takip/utils/constants.dart';

/// Auth servisi provider'ı
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Auth durumu stream provider'ı
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Giriş yapmış kullanıcının personel kaydını getirir
final currentPersonelProvider = FutureProvider<Personel?>((ref) async {
  // Auth durumu değiştiğinde bu provider'ın yeniden çalışmasını sağla
  ref.watch(authStateProvider);
  
  final authService = ref.watch(authServiceProvider);
  final currentUser = authService.currentUser;

  if (currentUser == null) return null;

  try {
    final response = await Supabase.instance.client
        .from(AppConstants.tabloPersonel)
        .select()
        .eq('auth_user_id', currentUser.id)
        .eq('iptal', false)
        .maybeSingle();

    if (response == null) return null;
    return Personel.fromJson(response);
  } catch (e) {
    return null;
  }
});
