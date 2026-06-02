class Personel {
  final String id;
  final String adSoyad;
  final String eposta;
  final String rol;
  final bool aktif;
  final String? authUserId;
  final bool iptal;
  final DateTime createdAt;

  Personel({
    required this.id,
    required this.adSoyad,
    required this.eposta,
    required this.rol,
    this.aktif = true,
    this.authUserId,
    this.iptal = false,
    required this.createdAt,
  });

  /// Yönetici veya muhasebe rolü kontrolü
  bool get isYonetici => rol == 'yonetici' || rol == 'muhasebe';

  /// Saha personeli kontrolü
  bool get isSaha => rol == 'saha';

  factory Personel.fromJson(Map<String, dynamic> json) {
    return Personel(
      id: json['id'] as String,
      adSoyad: json['ad_soyad'] as String,
      eposta: json['eposta'] as String,
      rol: json['rol'] as String,
      aktif: json['aktif'] as bool? ?? true,
      authUserId: json['auth_user_id'] as String?,
      iptal: json['iptal'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad_soyad': adSoyad,
      'eposta': eposta,
      'rol': rol,
      'aktif': aktif,
      'auth_user_id': authUserId,
      'iptal': iptal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Personel copyWith({
    String? id,
    String? adSoyad,
    String? eposta,
    String? rol,
    bool? aktif,
    String? authUserId,
    bool? iptal,
    DateTime? createdAt,
  }) {
    return Personel(
      id: id ?? this.id,
      adSoyad: adSoyad ?? this.adSoyad,
      eposta: eposta ?? this.eposta,
      rol: rol ?? this.rol,
      aktif: aktif ?? this.aktif,
      authUserId: authUserId ?? this.authUserId,
      iptal: iptal ?? this.iptal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Personel(id: $id, adSoyad: $adSoyad, rol: $rol)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Personel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
