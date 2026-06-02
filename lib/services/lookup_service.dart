import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:igt_masraf_takip/models/kategori.dart';
import 'package:igt_masraf_takip/models/odeme_sekli.dart';
import 'package:igt_masraf_takip/models/proje.dart';
import 'package:igt_masraf_takip/models/bolum.dart';
import 'package:igt_masraf_takip/models/personel.dart';
import 'package:igt_masraf_takip/utils/constants.dart';

/// Referans tablolarına erişim servisi
class LookupService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── KATEGORİLER ───────────────────────────────────────────

  /// Aktif kategorileri getirir (no'ya göre sıralı)
  Future<List<Kategori>> getKategoriler() async {
    final response = await _client
        .from(AppConstants.tabloKategoriler)
        .select()
        .eq('iptal', false)
        .order('no', ascending: true);

    return (response as List)
        .map((json) => Kategori.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Yeni kategori ekle
  Future<Kategori> addKategori(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppConstants.tabloKategoriler)
        .insert(data)
        .select()
        .single();

    return Kategori.fromJson(response);
  }

  /// Kategori güncelle
  Future<void> updateKategori(String id, Map<String, dynamic> data) async {
    await _client
        .from(AppConstants.tabloKategoriler)
        .update(data)
        .eq('id', id);
  }

  // ─── ÖDEME ŞEKİLLERİ ──────────────────────────────────────

  /// Aktif ödeme şekillerini getirir
  Future<List<OdemeSekli>> getOdemeSekilleri() async {
    final response = await _client
        .from(AppConstants.tabloOdemeSekilleri)
        .select()
        .eq('iptal', false)
        .order('ad', ascending: true);

    return (response as List)
        .map((json) => OdemeSekli.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Yeni ödeme şekli ekle
  Future<OdemeSekli> addOdemeSekli(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppConstants.tabloOdemeSekilleri)
        .insert(data)
        .select()
        .single();

    return OdemeSekli.fromJson(response);
  }

  /// Ödeme şekli güncelle
  Future<void> updateOdemeSekli(String id, Map<String, dynamic> data) async {
    await _client
        .from(AppConstants.tabloOdemeSekilleri)
        .update(data)
        .eq('id', id);
  }

  // ─── PROJELER ──────────────────────────────────────────────

  /// Aktif projeleri getirir
  Future<List<Proje>> getProjeler() async {
    final response = await _client
        .from(AppConstants.tabloProjeler)
        .select()
        .eq('iptal', false)
        .eq('durum', AppConstants.durumAktif)
        .order('ad', ascending: true);

    return (response as List)
        .map((json) => Proje.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Tüm projeleri getirir (iptal olanlar hariç)
  Future<List<Proje>> getTumProjeler() async {
    final response = await _client
        .from(AppConstants.tabloProjeler)
        .select()
        .eq('iptal', false)
        .order('ad', ascending: true);

    return (response as List)
        .map((json) => Proje.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Yeni proje ekle
  Future<Proje> addProje(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppConstants.tabloProjeler)
        .insert(data)
        .select()
        .single();

    return Proje.fromJson(response);
  }

  /// Proje güncelle
  Future<void> updateProje(String id, Map<String, dynamic> data) async {
    await _client
        .from(AppConstants.tabloProjeler)
        .update(data)
        .eq('id', id);
  }

  // ─── BÖLÜMLER ──────────────────────────────────────────────

  /// Aktif bölümleri getirir
  Future<List<Bolum>> getBolumler() async {
    final response = await _client
        .from(AppConstants.tabloBolumler)
        .select()
        .eq('iptal', false)
        .order('ad', ascending: true);

    return (response as List)
        .map((json) => Bolum.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Yeni bölüm ekle
  Future<Bolum> addBolum(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppConstants.tabloBolumler)
        .insert(data)
        .select()
        .single();

    return Bolum.fromJson(response);
  }

  /// Bölüm güncelle
  Future<void> updateBolum(String id, Map<String, dynamic> data) async {
    await _client
        .from(AppConstants.tabloBolumler)
        .update(data)
        .eq('id', id);
  }

  // ─── PERSONELLER ───────────────────────────────────────────

  /// Personelleri getirir
  Future<List<Personel>> getPersoneller() async {
    final response = await _client
        .from(AppConstants.tabloPersonel)
        .select()
        .eq('iptal', false)
        .order('ad_soyad', ascending: true);

    return (response as List)
        .map((json) => Personel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Yeni personel ekle (ve auth user oluştur)
  Future<Personel> addPersonel({
    required String adSoyad,
    required String eposta,
    required String sifre,
    required String rol,
  }) async {
    // Auth işlemini mevcut oturumu bozmadan yapmak için geçici bir Supabase Client oluşturuyoruz.
    // Uygulama bu işlemi service_role olmadan yapabilsin diye auth.signUp kullanıyoruz,
    // ancak adminin oturumunu bozmaması için yeni bir instance şart.
    // Not: Normalde auth signup email verification isterse, kullanıcı oturum açmaz,
    // verification kapalıysa oturum açar (ama secondary client'ta açtığı için ana client'ı bozmaz).
    
    // config'i import etmeden manuel environment değişkenlerini okuyoruz
    final String url = const String.fromEnvironment('SUPABASE_URL');
    final String anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
    
    final tempClient = SupabaseClient(url, anonKey);
    
    try {
      final authResponse = await tempClient.auth.signUp(
        email: eposta.trim(),
        password: sifre,
      );

      final newUserId = authResponse.user?.id;
      if (newUserId == null) throw Exception("Kullanıcı oluşturulamadı (User ID boş geldi)");

      final data = {
        'auth_user_id': newUserId,
        'ad_soyad': adSoyad.trim(),
        'eposta': eposta.trim(),
        'rol': rol,
        'aktif': true,
      };

      // Ana client üzerinden personel tablosuna ekliyoruz
      final response = await _client
          .from(AppConstants.tabloPersonel)
          .insert(data)
          .select()
          .single();

      return Personel.fromJson(response);
    } finally {
      tempClient.dispose();
    }
  }

  /// Personel güncelle
  Future<void> updatePersonel(String id, Map<String, dynamic> data) async {
    await _client
        .from(AppConstants.tabloPersonel)
        .update(data)
        .eq('id', id);
  }
}
