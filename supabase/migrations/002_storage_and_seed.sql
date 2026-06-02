-- ============================================================
-- IGT Masraf Takip — Storage Politikaları & İlk Admin Kurulumu
-- ============================================================
-- Bu dosyayı Supabase SQL Editor'de çalıştırın.
-- Migration 001_initial_schema.sql'den SONRA çalıştırılmalıdır.
-- ============================================================

-- ============================================================
-- 1. STORAGE — fisler bucket politikaları
-- ============================================================
--
-- Önce Supabase Dashboard > Storage bölümünden bucket oluşturun:
--   Bucket adı : fisler
--   Public     : true  (veya false — signed URL kullanmak isterseniz)
--
-- Bucket oluşturduktan sonra aşağıdaki SQL politikalarını çalıştırın:

-- Giriş yapmış kullanıcılar kendi klasörlerine dosya yükleyebilir
CREATE POLICY "fisler_authenticated_insert"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'fisler');

-- Giriş yapmış kullanıcılar tüm fişleri okuyabilir
CREATE POLICY "fisler_authenticated_select"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'fisler');

-- Kullanıcı yalnızca kendi yüklediği dosyayı silebilir
CREATE POLICY "fisler_owner_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'fisler' AND owner = auth.uid());


-- ============================================================
-- 2. İLK YÖNETİCİ (ADMIN) PERSONEL KURULUMU
-- ============================================================
--
-- Adımlar:
--   1) Supabase Dashboard > Authentication > Users bölümünden
--      "Add User" ile ilk kullanıcıyı oluşturun.
--      E-posta ve şifre girin, ardından oluşturulan kullanıcının
--      UUID'sini kopyalayın.
--
--   2) Aşağıdaki INSERT satırındaki:
--      - <AUTH_USER_UUID>   → kopyaladığınız UUID ile değiştirin
--      - 'Ad Soyad'        → gerçek ad soyad ile değiştirin
--      - 'admin@firma.com' → giriş e-postası ile değiştirin
--
--   3) Düzenlenmiş SQL'i çalıştırın:

-- INSERT INTO personel (ad_soyad, eposta, rol, auth_user_id)
-- VALUES (
--   'Ad Soyad',
--   'admin@firma.com',
--   'yonetici',
--   '<AUTH_USER_UUID>'   -- örn: '550e8400-e29b-41d4-a716-446655440000'
-- );


-- ============================================================
-- 3. EK PERSONEL EKLEME (Saha Ekibi)
-- ============================================================
-- Her yeni personel için aynı adımları tekrarlayın:
--   - Dashboard > Authentication > Users'tan kullanıcı oluşturun
--   - Aşağıdaki şablonu doldurup çalıştırın (rol = 'saha' veya 'muhasebe'):

-- INSERT INTO personel (ad_soyad, eposta, rol, auth_user_id)
-- VALUES (
--   'Personel Adı',
--   'personel@firma.com',
--   'saha',              -- 'saha' | 'yonetici' | 'muhasebe'
--   '<AUTH_USER_UUID>'
-- );


-- ============================================================
-- 4. DOĞRULAMA SORGUSU
-- ============================================================
-- Kurulum sonrası kontrol edin:

-- SELECT id, ad_soyad, eposta, rol, auth_user_id, aktif
-- FROM personel
-- ORDER BY created_at;
