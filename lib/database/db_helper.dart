import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/nasabah.dart';
import '../models/transaksi.dart';
import '../models/settings.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kredit_pintar.db');

    return openDatabase(
      path,
      version: 7,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE settings (
            id TEXT PRIMARY KEY,
            modalAwal REAL DEFAULT 0,
            targetKeuntungan REAL DEFAULT 0,
            biayaAdminPerKelipatan REAL DEFAULT 25000,
            autoBackupIntervalDays INTEGER DEFAULT 0,
            tahunAktif INTEGER,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE nasabah (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT NOT NULL,
            nomorTelpon TEXT,
            kartuKuning INTEGER DEFAULT 0,
            alasanKartuKuning TEXT,
            kartuMerah INTEGER DEFAULT 0,
            diblokir INTEGER DEFAULT 0,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE transaksi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nasabahId INTEGER NOT NULL,
            tanggalPinjam TEXT,
            nominalPinjaman REAL,
            biayaAdmin REAL,
            totalHarusBayar REAL,
            tanggalJatuhTempo TEXT,
            status TEXT DEFAULT 'aktif',
            sisaHutang REAL,
            riwayatPembayaran TEXT DEFAULT '[]',
            createdAt TEXT,
            FOREIGN KEY (nasabahId) REFERENCES nasabah(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE tutup_buku (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tahun INTEGER UNIQUE,
            modalAwal REAL,
            targetKeuntungan REAL,
            totalKeuntungan REAL,
            totalPinjaman REAL,
            totalPengembalian REAL,
            totalTransaksi INTEGER,
            totalNasabah INTEGER,
            totalNasabahBaru INTEGER,
            totalKartuKuning INTEGER,
            totalKartuMerah INTEGER,
            tanggalBukaBuku TEXT,
            tanggalTutupBuku TEXT,
            snapshotData TEXT,
            createdAt TEXT
          )
        ''');

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
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute(
              'ALTER TABLE settings RENAME COLUMN targetKeuntunganPersen TO targetKeuntungan'
            );
          } catch (_) {
            try {
              await db.execute(
                'ALTER TABLE settings ADD COLUMN targetKeuntungan REAL DEFAULT 0'
              );
            } catch (_) {}
          }

          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_token (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              token TEXT NOT NULL,
              activatedAt TEXT NOT NULL,
              durationMinutes INTEGER NOT NULL
            )
          ''');
        }

        if (oldVersion < 3) {
          try {
            await db.execute(
              'ALTER TABLE settings ADD COLUMN biayaAdminPerKelipatan REAL DEFAULT 25000'
            );
          } catch (_) {}
        }

        if (oldVersion < 4) {
          try {
            await db.execute(
              'ALTER TABLE nasabah ADD COLUMN alasanKartuKuning TEXT'
            );
          } catch (_) {}
        }

        if (oldVersion < 5) {
          try {
            await db.execute(
              'ALTER TABLE tutup_buku ADD COLUMN tanggalBukaBuku TEXT'
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE tutup_buku ADD COLUMN tanggalTutupBuku TEXT'
            );
          } catch (_) {}
        }

        if (oldVersion < 6) {
          try {
            await db.execute(
              'ALTER TABLE tutup_buku ADD COLUMN targetKeuntungan REAL DEFAULT 0'
            );
          } catch (_) {}
        }

        if (oldVersion < 7) {
          try {
            await db.execute(
              'ALTER TABLE settings ADD COLUMN autoBackupIntervalDays INTEGER DEFAULT 0'
            );
          } catch (_) {}
        }
      },
    );
  }

  // ==================== SETTINGS ====================

  Future<Settings> getSettings() async {
    final db = await database;
    final maps = await db.query('settings', where: 'id = ?', whereArgs: ['main']);
    if (maps.isNotEmpty) {
      return Settings.fromMap(maps.first);
    }
    return Settings();
  }

  Future<void> saveSettings(Settings settings) async {
    final db = await database;
    await db.insert(
      'settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== NASABAH ====================

  Future<int> insertNasabah(Nasabah nasabah) async {
    final db = await database;
    return db.insert('nasabah', nasabah.toMap());
  }

  Future<void> updateNasabah(Nasabah nasabah) async {
    final db = await database;
    await db.update('nasabah', nasabah.toMap(),
        where: 'id = ?', whereArgs: [nasabah.id]);
  }

  Future<Nasabah?> getNasabah(int id) async {
    final db = await database;
    final maps = await db.query('nasabah', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Nasabah.fromMap(maps.first);
    return null;
  }

  Future<List<Nasabah>> getAllNasabah() async {
    final db = await database;
    final maps = await db.query('nasabah', orderBy: 'nama ASC');
    return maps.map((m) => Nasabah.fromMap(m)).toList();
  }

  Future<List<Nasabah>> searchNasabah(String query) async {
    final db = await database;
    final maps = await db.query('nasabah',
        where: 'nama LIKE ? OR nomorTelpon LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'nama ASC');
    return maps.map((m) => Nasabah.fromMap(m)).toList();
  }

  Future<void> deleteNasabah(int id) async {
    final db = await database;
    await db.delete('transaksi', where: 'nasabahId = ?', whereArgs: [id]);
    await db.delete('nasabah', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteMultipleNasabah(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final idList = ids.join(',');
    await db.delete('transaksi', where: 'nasabahId IN ($idList)');
    await db.delete('nasabah', where: 'id IN ($idList)');
  }

  // ==================== TRANSAKSI ====================

  Future<int> insertTransaksi(Transaksi transaksi) async {
    final db = await database;
    return db.insert('transaksi', transaksi.toMap());
  }

  Future<void> updateTransaksi(Transaksi transaksi) async {
    final db = await database;
    await db.update('transaksi', transaksi.toMap(),
        where: 'id = ?', whereArgs: [transaksi.id]);
  }

  Future<List<Transaksi>> getAllTransaksi() async {
    final db = await database;
    final maps = await db.query('transaksi', orderBy: 'createdAt DESC');
    return maps.map((m) => Transaksi.fromMap(m)).toList();
  }

  Future<List<Transaksi>> getTransaksiByNasabah(int nasabahId) async {
    final db = await database;
    final maps = await db.query('transaksi',
        where: 'nasabahId = ?',
        whereArgs: [nasabahId],
        orderBy: 'createdAt DESC');
    return maps.map((m) => Transaksi.fromMap(m)).toList();
  }

  Future<List<Transaksi>> getTransaksiAktif() async {
    final db = await database;
    final maps = await db.query('transaksi',
        where: "status != 'lunas'",
        orderBy: 'tanggalJatuhTempo ASC');
    return maps.map((m) => Transaksi.fromMap(m)).toList();
  }

  Future<List<Transaksi>> getTransaksiJatuhTempo() async {
    final all = await getTransaksiAktif();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final batas = today.add(const Duration(days: 3));
    return all.where((t) {
      final dueRaw = DateTime.parse(t.tanggalJatuhTempo);
      final due = DateTime(dueRaw.year, dueRaw.month, dueRaw.day);
      final isUpcoming = (due.isAfter(today) || due.isAtSameMomentAs(today)) &&
          (due.isBefore(batas) || due.isAtSameMomentAs(batas));
      return isUpcoming && t.status != 'sebagian';
    }).toList();
  }

  Future<List<Transaksi>> getTransaksiPunyaHutang() async {
    final all = await getTransaksiAktif();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return all.where((t) {
      final dueRaw = DateTime.parse(t.tanggalJatuhTempo);
      final due = DateTime(dueRaw.year, dueRaw.month, dueRaw.day);
      return due.isBefore(today) || t.status == 'sebagian';
    }).toList();
  }

  // ==================== STATISTIK ====================

  Future<Map<String, dynamic>> getStatistik() async {
    final settings = await getSettings();
    final allTransaksi = await getAllTransaksi();
    final allNasabah = await getAllNasabah();

    double totalPinjaman = 0;
    double totalPengembalian = 0;
    double totalKeuntungan = 0;
    int totalTransaksiAktif = 0;

    for (var t in allTransaksi) {
      totalPinjaman += t.nominalPinjaman;
      totalPengembalian += t.totalDibayar;
      totalKeuntungan += t.keuntunganTerbayar;
      if (t.status != 'lunas') totalTransaksiAktif++;
    }

    final saldoTotal = settings.modalAwal + totalKeuntungan;
    final persenTarget = settings.targetKeuntungan > 0
        ? (totalKeuntungan / settings.targetKeuntungan) * 100
        : 0.0;

    return {
      'modalAwal': settings.modalAwal,
      'saldoTotal': saldoTotal,
      'totalPinjaman': totalPinjaman,
      'totalPengembalian': totalPengembalian,
      'totalKeuntungan': totalKeuntungan,
      'targetKeuntungan': settings.targetKeuntungan,
      'persenTarget': persenTarget,
      'totalNasabah': allNasabah.length,
      'totalTransaksiAktif': totalTransaksiAktif,
      'totalKartuKuning': allNasabah.where((n) => n.kartuKuning).length,
      'totalKartuMerah': allNasabah.where((n) => n.kartuMerah).length,
    };
  }

  // ==================== TUTUP BUKU ====================

  Future<void> insertTutupBuku(Map<String, dynamic> data) async {
    final db = await database;
    try {
      await db.insert('tutup_buku', data,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Auto-migrate missing columns dynamically if DB version upgrade didn't trigger
      try {
        await db.execute('ALTER TABLE tutup_buku ADD COLUMN tanggalBukaBuku TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE tutup_buku ADD COLUMN tanggalTutupBuku TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE tutup_buku ADD COLUMN targetKeuntungan REAL DEFAULT 0');
      } catch (_) {}
      await db.insert('tutup_buku', data,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getAllTutupBuku() async {
    final db = await database;
    return db.query('tutup_buku', orderBy: 'tahun DESC');
  }

  Future<void> deleteTutupBuku(int tahun) async {
    final db = await database;
    await db.delete('tutup_buku', where: 'tahun = ?', whereArgs: [tahun]);
  }

  Future<void> resetAllData() async {
    final db = await database;
    await db.delete('transaksi');
    await db.delete('nasabah');
  }

  Future<void> resetTransaksiOnly() async {
    final db = await database;
    await db.delete('transaksi');
    // Reset kartu kuning saat buka buku baru
    await db.update('nasabah', {'kartuKuning': 0});
  }

  // ==================== BACKUP & RESTORE ====================

  Future<Map<String, dynamic>> exportBackupJson() async {
    final db = await database;
    final settingsMaps = await db.query('settings');
    final nasabahMaps = await db.query('nasabah');
    final transaksiMaps = await db.query('transaksi');
    final tutupBukuMaps = await db.query('tutup_buku');

    return {
      'appName': 'KreditPintar',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': settingsMaps,
      'nasabah': nasabahMaps,
      'transaksi': transaksiMaps,
      'tutup_buku': tutupBukuMaps,
    };
  }

  Future<bool> importBackupJson(Map<String, dynamic> backupData) async {
    final db = await database;
    if (backupData['appName'] != 'KreditPintar') return false;

    await db.transaction((txn) async {
      await txn.delete('transaksi');
      await txn.delete('nasabah');
      await txn.delete('tutup_buku');
      await txn.delete('settings');

      if (backupData['settings'] is List) {
        for (final item in backupData['settings']) {
          if (item is Map<String, dynamic>) {
            await txn.insert('settings', Map<String, dynamic>.from(item),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }

      if (backupData['nasabah'] is List) {
        for (final item in backupData['nasabah']) {
          if (item is Map<String, dynamic>) {
            await txn.insert('nasabah', Map<String, dynamic>.from(item),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }

      if (backupData['transaksi'] is List) {
        for (final item in backupData['transaksi']) {
          if (item is Map<String, dynamic>) {
            await txn.insert('transaksi', Map<String, dynamic>.from(item),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }

      if (backupData['tutup_buku'] is List) {
        for (final item in backupData['tutup_buku']) {
          if (item is Map<String, dynamic>) {
            await txn.insert('tutup_buku', Map<String, dynamic>.from(item),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }
    });

    return true;
  }
}
