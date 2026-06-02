import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:igt_masraf_takip/models/personel.dart';
import 'package:igt_masraf_takip/models/is_avansi.dart';
import 'package:igt_masraf_takip/models/maas_avansi.dart';

class PersonelService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── PERSONEL İŞLEMLERİ ───────────────────────────────────────

  /// Tüm personelleri departman bilgisiyle birlikte getirir
  Future<List<Personel>> getPersoneller() async {
    final response = await _client
        .from('personel')
        .select('*, bolumler(ad)')
        .eq('iptal', false)
        .order('ad_soyad', ascending: true);

    return (response as List)
        .map((json) => Personel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Tek bir personeli getirir
  Future<Personel> getPersonel(String id) async {
    final response = await _client
        .from('personel')
        .select('*, bolumler(ad)')
        .eq('id', id)
        .single();

    return Personel.fromJson(response);
  }

  /// Personel özlük ve maaş bilgilerini günceller
  /// İş Kuralı: İşten çıkış tarihi girilmişse aktifliği otomatik false yapar
  Future<void> updatePersonel(String id, Map<String, dynamic> data) async {
    if (data.containsKey('isten_cikis_tarihi') && data['isten_cikis_tarihi'] != null) {
      data['aktif'] = false;
    }
    await _client.from('personel').update(data).eq('id', id);
  }

  // ─── MAAŞ AVANSLARI ──────────────────────────────────────────

  /// Personelin maaş avanslarını getirir
  Future<List<MaasAvansi>> getMaasAvanslari(String personelId, {DateTime? ay}) async {
    var query = _client
        .from('maas_avanslari')
        .select('*, personel(ad_soyad)')
        .eq('personel_id', personelId)
        .eq('iptal', false);

    if (ay != null) {
      final ilk = DateTime(ay.year, ay.month, 1);
      final son = DateTime(ay.year, ay.month + 1, 0);
      query = query
          .gte('tarih', ilk.toIso8601String().split('T')[0])
          .lte('tarih', son.toIso8601String().split('T')[0]);
    }

    final response = await query.order('tarih', ascending: false);

    return (response as List)
        .map((json) => MaasAvansi.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Yeni maaş avansı ekler
  Future<MaasAvansi> addMaasAvansi({
    required String personelId,
    required double tutar,
    required DateTime tarih,
    String? aciklama,
  }) async {
    final curUser = _client.auth.currentUser;
    final data = {
      'personel_id': personelId,
      'tutar': tutar,
      'tarih': tarih.toIso8601String().split('T')[0],
      'aciklama': aciklama,
      'created_by': curUser?.id,
    };

    final response = await _client
        .from('maas_avanslari')
        .insert(data)
        .select('*, personel(ad_soyad)')
        .single();

    return MaasAvansi.fromJson(response);
  }

  /// Maaş avansını iptal eder (soft delete)
  Future<void> cancelMaasAvansi(String id) async {
    await _client.from('maas_avanslari').update({'iptal': true}).eq('id', id);
  }

  // ─── İŞ AVANSLARI ─────────────────────────────────────────────

  /// Personelin iş avanslarını getirir
  Future<List<IsAvansi>> getIsAvanslari(String personelId, {DateTime? ay}) async {
    var query = _client
        .from('is_avanslari')
        .select('*, personel(ad_soyad)')
        .eq('personel_id', personelId)
        .eq('iptal', false);

    if (ay != null) {
      final ilk = DateTime(ay.year, ay.month, 1);
      final son = DateTime(ay.year, ay.month + 1, 0);
      query = query
          .gte('tarih', ilk.toIso8601String().split('T')[0])
          .lte('tarih', son.toIso8601String().split('T')[0]);
    }

    final response = await query.order('tarih', ascending: false);

    return (response as List)
        .map((json) => IsAvansi.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Yeni iş avansı ekler
  Future<IsAvansi> addIsAvansi({
    required String personelId,
    required double tutar,
    required DateTime tarih,
    String? aciklama,
    String? projeId,
  }) async {
    final data = {
      'personel_id': personelId,
      'tutar': tutar,
      'tarih': tarih.toIso8601String().split('T')[0],
      'aciklama': aciklama,
      'proje_id': projeId,
      'tur': 'avans_verildi',
    };

    final response = await _client
        .from('is_avanslari')
        .insert(data)
        .select('*, personel(ad_soyad)')
        .single();

    return IsAvansi.fromJson(response);
  }

  /// İş avansını iptal eder (soft delete)
  Future<void> cancelIsAvansi(String id) async {
    await _client.from('is_avanslari').update({'iptal': true}).eq('id', id);
  }

  // ─── FİNANSAL BAKİYE HESAPLAMA (NAKİT İŞ AVANSI) ───────────────

  /// Personelin iş avansı hareketlerini (Alınan Avanslar ve Yapılan Harcamalar)
  /// ve net bakiyesini hesaplar.
  Future<Map<String, dynamic>> getPersonelFinansalOzet(String personelId) async {
    // 1. Alınan tüm aktif iş avanslarını getir
    final avansResponse = await _client
        .from('is_avanslari')
        .select()
        .eq('personel_id', personelId)
        .eq('iptal', false)
        .order('tarih', ascending: false);

    final avanslar = (avansResponse as List)
        .map((json) => IsAvansi.fromJson(json as Map<String, dynamic>))
        .toList();

    double toplamAlinan = 0;
    for (final a in avanslar) {
      toplamAlinan += a.tutar;
    }

    // 2. Nakit İş Avansı (kod: 'NAKIT_AVANS') ödeme türü ile girilen tüm harcamaları getir
    final harcamaResponse = await _client
        .from('harcamalar')
        .select('*, odeme_sekilleri!inner(kod), kategoriler(ad), projeler(ad)')
        .eq('personel_id', personelId)
        .eq('iptal', false)
        .eq('odeme_sekilleri.kod', 'NAKIT_AVANS')
        .order('tarih', ascending: false);

    double toplamHarcanan = 0;
    final harcamalarList = harcamaResponse as List;
    for (final h in harcamalarList) {
      toplamHarcanan += (h['fis_tutari'] as num).toDouble();
    }

    final netBakiye = toplamAlinan - toplamHarcanan;

    // 3. Kronolojik akış günlüğünü (Avanslar + Harcamalar birleşik) oluştur
    final list = <Map<String, dynamic>>[];

    for (final a in avanslar) {
      list.add({
        'tip': 'avans',
        'id': a.id,
        'tarih': a.tarih,
        'tutar': a.tutar,
        'aciklama': a.aciklama ?? 'İş Avansı Gönderildi',
        'isPozitif': true,
      });
    }

    for (final h in harcamalarList) {
      final tarih = DateTime.parse(h['tarih'] as String);
      final firma = h['firma'] as String;
      final katAdi = h['kategoriler']?['ad'] as String? ?? 'Diğer';
      list.add({
        'tip': 'harcama',
        'id': h['id'] as String,
        'tarih': tarih,
        'tutar': (h['fis_tutari'] as num).toDouble(),
        'aciklama': '$firma - $katAdi',
        'isPozitif': false,
      });
    }

    // Tarihe göre azalan sırala
    list.sort((a, b) => (b['tarih'] as DateTime).compareTo(a['tarih'] as DateTime));

    return {
      'toplamAlinan': toplamAlinan,
      'toplamHarcanan': toplamHarcanan,
      'netBakiye': netBakiye,
      'akisListesi': list,
    };
  }
}
