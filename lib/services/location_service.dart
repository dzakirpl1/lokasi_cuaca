import 'dart:convert';

import 'package:http/http.dart' as http;

class RegionItem {
  final String code;
  final String name;

  const RegionItem({
    required this.code,
    required this.name,
    // nambahin variable langtitud dan nadtidtud nya
  });

  factory RegionItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return RegionItem(
      code: json['code']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class LocationService {
  static const String _baseUrl =
      '/v2';

  Future<List<RegionItem>> getProvinces() async {
    return _getList(
      '$_baseUrl/provinces.json',
    );
  }

  Future<List<RegionItem>> getRegencies(
    String provinceCode,
  ) async {
    return _getList(
      '$_baseUrl/regencies/$provinceCode.json',
    );
  }

  Future<List<RegionItem>> getDistricts(
    String regencyCode,
  ) async {
    return _getList(
      '$_baseUrl/districts/$regencyCode.json',
    );
  }

  Future<List<RegionItem>> getVillages(
    String districtCode,
  ) async {
    return _getList(
      '$_baseUrl/villages/$districtCode.json',
    );
  }

  Future<List<RegionItem>> _getList(
    String url,
  ) async {
    final response = await http.get(
      Uri.parse(url),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data wilayah. '
        'Status: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    List<dynamic> data;

    if (decoded is Map<String, dynamic> &&
        decoded['data'] is List) {
      data = decoded['data'];
    } else if (decoded is List) {
      data = decoded;
    } else {
      throw Exception(
        'Format data wilayah tidak valid.',
      );
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => RegionItem.fromJson(item),
        )
        .where(
          (item) =>
              item.code.isNotEmpty &&
              item.name.isNotEmpty,
        )
        .toList();
  }
}