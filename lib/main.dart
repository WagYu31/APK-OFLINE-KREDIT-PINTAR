import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/app_provider.dart';
import 'services/token_service.dart';
import 'screens/token_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transaksi_screen.dart';
import 'screens/nasabah_list_screen.dart';
import 'screens/tutup_buku_screen.dart';
import 'screens/settings_screen.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E1A),
    ));
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const KreditPintarApp(),
    ),
  );
}

class KreditPintarApp extends StatelessWidget {
  const KreditPintarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sukron08',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFB8860B),
          surface: Color(0xFF1E293B),
          error: Color(0xFFE53935),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0A0E1A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const TokenGate(),
    );
  }
}

// ==================== TOKEN GATE ====================
// Mengecek token sebelum izinkan akses ke app
class TokenGate extends StatefulWidget {
  const TokenGate({super.key});

  @override
  State<TokenGate> createState() => _TokenGateState();
}

class _TokenGateState extends State<TokenGate> {
  bool _isChecking = true;
  bool _isTokenValid = false;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    // Tunggu provider siap (database terinisialisasi)
    await Future.delayed(const Duration(milliseconds: 500));
    final valid = await TokenService.isTokenActive();
    if (mounted) {
      setState(() {
        _isTokenValid = valid;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    if (!_isTokenValid) {
      return TokenScreen(
        onActivated: () {
          setState(() {
            _isTokenValid = true;
          });
        },
      );
    }

    return const MainNavigation();
  }
}

// ==================== MAIN NAVIGATION ====================
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _checkedFirstTime = false;
  Timer? _tokenTimer;
  String _sisaWaktu = '';

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransaksiScreen(),
    NasabahListScreen(),
    TutupBukuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _startTokenTimer();
  }

  @override
  void dispose() {
    _tokenTimer?.cancel();
    super.dispose();
  }

  void _startTokenTimer() {
    _updateSisaWaktu();
    _tokenTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateSisaWaktu();
    });
  }

  Future<void> _updateSisaWaktu() async {
    final info = await TokenService.getActiveTokenInfo();
    if (info == null || info['isExpired'] == true) {
      // Token expired — kick back to token screen
      if (mounted) {
        _tokenTimer?.cancel();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: Theme.of(context),
              home: const TokenGate(),
            ),
          ),
          (route) => false,
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _sisaWaktu = TokenService.formatSisaWaktu(info['sisaDetik'] as int);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Show settings on first time
        if (!provider.isLoading &&
            !_checkedFirstTime &&
            provider.settings.modalAwal == 0) {
          _checkedFirstTime = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(isFirstTime: true),
              ),
            );
          });
        } else if (!provider.isLoading) {
          _checkedFirstTime = true;
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E1A),
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Sukron08'),
              ],
            ),
            actions: [
              // Sisa waktu token
              if (_sisaWaktu.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Color(0xFF4CAF50), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _sisaWaktu,
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white54),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: provider.activeTabIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1629),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(provider, 0, Icons.dashboard_rounded, 'Dashboard'),
                    _buildNavItem(provider, 1, Icons.add_circle_outline, 'Transaksi'),
                    _buildNavItem(provider, 2, Icons.people_outline, 'Nasabah'),
                    _buildNavItem(provider, 3, Icons.book_outlined, 'Tutup Buku'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(AppProvider provider, int index, IconData icon, String label) {
    final isActive = provider.activeTabIndex == index;
    return GestureDetector(
      onTap: () => provider.switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFD4AF37).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xFFD4AF37)
                  : Colors.white.withOpacity(0.4),
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
