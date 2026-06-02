import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/harcama_provider.dart';
import '../providers/lookup_provider.dart';
import '../providers/ozet_provider.dart';

import '../services/storage_service.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';

class HarcamaEkleScreen extends ConsumerStatefulWidget {
  const HarcamaEkleScreen({super.key});

  @override
  ConsumerState<HarcamaEkleScreen> createState() => _HarcamaEkleScreenState();
}

class _HarcamaEkleScreenState extends ConsumerState<HarcamaEkleScreen> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime _tarih = DateTime.now();
  final _firmaController = TextEditingController();
  final _fisNoController = TextEditingController();
  final _aciklamaController = TextEditingController();
  String? _selectedKategoriId;
  String? _selectedOdemeSekliId;
  String? _selectedProjeId;
  String _harcamaTipi = 'firma';
  final _plakaStokController = TextEditingController();
  final _tutarController = TextEditingController();
  final _kdvController = TextEditingController(text: '0');
  
  File? _imageFile;
  bool _isLoading = false;

  // Türkçe formatlı girişten matrah hesapla: sayiParse kullanarak binlik noktaları
  // binlik ayıraç olarak değerlendirip doğru çeviri yapar.
  double get _matrah {
    final tutar = sayiParse(_tutarController.text) ?? 0.0;
    final kdv = sayiParse(_kdvController.text) ?? 0.0;
    final result = tutar - kdv;
    return result > 0 ? result : 0.0;
  }

  @override
  void initState() {
    super.initState();
    _tutarController.addListener(() => setState(() {}));
    _kdvController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firmaController.dispose();
    _fisNoController.dispose();
    _aciklamaController.dispose();
    _plakaStokController.dispose();
    _tutarController.dispose();
    _kdvController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _tarih) {
      setState(() {
        _tarih = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final currentPersonel = ref.read(currentPersonelProvider).value;
    if (currentPersonel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi alınamadı.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? belgeUrl;
      if (_imageFile != null) {
        final storageService = StorageService();
        belgeUrl = await storageService.uploadFisFotografi(
          currentPersonel.id,
          _imageFile!.path,
        );
      }

      // sayiParse: "1.500,75" → 1500.75 (binlik nokta + ondalık virgül)
      final tutar = sayiParse(_tutarController.text) ?? 0.0;
      final kdv = sayiParse(_kdvController.text) ?? 0.0;

      final data = {
        'tarih': DateFormat('yyyy-MM-dd').format(_tarih),
        'firma': _firmaController.text,
        'fis_no': _fisNoController.text.isEmpty ? null : _fisNoController.text,
        'aciklama': _aciklamaController.text.isEmpty ? null : _aciklamaController.text,
        'kategori_id': _selectedKategoriId,
        'odeme_sekli_id': _selectedOdemeSekliId,
        'proje_id': _selectedProjeId,
        'plaka_stok': _plakaStokController.text.isEmpty ? null : _plakaStokController.text,
        'harcama_tipi': _harcamaTipi,
        'personel_id': currentPersonel.id,
        'created_by': currentPersonel.id,   // NOT NULL — zorunlu
        'fis_tutari': tutar,
        'kdv': kdv,
        'belge_url': belgeUrl,
      };

      final service = ref.read(harcamaServiceProvider);
      await service.addHarcama(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Harcama eklendi')),
        );
        ref.invalidate(harcamalarProvider);
        ref.invalidate(ozetProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hata'),
            content: Text('Harcama kaydedilirken bir hata oluştu:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kategorilerState = ref.watch(kategorilerProvider);
    final odemeSekilleriState = ref.watch(odemeSekilleriProvider);
    final projelerState = ref.watch(projelerProvider);

    final kategoriler = kategorilerState.value ?? [];
    final odemeSekilleri = odemeSekilleriState.value ?? [];
    final projeler = projelerState.value ?? [];

    final hasError = kategorilerState.hasError || odemeSekilleriState.hasError || projelerState.hasError;
    final errorMsg = [
      if (kategorilerState.hasError) 'Kategori Hatası: ${kategorilerState.error}',
      if (odemeSekilleriState.hasError) 'Ödeme Şekli Hatası: ${odemeSekilleriState.error}',
      if (projelerState.hasError) 'Proje Hatası: ${projelerState.error}'
    ].join('\n');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcama Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasError) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  child: Text(errorMsg, style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 16),
              ],
              // Harcama Tipi Seçimi
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'firma',
                    label: Text('Firma Gideri'),
                    icon: Icon(Icons.business),
                  ),
                  ButtonSegment<String>(
                    value: 'sahsi',
                    label: Text('Şahsi Harcama'),
                    icon: Icon(Icons.person),
                  ),
                ],
                selected: {_harcamaTipi},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _harcamaTipi = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                _harcamaTipi == 'sahsi'
                    ? 'Şahsi: firma kartı/avansından yapılan kişisel harcama; personelin hesabına borç yazılır.'
                    : 'Firma Gideri: Proje, araç veya genel şirket gideri.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // 1. Tarih
              GestureDetector(
                onTap: _isLoading ? null : _selectDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Tarih',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(text: tarihFormat(_tarih)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 2. Firma
              TextFormField(
                controller: _firmaController,
                decoration: const InputDecoration(labelText: 'Firma'),
                validator: zorunluAlan,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              
              // 3. Fiş No
              TextFormField(
                controller: _fisNoController,
                decoration: const InputDecoration(labelText: 'Fiş/Fatura No (Opsiyonel)'),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              
              // 4. Açıklama
              TextFormField(
                controller: _aciklamaController,
                decoration: const InputDecoration(labelText: 'Açıklama (Opsiyonel)'),
                maxLines: 3,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              
              // 5. Kategori
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Kategori'),
                initialValue: _selectedKategoriId,
                items: kategoriler.map((k) => DropdownMenuItem(value: k.id, child: Text(k.ad))).toList(),
                onChanged: _isLoading ? null : (v) => setState(() => _selectedKategoriId = v),
                validator: zorunluAlan,
              ),
              const SizedBox(height: 16),
              
              // 6. Ödeme Şekli
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Ödeme Şekli'),
                initialValue: _selectedOdemeSekliId,
                items: odemeSekilleri.map((o) => DropdownMenuItem(value: o.id, child: Text(o.ad))).toList(),
                onChanged: _isLoading ? null : (v) => setState(() => _selectedOdemeSekliId = v),
                validator: zorunluAlan,
              ),
              const SizedBox(height: 16),
              
              // 7. Proje
              DropdownButtonFormField<String?>(
                decoration: const InputDecoration(labelText: 'Proje (Opsiyonel)'),
                initialValue: _selectedProjeId,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Seçilmedi')),
                  ...projeler.map((p) => DropdownMenuItem(value: p.id, child: Text(p.ad))),
                ],
                onChanged: _isLoading ? null : (v) => setState(() => _selectedProjeId = v),
              ),
              const SizedBox(height: 16),
              
              // 8. Plaka/Stok
              TextFormField(
                controller: _plakaStokController,
                decoration: const InputDecoration(labelText: 'Plaka/Stok (Opsiyonel)'),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              
              // Finansal Bölüm
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    // 9. Fiş Tutarı
                    TextFormField(
                      controller: _tutarController,
                      decoration: const InputDecoration(
                        labelText: 'Fiş Tutarı (TL)',
                        prefixIcon: Icon(Icons.attach_money),
                        hintText: 'örn: 1.500,75',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      validator: tutarValidator,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    
                    // 10. KDV
                    TextFormField(
                      controller: _kdvController,
                      decoration: const InputDecoration(
                        labelText: 'KDV (TL)',
                        prefixIcon: Icon(Icons.percent),
                        hintText: 'örn: 250,50',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      validator: (v) => kdvValidator(v, _tutarController.text),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    
                    // 11. MATRAH
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Matrah (Tutar - KDV)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            tutarFormat(_matrah),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 12. Fiş Fotoğrafı
              Text(
                'Fiş Fotoğrafı',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_imageFile != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                    if (!_isLoading)
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        onPressed: () => setState(() => _imageFile = null),
                      ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Kamera'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeri'),
                      ),
                    ),
                  ],
                ),
                
              const SizedBox(height: 32),
              
              // Kaydet Butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Kaydet'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
