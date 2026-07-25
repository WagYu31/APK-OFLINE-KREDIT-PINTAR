import 'dart:convert';

class Pembayaran {
  double nominal;
  String tanggal;
  String? tanggalJanjiBerikutnya;
  String catatan;

  Pembayaran({
    required this.nominal,
    required this.tanggal,
    this.tanggalJanjiBerikutnya,
    this.catatan = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'nominal': nominal,
      'tanggal': tanggal,
      'tanggalJanjiBerikutnya': tanggalJanjiBerikutnya,
      'catatan': catatan,
    };
  }

  factory Pembayaran.fromMap(Map<String, dynamic> map) {
    return Pembayaran(
      nominal: (map['nominal'] ?? 0).toDouble(),
      tanggal: map['tanggal'] ?? '',
      tanggalJanjiBerikutnya: map['tanggalJanjiBerikutnya'],
      catatan: map['catatan'] ?? '',
    );
  }
}

class Transaksi {
  int? id;
  int nasabahId;
  String tanggalPinjam;
  double nominalPinjaman;
  double biayaAdmin;
  double totalHarusBayar;
  String tanggalJatuhTempo;
  String status; // 'aktif', 'sebagian', 'lunas'
  double sisaHutang;
  List<Pembayaran> riwayatPembayaran;
  String createdAt;

  Transaksi({
    this.id,
    required this.nasabahId,
    required this.tanggalPinjam,
    required this.nominalPinjaman,
    required this.biayaAdmin,
    required this.totalHarusBayar,
    required this.tanggalJatuhTempo,
    this.status = 'aktif',
    double? sisaHutang,
    List<Pembayaran>? riwayatPembayaran,
    String? createdAt,
  })  : sisaHutang = sisaHutang ?? (nominalPinjaman + biayaAdmin),
        riwayatPembayaran = riwayatPembayaran ?? [],
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  /// Hitung biaya admin: default Rp 25.000 per Rp 100.000 pinjaman (bisa diatur di Pengaturan)
  static double hitungBiayaAdmin(double nominalPinjaman, {double rate = 25000}) {
    return (nominalPinjaman / 100000).ceil() * rate;
  }

  /// Hitung total yang harus dibayar
  static double hitungTotalBayar(double nominalPinjaman, {double rate = 25000}) {
    return nominalPinjaman + hitungBiayaAdmin(nominalPinjaman, rate: rate);
  }

  /// Total yang sudah dibayar
  double get totalDibayar {
    return riwayatPembayaran.fold(0.0, (sum, p) => sum + p.nominal);
  }

  /// Keuntungan dari transaksi ini (biaya admin yang sudah terbayar)
  double get keuntunganTerbayar {
    if (status == 'lunas') return biayaAdmin;
    final sisa = totalHarusBayar - totalDibayar;
    if (sisa <= 0) return biayaAdmin;
    // Proportional profit based on what's been paid
    final paidRatio = totalDibayar / totalHarusBayar;
    return biayaAdmin * paidRatio;
  }

  /// Check if nearing due date (within 3 days)
  bool get isNearDue {
    final now = DateTime.now();
    final due = DateTime.parse(tanggalJatuhTempo);
    final diff = due.difference(now).inDays;
    return diff <= 3 && diff >= 0 && status != 'lunas';
  }

  /// Check if overdue
  bool get isOverdue {
    final now = DateTime.now();
    final due = DateTime.parse(tanggalJatuhTempo);
    return now.isAfter(due) && status != 'lunas';
  }

  /// Tanggal janji berikutnya (dari pembayaran terakhir)
  String? get tanggalJanjiBerikutnya {
    if (riwayatPembayaran.isEmpty) return null;
    return riwayatPembayaran.last.tanggalJanjiBerikutnya;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nasabahId': nasabahId,
      'tanggalPinjam': tanggalPinjam,
      'nominalPinjaman': nominalPinjaman,
      'biayaAdmin': biayaAdmin,
      'totalHarusBayar': totalHarusBayar,
      'tanggalJatuhTempo': tanggalJatuhTempo,
      'status': status,
      'sisaHutang': sisaHutang,
      'riwayatPembayaran': jsonEncode(
        riwayatPembayaran.map((p) => p.toMap()).toList(),
      ),
      'createdAt': createdAt,
    };
  }

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    List<Pembayaran> pembayaran = [];
    if (map['riwayatPembayaran'] != null) {
      final decoded = jsonDecode(map['riwayatPembayaran'] as String);
      pembayaran = (decoded as List).map((p) => Pembayaran.fromMap(p)).toList();
    }

    return Transaksi(
      id: map['id'],
      nasabahId: map['nasabahId'],
      tanggalPinjam: map['tanggalPinjam'] ?? '',
      nominalPinjaman: (map['nominalPinjaman'] ?? 0).toDouble(),
      biayaAdmin: (map['biayaAdmin'] ?? 0).toDouble(),
      totalHarusBayar: (map['totalHarusBayar'] ?? 0).toDouble(),
      tanggalJatuhTempo: map['tanggalJatuhTempo'] ?? '',
      status: map['status'] ?? 'aktif',
      sisaHutang: (map['sisaHutang'] ?? 0).toDouble(),
      riwayatPembayaran: pembayaran,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
