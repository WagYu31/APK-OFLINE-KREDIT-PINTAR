class Settings {
  final String id;
  double modalAwal;
  double targetKeuntungan; // Target keuntungan dalam Rupiah per tahun
  int tahunAktif;
  String createdAt;

  Settings({
    this.id = 'main',
    this.modalAwal = 0,
    this.targetKeuntungan = 0,
    int? tahunAktif,
    String? createdAt,
  })  : tahunAktif = tahunAktif ?? DateTime.now().year,
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'modalAwal': modalAwal,
      'targetKeuntungan': targetKeuntungan,
      'tahunAktif': tahunAktif,
      'createdAt': createdAt,
    };
  }

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      id: map['id'] ?? 'main',
      modalAwal: (map['modalAwal'] ?? 0).toDouble(),
      targetKeuntungan: (map['targetKeuntungan'] ?? map['targetKeuntunganPersen'] ?? 0).toDouble(),
      tahunAktif: map['tahunAktif'] ?? DateTime.now().year,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
