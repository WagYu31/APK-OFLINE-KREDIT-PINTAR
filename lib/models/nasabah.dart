class Nasabah {
  int? id;
  String nama;
  String nomorTelpon;
  bool kartuKuning;
  bool kartuMerah;
  bool diblokir;
  String createdAt;

  Nasabah({
    this.id,
    required this.nama,
    required this.nomorTelpon,
    this.kartuKuning = false,
    this.kartuMerah = false,
    this.diblokir = false,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama': nama,
      'nomorTelpon': nomorTelpon,
      'kartuKuning': kartuKuning ? 1 : 0,
      'kartuMerah': kartuMerah ? 1 : 0,
      'diblokir': diblokir ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory Nasabah.fromMap(Map<String, dynamic> map) {
    return Nasabah(
      id: map['id'],
      nama: map['nama'] ?? '',
      nomorTelpon: map['nomorTelpon'] ?? '',
      kartuKuning: map['kartuKuning'] == 1,
      kartuMerah: map['kartuMerah'] == 1,
      diblokir: map['diblokir'] == 1,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Nasabah copyWith({
    int? id,
    String? nama,
    String? nomorTelpon,
    bool? kartuKuning,
    bool? kartuMerah,
    bool? diblokir,
  }) {
    return Nasabah(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      nomorTelpon: nomorTelpon ?? this.nomorTelpon,
      kartuKuning: kartuKuning ?? this.kartuKuning,
      kartuMerah: kartuMerah ?? this.kartuMerah,
      diblokir: diblokir ?? this.diblokir,
      createdAt: createdAt,
    );
  }
}
