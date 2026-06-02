import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lookup_provider.dart';
import '../models/personel.dart';
import '../widgets/loading_widget.dart';

class PersonelYonetimiScreen extends ConsumerStatefulWidget {
  const PersonelYonetimiScreen({super.key});

  @override
  ConsumerState<PersonelYonetimiScreen> createState() => _PersonelYonetimiScreenState();
}

class _PersonelYonetimiScreenState extends ConsumerState<PersonelYonetimiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adSoyadController = TextEditingController();
  final _epostaController = TextEditingController();
  final _sifreController = TextEditingController();
  
  String _rol = 'saha';
  bool _isSaving = false;

  @override
  void dispose() {
    _adSoyadController.dispose();
    _epostaController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  void _showFormDialog({Personel? personel}) {
    final bool isNew = personel == null;

    if (!isNew) {
      _adSoyadController.text = personel.adSoyad;
      _epostaController.text = personel.eposta;
      _sifreController.clear(); // Şifre değiştirilemez
      _rol = personel.rol;
    } else {
      _adSoyadController.clear();
      _epostaController.clear();
      _sifreController.clear();
      _rol = 'saha';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isNew ? 'Yeni Personel' : 'Personel Düzenle'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _adSoyadController,
                        decoration: const InputDecoration(labelText: 'Ad Soyad'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _epostaController,
                        decoration: InputDecoration(
                          labelText: 'E-posta',
                          // Düzenlerken eposta değiştirilemez
                          enabled: isNew,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Zorunlu alan';
                          if (!v.contains('@')) return 'Geçerli bir e-posta girin';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (isNew) ...[
                        TextFormField(
                          controller: _sifreController,
                          decoration: const InputDecoration(labelText: 'Geçici Şifre (En az 6 karakter)'),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Zorunlu alan';
                            if (v.length < 6) return 'Şifre en az 6 karakter olmalı';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        const Text(
                          'Güvenlik gereği şifre ve mail adresi bu ekrandan değiştirilemez.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                      ],
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Rol'),
                        value: _rol,
                        items: const [
                          DropdownMenuItem(value: 'saha', child: Text('Saha Personeli')),
                          DropdownMenuItem(value: 'muhasebe', child: Text('Muhasebe')),
                          DropdownMenuItem(value: 'yonetici', child: Text('Yönetici')),
                        ],
                        onChanged: (v) => setDialogState(() => _rol = v ?? 'saha'),
                      ),
                    ],
                  ),
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

                          try {
                            if (isNew) {
                              await lookupService.addPersonel(
                                adSoyad: _adSoyadController.text.trim(),
                                eposta: _epostaController.text.trim(),
                                sifre: _sifreController.text,
                                rol: _rol,
                              );
                            } else {
                              final data = {
                                'ad_soyad': _adSoyadController.text.trim(),
                                'rol': _rol,
                              };
                              await lookupService.updatePersonel(personel.id, data);
                            }
                            ref.invalidate(personellerProvider);
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Hata: $e'),
                                    backgroundColor: Theme.of(context).colorScheme.error),
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

  void _confirmDelete(Personel personel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personeli Sil'),
        content: Text('"${personel.adSoyad}" isimli personeli silmek istediğinize emin misiniz? (Geçmiş kayıtlar etkilenmeyecek, personel sisteme giremeyecek)'),
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
              Navigator.pop(context);
              final lookupService = ref.read(lookupServiceProvider);
              try {
                // Sadece iptal bayrağını ve aktif bayrağını güncelliyoruz
                await lookupService.updatePersonel(personel.id, {'iptal': true, 'aktif': false});
                ref.invalidate(personellerProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error),
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
    final state = ref.watch(personellerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => _showFormDialog(),
            tooltip: 'Yeni Personel Ekle',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.when(
        data: (liste) {
          if (liste.isEmpty) {
            return const Center(child: Text('Kayıtlı personel bulunmuyor.'));
          }
          return ListView.builder(
            itemCount: liste.length,
            itemBuilder: (context, index) {
              final personel = liste[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: personel.aktif
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person,
                      color: personel.aktif
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    personel.adSoyad,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: personel.aktif ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text('${personel.eposta}\nRol: ${personel.rol.toUpperCase()}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showFormDialog(personel: personel),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                        onPressed: () => _confirmDelete(personel),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Yükleniyor...'),
        error: (error, stack) => Center(child: Text('Hata: $error')),
      ),
    );
  }
}
