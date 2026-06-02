-- ============================================================
-- IGT Masraf Takip — Veritabanı Şeması
-- ============================================================
-- Tüm tablolarda: id uuid pk, created_at timestamptz
-- Soft delete: iptal bool default false (fiziksel silme yok)
-- ============================================================

-- =========================
-- 1. PERSONEL
-- =========================
CREATE TABLE IF NOT EXISTS personel (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_soyad text NOT NULL,
  eposta text NOT NULL UNIQUE,
  rol text NOT NULL DEFAULT 'saha' CHECK (rol IN ('saha', 'yonetici', 'muhasebe')),
  aktif bool NOT NULL DEFAULT true,
  auth_user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
  iptal bool NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_personel_auth ON personel(auth_user_id);
CREATE INDEX idx_personel_rol ON personel(rol);

-- =========================
-- 2. BÖLÜMLER
-- =========================
CREATE TABLE IF NOT EXISTS bolumler (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ad text NOT NULL UNIQUE,
  aktif bool NOT NULL DEFAULT true,
  iptal bool NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- =========================
-- 3. PROJELER
-- =========================
CREATE TABLE IF NOT EXISTS projeler (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ad text NOT NULL,
  bolum_id uuid REFERENCES bolumler(id),
  lokasyon text,
  baslangic_tarihi date,
  bitis_tarihi date,
  durum text NOT NULL DEFAULT 'aktif' CHECK (durum IN ('aktif', 'tamamlandi')),
  aktif bool NOT NULL DEFAULT true,
  iptal bool NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_projeler_bolum ON projeler(bolum_id);
CREATE INDEX idx_projeler_durum ON projeler(durum);

-- =========================
-- 4. KATEGORİLER
-- =========================
CREATE TABLE IF NOT EXISTS kategoriler (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  no int NOT NULL,
  ad text NOT NULL,
  bolum_id uuid REFERENCES bolumler(id),  -- null = tüm bölümler için geçerli
  aktif bool NOT NULL DEFAULT true,
  iptal bool NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_kategoriler_bolum ON kategoriler(bolum_id);

-- =========================
-- 5. ÖDEME ŞEKİLLERİ
-- =========================
CREATE TABLE IF NOT EXISTS odeme_sekilleri (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kod text NOT NULL UNIQUE,
  ad text NOT NULL,
  iptal bool NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- =========================
-- 6. HARCAMALAR (Ana tablo)
-- =========================
CREATE TABLE IF NOT EXISTS harcamalar (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tarih date NOT NULL DEFAULT CURRENT_DATE,
  firma text NOT NULL,
  fis_no text,
  aciklama text,
  plaka_stok text,
  kategori_id uuid NOT NULL REFERENCES kategoriler(id),
  odeme_sekli_id uuid NOT NULL REFERENCES odeme_sekilleri(id),
  proje_id uuid REFERENCES projeler(id),
  personel_id uuid NOT NULL REFERENCES personel(id),
  fis_tutari numeric(12,2) NOT NULL CHECK (fis_tutari >= 0),
  kdv numeric(12,2) NOT NULL DEFAULT 0 CHECK (kdv >= 0),
  matrah numeric(12,2) GENERATED ALWAYS AS (fis_tutari - kdv) STORED,
  belge_url text,
  created_by uuid NOT NULL REFERENCES personel(id),
  iptal bool NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT kdv_lte_tutar CHECK (kdv <= fis_tutari)
);

CREATE INDEX idx_harcamalar_tarih ON harcamalar(tarih);
CREATE INDEX idx_harcamalar_personel ON harcamalar(personel_id);
CREATE INDEX idx_harcamalar_kategori ON harcamalar(kategori_id);
CREATE INDEX idx_harcamalar_odeme ON harcamalar(odeme_sekli_id);
CREATE INDEX idx_harcamalar_proje ON harcamalar(proje_id);
CREATE INDEX idx_harcamalar_iptal ON harcamalar(iptal);

-- =========================
-- 7. İŞ AVANSLARI (v1: tablo kurulur, ekranı FAZ 2)
-- =========================
CREATE TABLE IF NOT EXISTS is_avanslari (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tarih date NOT NULL DEFAULT CURRENT_DATE,
  personel_id uuid NOT NULL REFERENCES personel(id),
  tutar numeric(12,2) NOT NULL CHECK (tutar >= 0),
  tur text NOT NULL CHECK (tur IN ('avans_verildi', 'onceki_aydan_devir')),
  aciklama text,
  iptal bool NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_is_avanslari_personel ON is_avanslari(personel_id);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- ---- PERSONEL ----
ALTER TABLE personel ENABLE ROW LEVEL SECURITY;

CREATE POLICY "personel_select" ON personel
  FOR SELECT TO authenticated
  USING (true);  -- herkes personel listesini görebilir

CREATE POLICY "personel_insert" ON personel
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM personel p
      WHERE p.auth_user_id = (SELECT auth.uid())
      AND p.rol IN ('yonetici', 'muhasebe')
    )
  );

CREATE POLICY "personel_update" ON personel
  FOR UPDATE TO authenticated
  USING (
    auth_user_id = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1 FROM personel p
      WHERE p.auth_user_id = (SELECT auth.uid())
      AND p.rol IN ('yonetici', 'muhasebe')
    )
  );

-- ---- BÖLÜMLER ----
ALTER TABLE bolumler ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bolumler_select" ON bolumler
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "bolumler_insert" ON bolumler
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM personel
      WHERE auth_user_id = (SELECT auth.uid())
      AND rol IN ('yonetici', 'muhasebe')
    )
  );

CREATE POLICY "bolumler_update" ON bolumler
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM personel
      WHERE auth_user_id = (SELECT auth.uid())
      AND rol IN ('yonetici', 'muhasebe')
    )
  );

