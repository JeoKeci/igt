# IGT Masraf Takip

Saha ekibinin telefondan masraf girebileceği, çıktısı muhasebe ve yönetimce
anlaşılır olan mobil uygulama.  
Flutter (Dart) · Material 3 · Supabase (Postgres + Auth + Storage) · Riverpod

---

## Sıfırdan Kurulum

### Gereksinimler

- Flutter SDK ≥ 3.22  
- Android Studio veya VS Code  
- Supabase hesabı (supabase.com)

---

### 1. Supabase Projesini Hazırla

1. [app.supabase.com](https://app.supabase.com) adresinden yeni bir proje oluştur.  
2. Sol menüden **SQL Editor** → **New Query** aç.  
3. `supabase/migrations/001_initial_schema.sql` içeriğini kopyalayıp yapıştır ve **Run** et.  
4. Aynı işlemi `supabase/migrations/002_storage_and_seed.sql` için yap.

### 2. Storage Bucket Oluştur

1. Supabase panelinde **Storage** bölümüne git.  
2. **New Bucket** → İsim: `fisler`, Public: **true** → Oluştur.  
3. `002_storage_and_seed.sql` içindeki Storage politikaları zaten uygulandıysa burada ek işlem gerekmez.

### 3. İlk Kullanıcıyı Bağla (Yönetici)

1. **Authentication → Users → Add User** ile admin kullanıcısını oluştur.  
2. Oluşturulan kullanıcının UUID'sini kopyala.  
3. SQL Editor'de `002_storage_and_seed.sql` içindeki yorum satırlarını düzenleyip çalıştır:

```sql
INSERT INTO personel (ad_soyad, eposta, rol, auth_user_id)
VALUES (
  'Ad Soyad',
  'admin@firma.com',
  'yonetici',
  '<AUTH_USER_UUID>'
);
```

### 4. Supabase RLS — Ödeme Şekilleri Politikası

Eğer ödeme şekilleri dropdown'ı boş geliyorsa şunu çalıştır:

```sql
CREATE POLICY "odeme_sekilleri_select" ON odeme_sekilleri
  FOR SELECT TO authenticated USING (true);
```

### 5. Uygulamayı Başlat

Supabase URL ve Anon Key'i [Project Settings → API](https://app.supabase.com/project/_/settings/api) sayfasından al.

**Geliştirme (debug):**
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
```

**Release APK:**
```bash
flutter build apk \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
```

> **Not:** Anahtarları kaynak koduna veya Git geçmişine ekleme.  
> `.gitignore` bu dosyayı zaten kapsıyor.  
> CI/CD ortamında secret manager veya environment variable kullan.

---

## Proje Yapısı

```
lib/
├── app.dart              # MaterialApp, AuthGate, tema
├── main.dart             # Uygulama giriş noktası
├── config/
│   └── supabase_config.dart   # --dart-define ile okunan URL/Key
├── models/               # Veri modelleri (Personel, Harcama, ...)
├── providers/            # Riverpod state yönetimi
├── screens/              # Ekranlar (Login, Harcamalar, Özet, ...)
├── services/             # Supabase servisleri (Auth, Harcama, Storage, ...)
├── utils/                # Yardımcı fonksiyonlar (formatters, validators, ...)
└── widgets/              # Ortak widget'lar

supabase/migrations/
├── 001_initial_schema.sql   # Tablolar + RLS politikaları + seed data
└── 002_storage_and_seed.sql # Storage politikaları + ilk admin kurulumu
```

---

## Tutar Giriş Formatı

Uygulama **Türkçe sayı formatını** kullanır:

| Kullanıcı girer | Veritabanına yazılan |
|----------------|----------------------|
| `1.500,75`     | `1500.75`            |
| `250,50`       | `250.50`             |
| `1500`         | `1500.00`            |

---

## Roller

| Rol        | Yetkiler                                      |
|-----------|-----------------------------------------------|
| `saha`    | Kendi harcamalarını ekler/görür               |
| `muhasebe`| Tüm harcamaları görür, raporlar alır          |
| `yonetici`| Tüm yetkiler + lookup tabloları yönetir       |

---

## Kapsam Dışı (Sonraki Fazlar)

- Excel dışa aktarımı  
- İş avansı ekranı  
- OCR ile fiş tarama  
- Rol bazlı gelişmiş panolar  
