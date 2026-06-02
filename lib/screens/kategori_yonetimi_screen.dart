import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lookup_provider.dart';
import '../services/lookup_service.dart';
import '../models/kategori.dart';
import '../widgets/loading_widget.dart';

class KategoriYonetimiScreen extends ConsumerStatefulWidget {
  const KategoriYonetimiScreen({super.key});

  @override
  ConsumerState<KategoriYonetimiScreen> createState() => _KategoriYonetimiScreenState();
}

class _KategoriYonetimiScreenState extends ConsumerState<KategoriYonetimiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _noController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _adController.dispose();
    _noController.dispose();
    super.dispose();
  }

  void _showFormDialog({Kategori? kategori, int? autoNo}) {
    if (kategori != null) {
      _adController.text = kategori.ad;
      _noController.text = kategori.no.toString();
    } else {
      _adController.clear();
      _noController.text = (autoNo ?? 1).toString();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(kategori == null ? 'Yeni Kategori' : 'Kategori Düzenle'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _noController,
                      decoration: const InputDecoration(labelText: 'Sıra No'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Zorunlu';
                        if (int.tryParse(v) == null) return 'Geçerli bir sayı girin';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _adController,
                      decoration: const InputDecoration(labelText: 'Kategori Adı'),
                      validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setDialogState(() => _isSaving = true);

                          final lookupService = ref.read(lookupServiceProvider);
                          final data = {
                            'ad': _adController.text.trim(),
                            'no': int.parse(_noController.text.trim()),
                          };

                          try {
                            if (kategori == null) {
                              await lookupService.addKategori(data);
                            } else {
                              await lookupService.updateKategori(kategori.id, data);
                            }
                            ref.invalidate(kategorilerProvider);
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hata: $e'), backgroundColor: Theme.of(context).colorScheme.error),
                              );
                            }
                          } finally {
                            if (mounted) setDialogState(() => _isSaving = false);
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Kategori kategori) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text('"${kategori.ad}" kategorisini silmek istediğinize emin misiniz? Geçmiş kayıtlar etkilenmeyecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final lookupService = ref.read(lookupServiceProvider);
              try {
                await lookupService.updateKategori(kategori.id, {'iptal': true});
                ref.invalidate(kategorilerProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e'), backgroundColor: Theme.of(context).colorScheme.error),
                  );
                }
              }
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kategorilerAsync = ref.watch(kategorilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcama Kategorileri'),
      ),
      body: kategorilerAsync.when(
        data: (kategoriler) {
          if (kategoriler.isEmpty) {
            return const Center(child: Text('Kayıtlı kategori bulunmuyor.'));
          }
          return ListView.builder(
            itemCount: kategoriler.length,
            itemBuilder: (context, index) {
              final kat = kategoriler[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(kat.no.toString()),
                  ),
                  title: Text(kat.ad, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showFormDialog(kategori: kat),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                        onPressed: () => _confirmDelete(kat),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Kategoriler yükleniyor...'),
        error: (error, stack) => IgtErrorWidget(
          message: 'Kategoriler yüklenirken hata oluştu',
          onRetry: () => ref.refresh(kategorilerProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final kategoriler = kategorilerAsync.value;
          int nextNo = 1;
          if (kategoriler != null && kategoriler.isNotEmpty) {
            nextNo = kategoriler.map((e) => e.no).reduce((a, b) => a > b ? a : b) + 1;
          }
          _showFormDialog(autoNo: nextNo);
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Kategori'),
      ),
    );
  }
}
