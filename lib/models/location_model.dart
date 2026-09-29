class LocationModel {
  final String adm1;
  final String adm2;
  final String adm3;
  final String adm4;

  final String provinsi;
  final String kabupaten;
  final String kecamatan;
  final String desa;

  LocationModel({
    required this.adm1,
    required this.adm2,
    required this.adm3,
    required this.adm4, 
    required this.provinsi,
    required this.kabupaten,
    required this.kecamatan,
    required this.desa,
  });

  factory LocationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return LocationModel(
      adm1: json['adm1']?.toString() ?? '',
      adm2: json['adm2']?.toString() ?? '',
      adm3: json['adm3']?.toString() ?? '',
      adm4: json['adm4']?.toString() ?? '',
      provinsi: json['provinsi']?.toString() ?? '',
      kabupaten:
          json['kabkot']?.toString() ??
          json['kabupaten']?.toString() ??
          '',
      kecamatan:
          json['kec']?.toString() ??
          json['kecamatan']?.toString() ??
          '',
      desa: json['desa']?.toString() ?? '',
    );
  }
  //langtitud dan nadtidtud nya

  String get fullName {
    final parts = [
      desa,
      kecamatan,
      kabupaten,
      provinsi,
    ];

    return parts
        .where(
          (item) => item.isNotEmpty,
        )
        .join(', ');
  }
}