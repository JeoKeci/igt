import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:igt_masraf_takip/utils/constants.dart';

/// Ödeme şekli kodu → Excel özet tablo satır etiketi
const _odemeSatir = {
  'NAKIT_AVANS': 'İGT İş Avansı İle Nakit Harcama',
  'IGT_KK': 'İGT Kredi Kartı İle Harcama (YKB Gold Kart)',
  'PERSONEL_NAKIT': 'Personel Nakit Harcama',
  'PERSONEL_KK': 'Personel Şahsi Kredi Kartı İle Harcama',
};

/// Ana tablodaki "H. ŞEKLİ" sütununa yazılacak kısa etiket
const _odemeKisa = {
  'NAKIT_AVANS': 'Nakit Avans',
  'IGT_KK': 'İGT KK',
  'PERSONEL_NAKIT': 'P. Nakit',
  'PERSONEL_KK': 'P. Şahsi KK',
};

const _trAylar = [
  '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
];

class ExcelExportService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Stil yardımcıları ─────────────────────────────────────────────

  CellStyle _baslikStil() => CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('#1F3864'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  CellStyle _ozetBaslikStil() => CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('#305496'),
    horizontalAlign: HorizontalAlign.Center,
  );

  CellStyle _ozetSatirStil({bool bold = false}) => CellStyle(
    bold: bold,
    backgroundColorHex: ExcelColor.fromHexString('#D9E1F2'),
  );

  CellStyle _vurguStil() => CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#FFF2CC'),
  );

  // Para formatı için sadece bold kullanıyoruz (excel 4.x'te custom format ayrı API)
  CellStyle _paraStil({bool bold = false}) => CellStyle(bold: bold);

  // ── Veri çekme ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _getHarcamalar(DateTime ay) async {
    final ilk = DateTime(ay.year, ay.month, 1);
    final son = DateTime(ay.year, ay.month + 1, 0);
    final ilkStr = DateFormat('yyyy-MM-dd').format(ilk);
    final sonStr = DateFormat('yyyy-MM-dd').format(son);

    final response = await _client
        .from(AppConstants.tabloHarcamalar)
        .select(
          'tarih, firma, fis_no, aciklama, plaka_stok, fis_tutari, kdv,'
          'kategoriler(no, ad),'
          'odeme_sekilleri(kod, ad),'
          'projeler(ad),'
          'personel!harcamalar_personel_id_fkey(ad_soyad)',
        )
        .eq('iptal', false)
        .gte('tarih', ilkStr)
        .lte('tarih', sonStr)
        .order('tarih');

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> _getAvanslar(DateTime ay) async {
    final ilk = DateTime(ay.year, ay.month, 1);
    final son = DateTime(ay.year, ay.month + 1, 0);
    final ilkStr = DateFormat('yyyy-MM-dd').format(ilk);
    final sonStr = DateFormat('yyyy-MM-dd').format(son);

    try {
      final response = await _client
          .from('is_avanslari')
          .select('tarih, tutar, tur, aciklama, personel!is_avanslari_personel_id_fkey(ad_soyad)')
          .eq('iptal', false)
          .gte('tarih', ilkStr)
          .lte('tarih', sonStr)
          .order('tarih');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getKategoriler() async {
    final response = await _client
        .from(AppConstants.tabloKategoriler)
        .select('no, ad')
        .eq('iptal', false)
        .order('no');
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ── Yardımcı: iç içe map'ten güvenli okuma ───────────────────────

  dynamic _g(Map<String, dynamic> row, String key, [String? subKey]) {
    final val = row[key];
    if (subKey == null) return val;
    if (val is Map<String, dynamic>) return val[subKey];
    return null;
  }

  // ── Hücre ayarla yardımcısı ──────────────────────────────────────

  void _set(Sheet sheet, int col, int row, CellValue val, {CellStyle? style}) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = val;
    if (style != null) cell.cellStyle = style;
  }

  // ── Excel üretimi ─────────────────────────────────────────────────

  Future<String> exportAylikRapor(DateTime ay) async {
    final harcamalar = await _getHarcamalar(ay);
    final avanslar = await _getAvanslar(ay);
    final kategoriler = await _getKategoriler();

    final excel = Excel.createExcel();
    final ayAdi = _trAylar[ay.month];
    final sheet = excel[ayAdi];

    // Varsayılan Sheet1'i sil
    excel.delete('Sheet1');

    // ── Ana Tablo Başlıkları (satır 0, sütun 0-10) ───────────────
    final basliklar = [
      '', 'TARİH', 'FİRMA', 'FATURA/FİŞ NO.', 'AÇIKLAMA',
      'PLAKA NO/STOK ADI', 'H. ŞEKLİ', 'FİŞ TUTARI', 'KDV', 'MATRAH', 'H. YAPAN'
    ];
    for (var i = 0; i < basliklar.length; i++) {
      _set(sheet, i, 0, TextCellValue(basliklar[i]), style: _baslikStil());
    }

    // ── Veri Satırları ────────────────────────────────────────────
    var r = 1;
    for (var idx = 0; idx < harcamalar.length; idx++) {
      final h = harcamalar[idx];
      final kod = (_g(h, 'odeme_sekilleri', 'kod') as String?) ?? '';
      final tutar = (h['fis_tutari'] as num?)?.toDouble() ?? 0.0;
      final kdv = (h['kdv'] as num?)?.toDouble() ?? 0.0;
      final matrah = tutar - kdv;
      final tarihStr = (h['tarih'] as String?) ?? '';
      final tarih = tarihStr.isNotEmpty ? DateTime.tryParse(tarihStr) : null;
      final tarihFormatli = tarih != null
          ? DateFormat('dd.MM.yyyy').format(tarih)
          : tarihStr;

      _set(sheet, 0, r, IntCellValue(idx + 1));
      _set(sheet, 1, r, TextCellValue(tarihFormatli));
      _set(sheet, 2, r, TextCellValue((_g(h, 'firma') as String?) ?? ''));
      _set(sheet, 3, r, TextCellValue((_g(h, 'fis_no') as String?) ?? ''));
      _set(sheet, 4, r, TextCellValue((_g(h, 'aciklama') as String?) ?? ''));
      _set(sheet, 5, r, TextCellValue((_g(h, 'plaka_stok') as String?) ?? ''));
      _set(sheet, 6, r, TextCellValue(_odemeKisa[kod] ?? kod));
      _set(sheet, 7, r, DoubleCellValue(tutar), style: _paraStil());
      _set(sheet, 8, r, DoubleCellValue(kdv), style: _paraStil());
      _set(sheet, 9, r, DoubleCellValue(matrah), style: _paraStil());
      _set(sheet, 10, r, TextCellValue((_g(h, 'personel', 'ad_soyad') as String?) ?? ''));

      r++;
    }

    // ── TOPLAM Satırı ─────────────────────────────────────────────
    final toplamSatir = r + 1;
    if (harcamalar.isNotEmpty) {
      double toplamTutar = 0, toplamKdv = 0, toplamMatrah = 0;
      for (final h in harcamalar) {
        final t = (h['fis_tutari'] as num?)?.toDouble() ?? 0.0;
        final k = (h['kdv'] as num?)?.toDouble() ?? 0.0;
        toplamTutar += t;
        toplamKdv += k;
        toplamMatrah += (t - k);
      }
      _set(sheet, 6, toplamSatir, TextCellValue('TOPLAM'), style: CellStyle(bold: true));
      _set(sheet, 7, toplamSatir, DoubleCellValue(toplamTutar), style: _paraStil(bold: true));
      _set(sheet, 8, toplamSatir, DoubleCellValue(toplamKdv), style: _paraStil(bold: true));
      _set(sheet, 9, toplamSatir, DoubleCellValue(toplamMatrah), style: _paraStil(bold: true));
    }

    // ── ÖZET TABLO (sütun 12-13 = M:N) ──────────────────────────
    void mn(int row, String label, {dynamic val, bool bold = false, CellStyle? fillStyle}) {
      final mc = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row));
      mc.value = TextCellValue(label);
      mc.cellStyle = fillStyle ?? CellStyle(bold: bold);

      if (val != null) {
        final nc = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row));
        if (val is double) {
          nc.value = DoubleCellValue(val);
          nc.cellStyle = _paraStil(bold: bold);
        } else {
          nc.value = TextCellValue(val.toString());
        }
      }
    }

    // Özet başlık
    _set(sheet, 12, 0, TextCellValue('ÖZET TABLO'), style: _ozetBaslikStil());

    // Ay
    _set(sheet, 12, 1, TextCellValue('AY'), style: CellStyle(bold: true));
    _set(sheet, 13, 1, TextCellValue('${_trAylar[ay.month]} ${ay.year}'));

    // Personel listesi
    final personeller = harcamalar
        .map((h) => (_g(h, 'personel', 'ad_soyad') as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()..sort();
    mn(2, 'Harcamayı Yapan', val: personeller.join(', '));

    // Toplam değerler
    double topT = 0, topK = 0, topM = 0;
    final Map<String, double> odemeDagilim = {};
    for (final h in harcamalar) {
      final t = (h['fis_tutari'] as num?)?.toDouble() ?? 0.0;
      final k = (h['kdv'] as num?)?.toDouble() ?? 0.0;
      topT += t;
      topK += k;
      topM += (t - k);
      final kod = (_g(h, 'odeme_sekilleri', 'kod') as String?) ?? '';
      odemeDagilim[kod] = (odemeDagilim[kod] ?? 0) + t;
    }
    mn(3, 'MATRAH', val: topM, fillStyle: _ozetSatirStil());
    mn(4, 'KDV', val: topK, fillStyle: _ozetSatirStil());
    mn(5, 'TOPLAM', val: topT, fillStyle: _vurguStil(), bold: true);

    // Avans tablosu
    _set(sheet, 12, 8, TextCellValue('NAKİT/HAVALE/EFT İŞ AVANSLARI'), style: _ozetBaslikStil());
    _set(sheet, 12, 9, TextCellValue('Tarih'), style: CellStyle(bold: true));
    _set(sheet, 13, 9, TextCellValue('Tutar (TL)'), style: CellStyle(bold: true));

    var ar = 10;
    double toplamAvans = 0;
    for (final a in avanslar.where((a) => a['tur'] == 'avans_verildi')) {
      final tarihStr = (a['tarih'] as String?) ?? '';
      final tarih = tarihStr.isNotEmpty ? DateTime.tryParse(tarihStr) : null;
      _set(sheet, 12, ar, TextCellValue(
        tarih != null ? DateFormat('dd.MM.yyyy').format(tarih) : tarihStr,
      ));
      final avTutar = (a['tutar'] as num?)?.toDouble() ?? 0.0;
      _set(sheet, 13, ar, DoubleCellValue(avTutar), style: _paraStil());
      toplamAvans += avTutar;
      ar++;
    }

    // Özet alt blok
    mn(30, 'TOPLAM NAKİT İŞ AVANSLARI', val: toplamAvans, fillStyle: _ozetSatirStil());
    mn(31, _odemeSatir['NAKIT_AVANS']!, val: odemeDagilim['NAKIT_AVANS'] ?? 0.0);
    mn(32, _odemeSatir['IGT_KK']!, val: odemeDagilim['IGT_KK'] ?? 0.0);
    mn(33, _odemeSatir['PERSONEL_NAKIT']!, val: odemeDagilim['PERSONEL_NAKIT'] ?? 0.0);
    mn(34, _odemeSatir['PERSONEL_KK']!, val: odemeDagilim['PERSONEL_KK'] ?? 0.0);

    // Taşeron blok
    _set(sheet, 12, 38, TextCellValue('TAŞERON'), style: _ozetBaslikStil());
    mn(39, 'İGT KREDİ KARTI');
    mn(40, 'Nakit/Şahsi Kredi Kartı');

    // ── Masraf Kalemleri Listesi (sütun 15-16 = P:Q) ─────────────
    _set(sheet, 15, 0, TextCellValue('NO'), style: _baslikStil());
    _set(sheet, 16, 0, TextCellValue('MASRAF KALEMLERİ'), style: _baslikStil());

    for (var i = 0; i < kategoriler.length; i++) {
      final k = kategoriler[i];
      _set(sheet, 15, i + 1, IntCellValue((k['no'] as num).toInt()));
      _set(sheet, 16, i + 1, TextCellValue('*${k['ad']}'));
    }

    // ── Sütun genişlikleri ────────────────────────────────────────
    final genislikler = [5, 12, 22, 14, 26, 18, 13, 13, 11, 13, 16, 2, 34, 14, 2, 5, 22];
    for (var i = 0; i < genislikler.length; i++) {
      sheet.setColumnWidth(i, genislikler[i].toDouble());
    }

    // ── Dosyaya kaydet ────────────────────────────────────────────
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Excel encode başarısız');

    final dir = await getTemporaryDirectory();
    final ayStr = DateFormat('yyyy-MM').format(ay);
    final filePath = '${dir.path}/IGT-Masraf-$ayStr.xlsx';
    await File(filePath).writeAsBytes(bytes);

    debugPrint('Excel oluşturuldu: $filePath');
    return filePath;
  }

  /// Excel üret ve paylaşım diyaloğunu aç (WhatsApp, Mail, Drive vb.)
  Future<void> exportVePaylas(DateTime ay) async {
    final filePath = await exportAylikRapor(ay);
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'IGT Masraf Raporu — ${_trAylar[ay.month]} ${ay.year}',
    );
  }
}
