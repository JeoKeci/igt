import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:igt_masraf_takip/utils/constants.dart';

/// Dosya yükleme servisi (fiş fotoğrafları)
class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  /// Fiş fotoğrafını Supabase Storage'a yükler
  ///
  /// [personelId] — fotoğrafı yükleyen personel ID'si (klasör yapısı için)
  /// [filePath] — cihazda bulunan dosyanın yolu
  ///
  /// Başarılı olursa public URL döner, hata durumunda null döner.
  Future<String?> uploadFisFotografi(
    String personelId,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      // Dosya uzantısını belirle
      final ext = filePath.contains('.') ? '.${filePath.split('.').last.toLowerCase()}' : '';

      // Benzersiz dosya adı oluştur
      final fileName = '${_uuid.v4()}$ext';
      final storagePath = '$personelId/$fileName';

      // Supabase Storage'a yükle
      await _client.storage
          .from(AppConstants.bucketFisler)
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Public URL'i döndür
      final publicUrl = _client.storage
          .from(AppConstants.bucketFisler)
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      // Hata durumunda null döner, çağıran taraf hata yönetimini yapar
      return null;
    }
  }

  /// Storage'daki dosyanın public URL'ini döndürür
  String? getPublicUrl(String path) {
    try {
      if (path.isEmpty) return null;
      return _client.storage
          .from(AppConstants.bucketFisler)
          .getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  /// Storage'dan dosya siler
  Future<bool> deleteFile(String path) async {
    try {
      if (path.isEmpty) return false;
      await _client.storage
          .from(AppConstants.bucketFisler)
          .remove([path]);
      return true;
    } catch (e) {
      return false;
    }
  }
}