-- ---- PROJELER ----
ALTER TABLE projeler ENABLE ROW LEVEL SECURITY;

CREATE POLICY "projeler_select" ON projeler
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "projeler_insert" ON projeler
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM personel
      WHERE auth_user_id = (SELECT auth.uid())
      AND rol IN ('yonetici', 'muhasebe')
    )
  );

CREATE POLICY "projeler_update" ON projeler
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM personel
      WHERE auth_user_id = (SELECT auth.uid())
      AND rol IN ('yonetici', 'muhasebe')
    )
  );

-- ---- KATEGORİLER ----
ALTER TABLE kategoriler ENABLE ROW LEVEL SECURITY;

CREATE POLICY "kategoriler_select" ON kategoriler
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "kategoriler_insert" ON kategoriler
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM personel
      WHERE auth_user_id = (SELECT auth.uid())
      AND rol IN ('yonetici', 'muhasebe')
    )
  );

CREATE POLICY "kategoriler_update" ON kategoriler
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM personel
      WHERE auth_user_id = (SELECT auth.uid())
      AND rol IN ('yonetici', 'muhasebe')
    )
  );

-- ---- ÖDEME ŞEKİLLERİ ----
ALTER TABLE odeme_sekilleri ENABLE ROW LEVEL SECURITY;

CREATE POLICY "odeme_sekilleri_select" ON odeme_sekilleri
  FOR SELECT TO authenticated
  USING (true);

-- ---- HARCAMALAR ----
ALTER TABLE harcamalar ENABLE ROW LEVEL SECURITY;

CREATE POLICY "harcamalar_insert" ON harcamalar
  FOR INSERT TO authenticated
  WITH CHECK (
    personel_id IN (
      SELECT id FROM personel WHERE auth_user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "harcamalar_select" ON harcamalar
  FOR SELECT TO authenticated
  USING (
    personel_id IN (
      SELECT id FROM personel WHERE auth_user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM personel
      WHERE auth_user_id = (SELECT auth.uid())
      AND rol IN ('yonetici', 'muhasebe')
    )
  );

CREATE POLICY "harcamalar_update" ON harcamalar
  FOR UPDATE TO authenticated
  USING (
    personel_id IN (
      SELECT id FROM personel WHERE auth_user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    personel_id IN (
      SELECT id FROM personel WHERE auth_user_id = (SELECT auth.uid())
    )
  );

-- ---- İŞ AVANSLARI ----
ALTER TABLE is_avanslari ENABLE ROW LEVEL SECURITY;

CREATE POLICY "is_avanslari_select" ON is_avanslari
  FOR SELECT TO authenticated
  USING (
    personel_id IN (
      SELECT id FROM personel WHERE auth_user_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM personel
      WHERE auth_user_id = (SELECT auth.uid())
      AND rol IN ('yonetici', 'muhasebe')
    )
  );

-- ============================================================
-- STORAGE: Fiş fotoğrafları bucket'ı
-- ============================================================
-- NOT: Bu kısmı Supabase Dashboard > Storage'dan oluşturun:
--   Bucket adı: fisler
--   Public: true (veya signed URL kullanılacaksa false)
--
-- Storage RLS politikaları Dashboard'dan eklenecek:
-- INSERT: authenticated kullanıcılar yükleyebilir
-- SELECT: authenticated kullanıcılar okuyabilir

-- ============================================================
-- SEED DATA
-- ============================================================

-- Ödeme Şekilleri
INSERT INTO odeme_sekilleri (kod, ad) VALUES
  ('NAKIT_AVANS', 'Nakit İş Avansı'),
  ('IGT_KK', 'İGT Kredi Kartı (YKB Gold)'),
  ('PERSONEL_NAKIT', 'Personel Nakit Harcama'),
  ('PERSONEL_KK', 'Personel Şahsi Kredi Kartı');

-- Bölümler
INSERT INTO bolumler (ad) VALUES
  ('Geosentetikler'),
  ('İnşaat | Madencilik');

-- Kategoriler — Genel (bolum_id = null, tüm bölümler)
INSERT INTO kategoriler (no, ad, bolum_id) VALUES
  (1,  'Fatura', NULL),
  (2,  'Yemek', NULL),
  (3,  'Market', NULL),
  (4,  'Yakıt', NULL),
  (5,  'Araç Bakım', NULL),
  (6,  'Araç Yıkama', NULL),
  (7,  'Araç Kira', NULL),
  (8,  'Sarf Malzeme', NULL),
  (9,  'İş Kıyafeti', NULL),
  (10, 'Kırtasiye', NULL),
  (11, 'Kargo', NULL),
  (12, 'Ekipman', NULL),
  (13, 'Nakliye', NULL),
  (14, 'Makine Tamir', NULL),
  (15, 'Taşeron Hizmeti', NULL),
  (16, 'Kiralık Ekipman', NULL),
  (17, 'Ulaşım', NULL),
  (18, 'Konaklama', NULL),
  (19, 'Otopark', NULL),
  (20, 'Alınan Emtia', NULL),
  (21, 'Sağlık', NULL),
  (22, 'Temsili Ağırlama', NULL);

-- Kategoriler — İnşaat | Madencilik bölümüne özel
INSERT INTO kategoriler (no, ad, bolum_id) VALUES
  (23, 'Sondaj Yakıt', (SELECT id FROM bolumler WHERE ad = 'İnşaat | Madencilik')),
  (24, 'Sondaj Su', (SELECT id FROM bolumler WHERE ad = 'İnşaat | Madencilik'));
