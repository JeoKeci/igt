# IGT Masraf Takip — Excel Dışa Aktarım Aracı

Bu klasör, Supabase'deki harcama verilerini şirketin mevcut
masraf formu düzeninde `.xlsx` olarak dışa aktaran Python aracını içerir.

## Kurulum (tek seferlik)

```bash
cd tools
pip install -r requirements.txt
```

## Kullanım

### Canlı veriden (Supabase)

```bash
# Windows
set SUPABASE_URL=https://brawtwidyrlaedqhlfjv.supabase.co
set SUPABASE_KEY=<service_role_key>   # Dashboard > Settings > API > service_role

python igt_excel_export.py --ay 2026-05 --cikti IGT-Masraf-2026-05.xlsx
```

```bash
# Linux / macOS
export SUPABASE_URL=https://brawtwidyrlaedqhlfjv.supabase.co
export SUPABASE_KEY=<service_role_key>

python igt_excel_export.py --ay 2026-05 --cikti IGT-Masraf-2026-05.xlsx
```

> ⚠️ `SUPABASE_KEY` olarak **service_role** anahtarını kullanın (RLS'i bypass eder,
> tüm personelin harcamalarını çeker). Bu anahtarı asla repoya commit etmeyin!

### Canlı DB olmadan (mock veri — layout testi)

```bash
python igt_excel_export.py --ay 2026-05 --mock --cikti ornek.xlsx
```

## Parametreler

| Parametre  | Açıklama                              | Örnek               |
|-----------|---------------------------------------|---------------------|
| `--ay`    | Raporlanacak ay (zorunlu)             | `2026-05`           |
| `--cikti` | Çıktı dosyası (opsiyonel)             | `rapor.xlsx`        |
| `--mock`  | Örnek veri kullan, DB gerekmez        | *(flag)*            |

## Excel Çıktı Yapısı

| Sütun | İçerik                              |
|-------|-------------------------------------|
| A     | Sıra No                             |
| B     | Tarih                               |
| C     | Firma                               |
| D     | Fatura/Fiş No                       |
| E     | Açıklama                            |
| F     | Plaka/Stok Adı                      |
| G     | Harcama Şekli (kısa etiket)         |
| H     | Fiş Tutarı                          |
| I     | KDV                                 |
| J     | Matrah (=H-I, formül)               |
| K     | Harcamayı Yapan                     |
| M:N   | Özet tablo (ödeme şekli kırılımı)   |
| P:Q   | Masraf kalemleri referans listesi   |
