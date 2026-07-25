class Settings {
  final String id;
  double modalAwal;
  double targetKeuntungan; // Target keuntungan dalam Rupiah per tahun
  double biayaAdminPerKelipatan; // Biaya admin per kelipatan Rp 100.000 (default: Rp 25.000)
  int tahunAktif;
  String createdAt;

  Settings({
    this.id = 'main',
    this.modalAwal = 0,
    this.targetKeuntungan = 0,
    this.biayaAdminPerKelipatan = 25000,
    int? tahunAktif,
    String? createdAt,
  })  : tahunAktif = tahunAktif ?? DateTime.now().year,
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'modalAwal': modalAwal,
      'targetKeuntungan': targetKeuntungan,
      'biayaAdminPerKelipatan': biayaAdminPerKelipatan,
      'tahunAktif': tahunAktif,
      'createdAt': createdAt,
    };
  }

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      id: map['id'] ?? 'main',
      modalAwal: (map['modalAwal'] ?? 0).toDouble(),
      targetKeuntungan: (map['targetKeuntungan'] ?? map['targetKeuntunganPersen'] ?? 0).toDouble(),
      biayaAdminPerKelipatan: (map['biayaAdminPerKelipatan'] ?? 25000).toDouble(),
      tahunAktif: map['tahunAktif'] ?? DateTime.now().year,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
