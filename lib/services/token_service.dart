import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';

class TokenService {
  // ==================== DAFTAR TOKEN (75+ TOKEN SEKALI PAKAI) ====================
  static final Map<String, int> _tokenList = {
    // Legacy / Test tokens
    'XK7P-9WQL': 2,
    'BN3F-HVRT': 5,
    'M8DZ-42YA': 60,
    'RJ6C-EXNB': 1440,
    'VT2W-KP85': 10080,
    'GQ4N-LD97': 43200,
    'AH1Y-ZF63': 525600,
    'UW9S-MC0X': 99999999,

    // --- 2 MENIT (Trial) ---
    'T2M-BQEE-98CF': 2,
    'T2M-DRMK-EQCW': 2,
    'T2M-NT9N-TQRX': 2,
    'T2M-5UVN-FUUR': 2,
    'T2M-KXAP-VQK2': 2,
    'T2M-TX8M-9FTN': 2,
    'T2M-VJAD-8CCP': 2,
    'T2M-4MPU-QNRU': 2,
    'T2M-HRWS-SLKY': 2,
    'T2M-YX4Y-K7XR': 2,

    // --- 5 MENIT (Trial) ---
    'T5M-LJTE-AWL3': 5,
    'T5M-T2JY-LSDG': 5,
    'T5M-7KQ2-S5M5': 5,
    'T5M-Q6ZC-NZAN': 5,
    'T5M-F8UN-2XKN': 5,
    'T5M-CWGV-5F58': 5,
    'T5M-X2UE-YQGN': 5,
    'T5M-9KX8-B2P4': 5,
    'T5M-XJDD-LJC6': 5,
    'T5M-NTUK-QFY8': 5,

    // --- 1 JAM ---
    'H1J-U59P-CA2F': 60,
    'H1J-DB5K-G37R': 60,
    'H1J-8ZGJ-GD4U': 60,
    'H1J-KDFS-YEQF': 60,
    'H1J-55TG-SQQG': 60,
    'H1J-HAMP-KT6R': 60,
    'H1J-234R-D522': 60,
    'H1J-3D57-T79K': 60,
    'H1J-ZJB4-RUHB': 60,
    'H1J-5Q49-8Z6L': 60,

    // --- 1 HARI (24 Jam) ---
    'D1H-TRTH-6UUU': 1440,
    'D1H-FVL5-KHAN': 1440,
    'D1H-H7DA-Q74U': 1440,
    'D1H-84TK-UZBX': 1440,
    'D1H-U494-58W4': 1440,
    'D1H-ACBQ-X74K': 1440,
    'D1H-48E5-96D7': 1440,
    'D1H-Y6TS-MVAC': 1440,
    'D1H-HXZ6-DZBH': 1440,
    'D1H-6LCL-BJZW': 1440,

    // --- 7 HARI (1 Minggu) ---
    'D7H-YXPY-YNME': 10080,
    'D7H-MJC5-C92D': 10080,
    'D7H-XKR9-ANWV': 10080,
    'D7H-3TWK-8QGE': 10080,
    'D7H-M6E8-TMVQ': 10080,
    'D7H-B3KQ-5628': 10080,
    'D7H-7HAN-MGLZ': 10080,
    'D7H-78RP-4EGF': 10080,
    'D7H-QA4T-EYQ8': 10080,
    'D7H-C69Y-JM34': 10080,

    // --- 30 HARI (1 Bulan) ---
    'M1B-BMW5-6PTQ': 43200,
    'M1B-RJ3M-9B28': 43200,
    'M1B-587D-ACWA': 43200,
    'M1B-984H-RQ5V': 43200,
    'M1B-C5QH-CV8G': 43200,
    'M1B-QMT2-72V5': 43200,
    'M1B-7LS5-8JTU': 43200,
    'M1B-LYVG-D9CF': 43200,
    'M1B-H94Z-LZFK': 43200,
    'M1B-WNRS-U34R': 43200,

    // --- 1 TAHUN ---
    'Y1T-BBGR-F4NJ': 525600,
    'Y1T-QX42-4BWH': 525600,
    'Y1T-Z96S-5RS9': 525600,
    'Y1T-RP9P-N4HG': 525600,
    'Y1T-756Q-HTGX': 525600,
    'Y1T-HYZX-98U5': 525600,
    'Y1T-MYAX-KA8P': 525600,
    'Y1T-LSZ9-LKQN': 525600,
    'Y1T-ABCU-KGE9': 525600,
    'Y1T-28CL-WEPC': 525600,

    // --- LIFETIME (Selamanya) ---
    'LFT-UNS9-CYHW': 99999999,
    'LFT-6852-B5M7': 99999999,
    'LFT-4U3M-H2AA': 99999999,
    'LFT-8P2K-UEXL': 99999999,
    'LFT-42G3-9WH3': 99999999,
  };

