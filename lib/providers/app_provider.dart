import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/nasabah.dart';
import '../models/transaksi.dart';
import '../models/settings.dart';

class AppProvider extends ChangeNotifier {
  final DbHelper _db = DbHelper();

  Settings _settings = Settings();
  List<Nasabah> _allNasabah = [];
  List<Transaksi> _allTransaksi = [];
  List<Transaksi> _transaksiJatuhTempo = [];
  List<Transaksi> _transaksiHutang = [];
  Map<String, dynamic> _statistik = {};
  bool _isLoading = true;
  String _searchQuery = '';

  // Getters
  Settings get settings => _settings;
  List<Nasabah> get allNasabah => _searchQuery.isEmpty
      ? _allNasabah
      : _allNasabah.where((n) =>
          n.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.nomorTelpon.contains(_searchQuery)).toList();
  List<Transaksi> get allTransaksi => _allTransaksi;
  List<Transaksi> get transaksiJatuhTempo => _transaksiJatuhTempo;
  List<Transaksi> get transaksiHutang => _transaksiHutang;
  Map<String, dynamic> get statistik => _statistik;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _settings = await _db.getSettings();
    await refreshData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshData() async {
    _allNasabah = await _db.getAllNasabah();
    _allTransaksi = await _db.getAllTransaksi();
    _transaksiJatuhTempo = await _db.getTransaksiJatuhTempo();
    _transaksiHutang = await _db.getTransaksiPunyaHutang();
    _statistik = await _db.getStatistik();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ==================== SETTINGS ====================

  Future<void> saveSettings(Settings settings) async {
    await _db.saveSettings(settings);
    _settings = settings;
    await refreshData();
  }

  // ==================== NASABAH ====================

  Future<int> addNasabah(Nasabah nasabah) async {
    final id = await _db.insertNasabah(nasabah);
    await refreshData();
    return id;
  }

  Future<void> updateNasabah(Nasabah nasabah) async {
    await _db.updateNasabah(nasabah);
    await refreshData();
  }

  Future<Nasabah?> getNasabahById(int id) async {
    return _db.getNasabah(id);
  }

  Future<void> toggleKartuKuning(Nasabah nasabah, {String? alasan}) async {
    nasabah.kartuKuning = !nasabah.kartuKuning;
    if (nasabah.kartuKuning) {
      nasabah.alasanKartuKuning = alasan;
    } else {
      nasabah.alasanKartuKuning = null;
    }
    await _db.updateNasabah(nasabah);
    await refreshData();
  }

  Future<void> toggleKartuMerah(Nasabah nasabah) async {
    nasabah.kartuMerah = !nasabah.kartuMerah;
    await _db.updateNasabah(nasabah);
    await refreshData();
  }

  Future<void> toggleBlokir(Nasabah nasabah) async {
    nasabah.diblokir = !nasabah.diblokir;
    nasabah.kartuMerah = nasabah.diblokir;
    await _db.updateNasabah(nasabah);
    await refreshData();
  }

  // ==================== TRANSAKSI ====================

  Future<int> addTransaksi(Transaksi transaksi) async {
    final id = await _db.insertTransaksi(transaksi);
    await refreshData();
    return id;
  }

  Future<List<Transaksi>> getTransaksiByNasabah(int nasabahId) async {
    return _db.getTransaksiByNasabah(nasabahId);
  }

  Future<bool> nasabahHasActiveTransaksi(int nasabahId) async {
    final transaksi = await _db.getTransaksiByNasabah(nasabahId);
    return transaksi.any((t) => t.status != 'lunas');
  }

  /// Process a payment on a transaksi
  Future<void> prosesPembayaran({
    required Transaksi transaksi,
    required double nominal,
    required String tanggalBayar,
    String? tanggalJanjiBerikutnya,
  }) async {
    final pembayaran = Pembayaran(
      nominal: nominal,
      tanggal: tanggalBayar,
      tanggalJanjiBerikutnya: tanggalJanjiBerikutnya,
    );

    transaksi.riwayatPembayaran.add(pembayaran);
    transaksi.sisaHutang = transaksi.totalHarusBayar - transaksi.totalDibayar;

    if (transaksi.sisaHutang <= 0) {
      transaksi.status = 'lunas';
      transaksi.sisaHutang = 0;
    } else {
      transaksi.status = 'sebagian';
    }

    await _db.updateTransaksi(transaksi);
    await refreshData();
  }

  /// Mark a transaksi as fully paid (lunas)
  Future<void> tandaiLunas(Transaksi transaksi) async {
    final sisa = transaksi.sisaHutang;
    if (sisa > 0) {
      final pembayaran = Pembayaran(
        nominal: sisa,
        tanggal: DateTime.now().toIso8601String().split('T')[0],
      );
      transaksi.riwayatPembayaran.add(pembayaran);
    }
    transaksi.status = 'lunas';
    transaksi.sisaHutang = 0;
    await _db.updateTransaksi(transaksi);
    await refreshData();
  }

  // ==================== TUTUP BUKU ====================

  Future<Map<String, dynamic>> generateTutupBuku() async {
    final stats = await _db.getStatistik();
    final allTransaksi = await _db.getAllTransaksi();
    final allNasabah = await _db.getAllNasabah();

    final tahun = _settings.tahunAktif;
    final nasabahBaru = allNasabah.where((n) {
      final created = DateTime.parse(n.createdAt);
      return created.year == tahun;
    }).length;

    final data = {
      'tahun': tahun,
      'modalAwal': _settings.modalAwal,
      'totalKeuntungan': stats['totalKeuntungan'] ?? 0.0,
      'totalPinjaman': stats['totalPinjaman'] ?? 0.0,
      'totalPengembalian': stats['totalPengembalian'] ?? 0.0,
      'totalTransaksi': allTransaksi.length,
      'totalNasabah': allNasabah.length,
      'totalNasabahBaru': nasabahBaru,
      'totalKartuKuning': stats['totalKartuKuning'] ?? 0,
      'totalKartuMerah': stats['totalKartuMerah'] ?? 0,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _db.insertTutupBuku(data);
    return data;
  }

  Future<void> resetData({bool fullReset = false}) async {
    if (fullReset) {
      await _db.resetAllData();
    } else {
      await _db.resetTransaksiOnly();
    }
    await refreshData();
  }

  Future<List<Map<String, dynamic>>> getRiwayatTutupBuku() async {
    return _db.getAllTutupBuku();
  }

  String getNasabahNama(int nasabahId) {
    final nasabah = _allNasabah.firstWhere(
      (n) => n.id == nasabahId,
      orElse: () => Nasabah(nama: 'Unknown', nomorTelpon: ''),
    );
    return nasabah.nama;
  }

  Nasabah? getNasabahFromList(int nasabahId) {
    try {
      return _allNasabah.firstWhere((n) => n.id == nasabahId);
    } catch (_) {
      return null;
    }
  }
}
