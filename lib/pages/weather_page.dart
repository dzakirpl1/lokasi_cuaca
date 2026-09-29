import 'package:flutter/material.dart';

import '../models/weather_model.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../widgets/location_map.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();

  List<RegionItem> provinces = [];
  List<RegionItem> regencies = [];
  List<RegionItem> districts = [];
  List<RegionItem> villages = [];

  RegionItem? selectedProvince;
  RegionItem? selectedRegency;
  RegionItem? selectedDistrict;
  RegionItem? selectedVillage;

  List<WeatherModel> weatherList = [];

  bool loadingProvince = false;
  bool loadingRegency = false;
  bool loadingDistrict = false;
  bool loadingVillage = false;
  bool loadingWeather = false;
  bool loadingMap = false;

  String? errorMessage;

  double? mapLatitude;
  double? mapLongitude;
  String? mapLocationName;
  bool mapIsEstimate = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    setState(() {
      loadingProvince = true;
      errorMessage = null;
    });

    try {
      final result = await _locationService.getProvinces();

      if (!mounted) return;

      setState(() {
        provinces = result;
        loadingProvince = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingProvince = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _selectProvince(RegionItem item) async {
    setState(() {
      selectedProvince = item;

      selectedRegency = null;
      selectedDistrict = null;
      selectedVillage = null;

      regencies = [];
      districts = [];
      villages = [];

      weatherList = [];

      _resetMap();

      loadingRegency = true;
      errorMessage = null;
    });

    try {
      final result =
          await _locationService.getRegencies(item.code);

      if (!mounted) return;

      setState(() {
        regencies = result;
        loadingRegency = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingRegency = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _selectRegency(RegionItem item) async {
    setState(() {
      selectedRegency = item;

      selectedDistrict = null;
      selectedVillage = null;

      districts = [];
      villages = [];

      weatherList = [];

      _resetMap();

      loadingDistrict = true;
      errorMessage = null;
    });

    try {
      final result =
          await _locationService.getDistricts(item.code);

      if (!mounted) return;

      setState(() {
        districts = result;
        loadingDistrict = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingDistrict = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _selectDistrict(RegionItem item) async {
    setState(() {
      selectedDistrict = item;

      selectedVillage = null;

      villages = [];

      weatherList = [];

      _resetMap();

      loadingVillage = true;
      errorMessage = null;
    });

    try {
      final result =
          await _locationService.getVillages(item.code);

      if (!mounted) return;

      setState(() {
        villages = result;
        loadingVillage = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingVillage = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _selectVillage(RegionItem item) async {
    setState(() {
      selectedVillage = item;
      loadingWeather = true;
      loadingMap = true;
      errorMessage = null;
      weatherList = [];
      _resetMap();
    });

    try {
      final weather =
          await _weatherService.getWeather(item.code);

      if (!mounted) return;

      setState(() {
        weatherList = weather;
        loadingWeather = false;
      });

      await _loadMapLocation();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingWeather = false;
        loadingMap = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadMapLocation() async {
    if (!mounted) return;

    final target = _resolveMapTarget();

    setState(() {
      loadingMap = false;

      if (target == null) {
        return;
      }

      mapLatitude = target.item.latitude;
      mapLongitude = target.item.longitude;
      mapIsEstimate = target.isEstimate;
      mapLocationName = target.item.name;
    });
  }

  _MapTarget? _resolveMapTarget() {
    final village = selectedVillage;

    if (village != null && village.hasCoordinates) {
      return _MapTarget(
        item: village,
        isEstimate: false,
      );
    }

    for (final parent in [
      selectedDistrict,
      selectedRegency,
      selectedProvince,
    ]) {
      if (parent != null && parent.hasCoordinates) {
        return _MapTarget(
          item: parent,
          isEstimate: true,
        );
      }
    }

    return null;
  }

  void _resetMap() {
    mapLatitude = null;
    mapLongitude = null;
    mapLocationName = null;
    mapIsEstimate = false;
  }

  Future<void> _openSearch() async {
    final controller = TextEditingController();

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query =
                controller.text.trim().toLowerCase();

            List<RegionItem> source = [];

            String title = 'Cari Wilayah';

            if (selectedProvince == null) {
              source = provinces;
              title = 'Cari Provinsi';
            } else if (selectedRegency == null) {
              source = regencies;
              title = 'Cari Kabupaten / Kota';
            } else if (selectedDistrict == null) {
              source = districts;
              title = 'Cari Kecamatan';
            } else {
              source = villages;
              title = 'Cari Desa / Kelurahan';
            }

            final filtered = source.where((item) {
              return item.name.toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      onChanged: (_) {
                        setModalState(() {});
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Ketik nama wilayah...',
                        prefixIcon:
                            const Icon(Icons.search),
                        suffixIcon:
                            controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                    ),
                                    onPressed: () {
                                      controller.clear();
                                      setModalState(() {});
                                    },
                                  )
                                : null,
                        filled: true,
                        fillColor:
                            Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 50,
                                  color:
                                      Colors.grey.shade400,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  query.isEmpty
                                      ? 'Data wilayah belum tersedia'
                                      : 'Wilayah tidak ditemukan',
                                  style: TextStyle(
                                    color: Colors
                                        .grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            itemCount: filtered.length,
                            itemBuilder:
                                (context, index) {
                              final item =
                                  filtered[index];

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Colors.blue
                                          .shade50,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.blue,
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                                subtitle:
                                    Text(item.code),
                                onTap: () {
                                  Navigator.pop(
                                    context,
                                  );

                                  if (selectedProvince ==
                                      null) {
                                    _selectProvince(
                                      item,
                                    );
                                  } else if (
                                      selectedRegency ==
                                          null) {
                                    _selectRegency(
                                      item,
                                    );
                                  } else if (
                                      selectedDistrict ==
                                          null) {
                                    _selectDistrict(
                                      item,
                                    );
                                  } else {
                                    _selectVillage(
                                      item,
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showRegionPicker({
    required String title,
    required List<RegionItem> items,
    required Function(RegionItem) onSelected,
  }) async {
    final controller = TextEditingController();

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query =
                controller.text.trim().toLowerCase();

            final filteredItems = items.where((item) {
              return item.name.toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height *
                  0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      12,
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      onChanged: (_) {
                        setModalState(() {});
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Cari $title...',
                        prefixIcon:
                            const Icon(Icons.search),
                        suffixIcon:
                            controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                    ),
                                    onPressed: () {
                                      controller.clear();
                                      setModalState(() {});
                                    },
                                  )
                                : null,
                        filled: true,
                        fillColor:
                            Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Text(
                              'Wilayah tidak ditemukan',
                              style: TextStyle(
                                color:
                                    Colors.grey.shade600,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount:
                                filteredItems.length,
                            itemBuilder:
                                (context, index) {
                              final item =
                                  filteredItems[index];

                              return ListTile(
                                leading: const Icon(
                                  Icons.location_on,
                                ),
                                title: Text(item.name),
                                subtitle:
                                    Text(item.code),
                                onTap: () {
                                  Navigator.pop(
                                    context,
                                  );
                                  onSelected(item);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Widget _buildSelector({
    required String title,
    required RegionItem? selected,
    required List<RegionItem> items,
    required bool enabled,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled && !loading ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? Colors.grey.shade300
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: enabled
                  ? Colors.blue
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selected?.name ??
                        (enabled
                            ? 'Pilih $title'
                            : 'Pilih wilayah sebelumnya'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
              const Icon(
                Icons.keyboard_arrow_down,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return InkWell(
      onTap: _openSearch,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedVillage != null
                    ? selectedVillage!.name
                    : 'Cari wilayah...',
                style: TextStyle(
                  fontSize: 15,
                  color: selectedVillage != null
                      ? Colors.black87
                      : Colors.grey.shade600,
                ),
              ),
            ),
            const Icon(
              Icons.tune,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.blue.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade700,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Tentang Prakiraan Cuaca',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prakiraan cuaca di bawah ini berasal '
                  'dari data BMKG berdasarkan wilayah '
                  'desa atau kelurahan yang kamu pilih.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Data dapat berubah mengikuti pembaruan '
                  'prakiraan cuaca dari BMKG.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(WeatherModel weather) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          if (weather.imageUrl.isNotEmpty)
            SizedBox(
              width: 65,
              height: 65,
              child: Image.network(
                weather.imageUrl,
                fit: BoxFit.contain,
                errorBuilder:
                    (context, error, stackTrace) {
                  return const Icon(
                    Icons.cloud,
                    size: 45,
                  );
                },
              ),
            )
          else
            const SizedBox(
              width: 65,
              height: 65,
              child: Icon(
                Icons.cloud,
                size: 45,
              ),
            ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateTime(weather.datetime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weather.weather,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.thermostat,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${weather.temperature.toStringAsFixed(0)}°C',
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.water_drop,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${weather.humidity}%',
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.air,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${weather.windSpeed.toStringAsFixed(1)} km/j',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherByDay() {
    if (weatherList.isEmpty) {
      return const SizedBox.shrink();
    }

    final Map<String, List<WeatherModel>> grouped = {};

    for (final weather in weatherList) {
      final key =
          '${weather.datetime.year}-'
          '${weather.datetime.month}-'
          '${weather.datetime.day}';

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(weather);
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        final first = entry.value.first;

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 18,
                bottom: 10,
              ),
              child: Text(
                _formatDate(first.datetime),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...entry.value.map(
              (weather) =>
                  _buildWeatherCard(weather),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMapSection() {
    if (loadingMap) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Menyiapkan peta...'),
            ],
          ),
        ),
      );
    }

    if (mapLatitude == null ||
        mapLongitude == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 45,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 10),
            const Text(
              'Koordinat wilayah ini belum tersedia',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Data cuaca tetap dapat ditampilkan '
              'meskipun titik peta tidak tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return LocationMap(
      latitude: mapLatitude!,
      longitude: mapLongitude!,
      locationName:
          mapLocationName ?? 'Lokasi terpilih',
      isEstimate: mapIsEstimate,
    );
  }

  String _formatDateTime(DateTime date) {
    final hour =
        date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');

    return '${_formatDate(date)} • $hour:$minute';
  }

  String _formatDate(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${days[date.weekday - 1]}, '
        '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f9fc),
      appBar: AppBar(
        title: const Text(
          'Prakiraan Cuaca',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProvinces,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            30,
          ),
          children: [
            const Text(
              'Cek Cuaca Wilayah',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Pilih wilayah untuk melihat prakiraan '
              'cuaca berdasarkan data BMKG.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 18),

            // SEARCH BAR UTAMA
            _buildSearchBar(),

            const SizedBox(height: 20),

            // PILIH PROVINSI
            _buildSelector(
              title: 'Provinsi',
              selected: selectedProvince,
              items: provinces,
              enabled: provinces.isNotEmpty,
              loading: loadingProvince,
              onTap: () {
                _showRegionPicker(
                  title: 'Provinsi',
                  items: provinces,
                  onSelected: _selectProvince,
                );
              },
            ),

            const SizedBox(height: 12),

            // PILIH KABUPATEN / KOTA
            _buildSelector(
              title: 'Kabupaten / Kota',
              selected: selectedRegency,
              items: regencies,
              enabled: selectedProvince != null,
              loading: loadingRegency,
              onTap: () {
                _showRegionPicker(
                  title: 'Kabupaten / Kota',
                  items: regencies,
                  onSelected: _selectRegency,
                );
              },
            ),

            const SizedBox(height: 12),

            // PILIH KECAMATAN
            _buildSelector(
              title: 'Kecamatan',
              selected: selectedDistrict,
              items: districts,
              enabled: selectedRegency != null,
              loading: loadingDistrict,
              onTap: () {
                _showRegionPicker(
                  title: 'Kecamatan',
                  items: districts,
                  onSelected: _selectDistrict,
                );
              },
            ),

            const SizedBox(height: 12),

            // PILIH DESA / KELURAHAN
            _buildSelector(
              title: 'Desa / Kelurahan',
              selected: selectedVillage,
              items: villages,
              enabled: selectedDistrict != null,
              loading: loadingVillage,
              onTap: () {
                _showRegionPicker(
                  title: 'Desa / Kelurahan',
                  items: villages,
                  onSelected: _selectVillage,
                );
              },
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius:
                      BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.red.shade100,
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (selectedVillage != null) ...[
              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              Colors.blue.shade50,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Lokasi Terpilih',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedVillage!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${selectedDistrict?.name ?? ''}, '
                      '${selectedRegency?.name ?? ''}, '
                      '${selectedProvince?.name ?? ''}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ADM4: ${selectedVillage!.code}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // KETERANGAN PRAKIRAAN
              _buildWeatherInfo(),

              const SizedBox(height: 22),

              // JUDUL PRAKIRAAN
              const Text(
                'Prakiraan Cuaca',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Perkiraan kondisi cuaca berdasarkan '
                'waktu untuk wilayah yang dipilih.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 10),

              if (loadingWeather)
                const Padding(
                  padding: EdgeInsets.all(35),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          'Mengambil data cuaca BMKG...',
                        ),
                      ],
                    ),
                  ),
                )
              else if (weatherList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Data prakiraan cuaca belum tersedia.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                _buildWeatherByDay(),

              const SizedBox(height: 28),

              // MAP
              const Text(
                'Lokasi di Peta',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Titik peta memakai titik tengah (centroid) '
                'wilayah desa atau kelurahan dari data BIG.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 12),

              _buildMapSection(),

              const SizedBox(height: 8),

              Text(
                'Peta: © OpenStreetMap contributors • '
                'Data wilayah: emsifa.com',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapTarget {
  final RegionItem item;
  final bool isEstimate;

  const _MapTarget({
    required this.item,
    required this.isEstimate,
  });
}
