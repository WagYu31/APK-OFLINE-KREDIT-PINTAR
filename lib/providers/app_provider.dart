import 'dart:convert';
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
  int _activeTabIndex = 0;

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
  int get activeTabIndex => _activeTabIndex;

  void switchTab(int index) {
    _activeTabIndex = index;
    notifyListeners();
  }

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

  Future<void> deleteNasabah(int id) async {
    await _db.deleteNasabah(id);
    await refreshData();
  }

  Future<void> deleteMultipleNasabah(List<int> ids) async {
    await _db.deleteMultipleNasabah(ids);
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

  /// Process a payment on a transaksi, automatically cascading any excess payment
  /// to other active loans of the same nasabah.
  Future<void> prosesPembayaran({
    required Transaksi transaksi,
    required double nominal,
    required String tanggalBayar,
    String? tanggalJanjiBerikutnya,
  }) async {
    double remainingNominal = nominal;

    // Fetch all active transactions for this nasabah from DB
    final allNasabahTx = await _db.getTransaksiByNasabah(transaksi.nasabahId);
    final activeTxList = allNasabahTx.where((t) => t.status != 'lunas').toList();

    // Ensure target transaksi is first in line
    activeTxList.sort((a, b) {
      if (a.id == transaksi.id) return -1;
      if (b.id == transaksi.id) return 1;
      return a.tanggalJatuhTempo.compareTo(b.tanggalJatuhTempo);
    });

    for (var currentTx in activeTxList) {
      if (remainingNominal <= 0) break;

      final currentSisa = currentTx.sisaHutang;
      final paymentForThisTx = (remainingNominal > currentSisa && currentSisa > 0)
          ? currentSisa
          : remainingNominal;

      final pembayaran = Pembayaran(
        nominal: paymentForThisTx,
        tanggal: tanggalBayar,
        tanggalJanjiBerikutnya: paymentForThisTx < currentSisa ? tanggalJanjiBerikutnya : null,
      );

      currentTx.riwayatPembayaran.add(pembayaran);
      final newSisa = currentTx.totalHarusBayar - currentTx.totalDibayar;

      if (newSisa <= 0) {
        currentTx.status = 'lunas';
        currentTx.sisaHutang = 0;
      } else {
        currentTx.status = 'sebagian';
        currentTx.sisaHutang = newSisa;
      }

      await _db.updateTransaksi(currentTx);
      remainingNominal -= paymentForThisTx;
    }

    // If there is still excess remainingNominal even after all active loans are paid lunas,
    // attach the remainder to the target transaction as an overpayment record.
    if (remainingNominal > 0 && activeTxList.isNotEmpty) {
      final targetTx = activeTxList.firstWhere(
        (t) => t.id == transaksi.id,
        orElse: () => activeTxList.first,
      );
      final lastP = targetTx.riwayatPembayaran.lastOrNull;
      if (lastP != null) {
        targetTx.riwayatPembayaran.removeLast();
        targetTx.riwayatPembayaran.add(Pembayaran(
          nominal: lastP.nominal + remainingNominal,
          tanggal: lastP.tanggal,
          tanggalJanjiBerikutnya: lastP.tanggalJanjiBerikutnya,
        ));
        await _db.updateTransaksi(targetTx);
      }
    }

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

    // Determine start date of period (Tanggal Buka Buku)
    String tanggalBukaBuku = '$tahun-01-01';
    if (allTransaksi.isNotEmpty) {
      final sortedTx = List<Transaksi>.from(allTransaksi)
        ..sort((a, b) => a.tanggalPinjam.compareTo(b.tanggalPinjam));
      if (sortedTx.first.tanggalPinjam.isNotEmpty) {
        tanggalBukaBuku = sortedTx.first.tanggalPinjam;
      }
    }

    // Build JSON snapshot of all nasabah & transactions for permanent history
    final snapshotObj = {
      'nasabah': allNasabah.map((n) => n.toMap()).toList(),
      'transaksi': allTransaksi.map((t) => t.toMap()).toList(),
    };
    final snapshotJson = jsonEncode(snapshotObj);

    final data = {
      'tahun': tahun,
      'modalAwal': _settings.modalAwal,
      'targetKeuntungan': _settings.targetKeuntungan,
      'totalKeuntungan': stats['totalKeuntungan'] ?? 0.0,
      'totalPinjaman': stats['totalPinjaman'] ?? 0.0,
      'totalPengembalian': stats['totalPengembalian'] ?? 0.0,
      'totalTransaksi': allTransaksi.length,
      'totalNasabah': allNasabah.length,
      'totalNasabahBaru': nasabahBaru,
      'totalKartuKuning': stats['totalKartuKuning'] ?? 0,
      'totalKartuMerah': stats['totalKartuMerah'] ?? 0,
      'tanggalBukaBuku': tanggalBukaBuku,
      'tanggalTutupBuku': DateTime.now().toIso8601String().split('T')[0],
      'snapshotData': snapshotJson,
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

  Future<void> deleteTutupBuku(int tahun) async {
    await _db.deleteTutupBuku(tahun);
    await refreshData();
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
