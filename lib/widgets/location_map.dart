  import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String locationName;
  final bool isEstimate;

  const LocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.isEstimate = false,
  });

  @override
  Widget build(BuildContext context) {
    final position = LatLng(
      latitude,
      longitude,
    );

    return Container(
      height: 350,
      margin: const EdgeInsets.only(
        top: 12,
        bottom: 20,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: position,
                initialZoom: isEstimate ? 11 : 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.example.api_test2',
                ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: position,
                      width: 60,
                      height: 70,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 45,
                          ),
                          Expanded(
                            child: Text(
                              locationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                    ),
                  ],
                ),
              ],
            ),

            if (isEstimate)
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Titik perkiraan area kecamatan — '
                      'koordinat desa belum tersedia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}