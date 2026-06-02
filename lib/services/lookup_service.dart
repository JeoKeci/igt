import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:igt_masraf_takip/models/kategori.dart';
import 'package:igt_masraf_takip/models/odeme_sekli.dart';
import 'package:igt_masraf_takip/models/proje.dart';
import 'package:igt_masraf_takip/models/bolum.dart';
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
}
