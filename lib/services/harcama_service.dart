import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:igt_masraf_takip/models/harcama.dart';
import 'package:igt_masraf_takip/utils/constants.dart';

/// Harcamalar CRUD servisi
class HarcamaService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Supabase select sorgusu: ilişkili tabloları join eder
  static const String _selectQuery = '''
    *,
    kategoriler(ad),
    odeme_sekilleri(ad),
    projeler(ad),
    personel!harcamalar_personel_id_fkey(ad_soyad)
  ''';

  /// Belirli bir ayın harcamalarını getirir (filtreli)
  Future<List<Harcama>> getHarcamalar({
    required DateTime ay,
    String? personelId,
    String? kategoriId,
    String? projeId,
    String? odemeSekliId,
  }) async {
    // Ayın ilk ve son günü
    final ilkGun = DateTime(ay.year, ay.month, 1);
    final sonGun = DateTime(ay.year, ay.month + 1, 0);

    final ilkGunStr = ilkGun.toIso8601String().split('T').first;
    final sonGunStr = sonGun.toIso8601String().split('T').first;

    var query = _client
        .from(AppConstants.tabloHarcamalar)
        .select(_selectQuery)
        .eq('iptal', false)
        .gte('tarih', ilkGunStr)
        .lte('tarih', sonGunStr);

    // Opsiyonel filtreler
    if (personelId != null) {
      query = query.eq('personel_id', personelId);
    }
    if (kategoriId != null) {
      query = query.eq('kategori_id', kategoriId);
    }
    if (projeId != null) {
      query = query.eq('proje_id', projeId);
    }
    if (odemeSekliId != null) {
      query = query.eq('odeme_sekli_id', odemeSekliId);
    }

    final response = await query.order('tarih', ascending: false);

    return (response as List)
        .map((json) => Harcama.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Yeni harcama ekle
  Future<Harcama> addHarcama(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppConstants.tabloHarcamalar)
        .insert(data)
        .select(_selectQuery)
        .single();

    return Harcama.fromJson(response);
  }

  /// Harcama güncelle
  Future<void> updateHarcama(String id, Map<String, dynamic> data) async {
    await _client
        .from(AppConstants.tabloHarcamalar)
        .update(data)
        .eq('id', id);
  }

  /// Harcama iptal et (soft delete)
  Future<void> cancelHarcama(String id) async {
    await _client
        .from(AppConstants.tabloHarcamalar)
        .update({'iptal': true})
        .eq('id', id);
  }

  /// Tek bir harcamayı ID ile getirir
  Future<Harcama?> getHarcamaById(String id) async {
    final response = await _client
        .from(AppConstants.tabloHarcamalar)
        .select(_selectQuery)
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Harcama.fromJson(response);
  }

  /// Aylık özet: toplam tutar, KDV, matrah ve dağılımlar
  Future<Map<String, dynamic>> getOzet({required DateTime ay}) async {
    final ilkGun = DateTime(ay.year, ay.month, 1);
    final sonGun = DateTime(ay.year, ay.month + 1, 0);

    final ilkGunStr = ilkGun.toIso8601String().split('T').first;
    final sonGunStr = sonGun.toIso8601String().split('T').first;

    // Ana harcama verilerini çek
    final harcamalar = await _client
        .from(AppConstants.tabloHarcamalar)
        .select('fis_tutari, kdv, matrah, kategori_id, odeme_sekli_id, personel_id, kategoriler(ad), odeme_sekilleri(ad), personel!harcamalar_personel_id_fkey(ad_soyad)')
        .eq('iptal', false)
        .gte('tarih', ilkGunStr)
        .lte('tarih', sonGunStr);

    double toplamTutar = 0;
    double toplamKdv = 0;
    double toplamMatrah = 0;

    final Map<String, double> odemeSekliDagilimi = {};
    final Map<String, double> kategoriDagilimi = {};
    final Map<String, double> personelDagilimi = {};

    for (final row in harcamalar) {
      final tutar = (row['fis_tutari'] as num).toDouble();
      final kdv = (row['kdv'] as num).toDouble();
      final matrah = row['matrah'] != null
          ? (row['matrah'] as num).toDouble()
          : tutar - kdv;

      toplamTutar += tutar;
      toplamKdv += kdv;
      toplamMatrah += matrah;

      // Ödeme şekli dağılımı
      final odemeSekliAdi = (row['odeme_sekilleri'] is Map)
          ? (row['odeme_sekilleri'] as Map)['ad'] as String? ?? 'Bilinmiyor'
          : 'Bilinmiyor';
      odemeSekliDagilimi[odemeSekliAdi] =
          (odemeSekliDagilimi[odemeSekliAdi] ?? 0) + tutar;

      // Kategori dağılımı
      final kategoriAdi = (row['kategoriler'] is Map)
          ? (row['kategoriler'] as Map)['ad'] as String? ?? 'Bilinmiyor'
          : 'Bilinmiyor';
      kategoriDagilimi[kategoriAdi] =
          (kategoriDagilimi[kategoriAdi] ?? 0) + tutar;

      // Personel dağılımı
      final personelAdi = (row['personel'] is Map)
          ? (row['personel'] as Map)['ad_soyad'] as String? ?? 'Bilinmiyor'
          : 'Bilinmiyor';
      personelDagilimi[personelAdi] =
          (personelDagilimi[personelAdi] ?? 0) + tutar;
    }

    List<Map<String, dynamic>> toSortedList(Map<String, double> map) {
      final list = map.entries.map((e) => {'ad': e.key, 'toplam': e.value}).toList();
      list.sort((a, b) => (b['toplam'] as double).compareTo(a['toplam'] as double));
      return list;
    }

    return {
      'toplamTutar': toplamTutar,
      'toplamKdv': toplamKdv,
      'toplamMatrah': toplamMatrah,
      'harcamaSayisi': harcamalar.length,
      'odemeSekliKirilim': toSortedList(odemeSekliDagilimi),
      'kategoriKirilim': toSortedList(kategoriDagilimi),
      'kisiKirilim': toSortedList(personelDagilimi),
    };
  }
}
