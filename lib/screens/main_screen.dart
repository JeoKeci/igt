import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/harcama_provider.dart';
import '../providers/ozet_provider.dart';
import '../providers/auth_provider.dart';
import 'harcamalar_screen.dart';
import 'ozet_screen.dart';
import 'ayarlar_screen.dart';
import 'harcama_ekle_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Mevcut personeli dinle
    final personelAsync = ref.watch(currentPersonelProvider);
    
    // Saha personeli mi kontrolü
    final isSaha = personelAsync.value?.isSaha ?? false;
    
    // Saha personeline ayarları gösterme
    final activeScreens = [
      const HarcamalarScreen(),
      const OzetScreen(),
      if (!isSaha) const AyarlarScreen(),
    ];
    
    final activeDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Harcamalar',
      ),
      const NavigationDestination(
        icon: Icon(Icons.pie_chart_outline),
        selectedIcon: Icon(Icons.pie_chart),
        label: 'Özet',
      ),
      if (!isSaha)
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Ayarlar',
        ),
    ];
    
    // Eğer index sınırların dışındaysa 0'a çek (Örn: Saha personeli login olunca)
    if (_selectedIndex >= activeScreens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: activeScreens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: activeDestinations,
      ),
    );
  }
}
