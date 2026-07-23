import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';

class TokenService {
  // ==================== DAFTAR TOKEN ====================
  // Tambahkan token baru di sini
  static final Map<String, int> _tokenList = {
    'XK7P-9WQL': 2,             // 2 menit
    'BN3F-HVRT': 5,             // 5 menit
    'M8DZ-42YA': 60,            // 1 jam
    'RJ6C-EXNB': 1440,          // 1 hari (24 jam)
    'VT2W-KP85': 10080,         // 7 hari
    'GQ4N-LD97': 43200,         // 30 hari
    'AH1Y-ZF63': 525600,        // 1 tahun
    'UW9S-MC0X': 99999999,      // Selamanya (~190 tahun)
  };

  // ==================== CEK TOKEN VALID ====================
  static Future<bool> isTokenActive() async {
    try {
      final db = await DbHelper().database;

      // Cek apakah tabel token ada
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='app_token'",
      );
      if (tables.isEmpty) {
        await _createTokenTable(db);
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

  // ==================== AKTIVASI TOKEN ====================
  static Future<Map<String, dynamic>> activateToken(String token) async {
    final upperToken = token.toUpperCase().trim();

    // Cek apakah token valid
    if (!_tokenList.containsKey(upperToken)) {
      return {
        'success': false,
        'message': 'Token tidak valid! ❌',
      };
    }

    final durationMinutes = _tokenList[upperToken]!;

    try {
      final db = await DbHelper().database;

      // Pastikan tabel ada
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='app_token'",
      );
      if (tables.isEmpty) {
        await _createTokenTable(db);
      }

      // Hapus token lama
      await db.delete('app_token');

      // Insert token baru
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
        'message': 'Token aktif! ✅\nMasa berlaku: $durasi',
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
  static Future<void> _createTokenTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_token (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        token TEXT NOT NULL,
        activatedAt TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL
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
}
