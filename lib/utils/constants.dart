/// Uygulama genelinde kullanılan sabit değerler
class AppConstants {
  // Uygulama bilgileri
  static const String appName = 'IGT Masraf Takip';
  static const String appVersion = '1.0.0';

  // Supabase tablo adları
  static const String tabloPersonel = 'personel';
  static const String tabloHarcamalar = 'harcamalar';
  static const String tabloKategoriler = 'kategoriler';
  static const String tabloOdemeSekilleri = 'odeme_sekilleri';
  static const String tabloProjeler = 'projeler';
  static const String tabloBolumler = 'bolumler';

  // Storage bucket
  static const String bucketFisler = 'fisler';

  // Kullanıcı rolleri
  static const String rolSaha = 'saha';
  static const String rolYonetici = 'yonetici';
  static const String rolMuhasebe = 'muhasebe';

  // Ödeme şekli kodları
  static const String odemeNakit = 'nakit';
  static const String odemeKrediKarti = 'kredi_karti';
  static const String odemeBanka = 'banka';
  static const String odemeCek = 'cek';

  // Proje durumları
  static const String durumAktif = 'aktif';
  static const String durumTamamlandi = 'tamamlandi';
  static const String durumIptal = 'iptal';

  // Sayfalama
  static const int sayfaBoyutu = 50;

  // Resim boyutları (fiş fotoğrafı sıkıştırma)
  static const double maxResimGenislik = 1024;
  static const double maxResimYukseklik = 1024;
  static const int resimKalitesi = 80;
}