  // ==================== CEK TOKEN VALID & AKTIF ====================
  static Future<bool> isTokenActive() async {
    try {
      final db = await DbHelper().database;

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='app_token'",
      );
      if (tables.isEmpty) {
        await _createTokenTables(db);
        return false;
      }

      final result = await db.query('app_token', limit: 1);
      if (result.isEmpty) return false;

      final activatedAt = DateTime.parse(result.first['activatedAt'] as String);
      final durationMinutes = result.first['durationMinutes'] as int;
      final expiredAt = activatedAt.add(Duration(minutes: durationMinutes));

      return DateTime.now().isBefore(expiredAt);
    } catch (e) {
      return false;
    }
  }

  // ==================== INFO TOKEN AKTIF ====================
  static Future<Map<String, dynamic>?> getActiveTokenInfo() async {
    try {
      final db = await DbHelper().database;

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='app_token'",
      );
      if (tables.isEmpty) return null;

      final result = await db.query('app_token', limit: 1);
      if (result.isEmpty) return null;

      final token = result.first['token'] as String;
      final activatedAt = DateTime.parse(result.first['activatedAt'] as String);
      final durationMinutes = result.first['durationMinutes'] as int;
      final expiredAt = activatedAt.add(Duration(minutes: durationMinutes));
      final sisaDetik = expiredAt.difference(DateTime.now()).inSeconds;

      return {
        'token': token,
        'activatedAt': activatedAt,
        'expiredAt': expiredAt,
        'durationMinutes': durationMinutes,
        'sisaDetik': sisaDetik > 0 ? sisaDetik : 0,
        'isExpired': sisaDetik <= 0,
      };
    } catch (e) {
      return null;
    }
  }

  // ==================== AKTIVASI TOKEN (SEKALI PAKAI) ====================
  static Future<Map<String, dynamic>> activateToken(String token) async {
    final upperToken = token.toUpperCase().trim();

    // 1. Cek apakah token ada di daftar valid
    if (!_tokenList.containsKey(upperToken)) {
      return {
        'success': false,
        'message': 'Token tidak valid! Kode salah. ❌',
      };
    }

    try {
      final db = await DbHelper().database;
      await _createTokenTables(db);

      // 2. Cek apakah token ini sudah PERNAH DIGUNAKAN (Single Use Check)
      final usedCheck = await db.query(
        'used_tokens',
        where: 'token = ?',
        whereArgs: [upperToken],
      );

      if (usedCheck.isNotEmpty) {
        return {
          'success': false,
          'message': 'Token ini sudah pernah digunakan! ⚠️\nSilakan minta kode token baru.',
        };
      }

      final durationMinutes = _tokenList[upperToken]!;

      // 3. Catat token ke tabel used_tokens agar tidak bisa dipakai lagi nanti
      await db.insert('used_tokens', {
        'token': upperToken,
        'usedAt': DateTime.now().toIso8601String(),
      });

      // 4. Hapus token lama di app_token & simpan token baru
      await db.delete('app_token');
      await db.insert('app_token', {
        'token': upperToken,
        'activatedAt': DateTime.now().toIso8601String(),
        'durationMinutes': durationMinutes,
      });

      String durasi;
      if (durationMinutes >= 525600) {
        durasi = 'Selamanya';
      } else if (durationMinutes >= 1440) {
        durasi = '${durationMinutes ~/ 1440} hari';
      } else if (durationMinutes >= 60) {
        durasi = '${durationMinutes ~/ 60} jam';
      } else {
        durasi = '$durationMinutes menit';
      }

      return {
        'success': true,
        'message': 'Aktivasi Berhasil! ✅\nMasa berlaku: $durasi',
        'durationMinutes': durationMinutes,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal aktivasi token: $e',
      };
    }
  }

  // ==================== BUAT TABEL TOKEN ====================
  static Future<void> _createTokenTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_token (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        token TEXT NOT NULL,
        activatedAt TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS used_tokens (
        token TEXT PRIMARY KEY,
        usedAt TEXT NOT NULL
      )
    ''');
  }

  // ==================== FORMAT SISA WAKTU ====================
  static String formatSisaWaktu(int sisaDetik) {
    if (sisaDetik <= 0) return 'Expired';
    if (sisaDetik >= 86400) {
      final hari = sisaDetik ~/ 86400;
      return '$hari hari lagi';
    } else if (sisaDetik >= 3600) {
      final jam = sisaDetik ~/ 3600;
      final menit = (sisaDetik % 3600) ~/ 60;
      return '${jam}j ${menit}m lagi';
    } else if (sisaDetik >= 60) {
      final menit = sisaDetik ~/ 60;
      final detik = sisaDetik % 60;
      return '${menit}m ${detik}d lagi';
    } else {
      return '${sisaDetik}d lagi';
    }
  }

  // ==================== VERIFIKASI TOKEN UNTUK BACKUP ====================
  static final Set<String> _masterBackupTokens = {
    'PROG-BACKUP-99',
    'SEC-8888-KREDIT',
    'BCK-7777-SUKRON',
    'KREDIT-PINTAR-BACKUP',
  };

  static Future<bool> verifyTokenForBackup(String inputToken) async {
    final cleanInput = inputToken.toUpperCase().trim();
    if (cleanInput.isEmpty) return false;

    // 1. Cek token master khusus programmer
    if (_masterBackupTokens.contains(cleanInput)) {
      return true;
    }

    // 2. Cek apakah ada di daftar token valid sistem
    if (_tokenList.containsKey(cleanInput)) {
      return true;
    }

    return false;
  }
}
