import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class IndonesiaMapPage extends StatelessWidget {
  const IndonesiaMapPage({super.key}); //tambahan parmenter untuk  initialCenter: LatLng(-2.5, 118.0)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Indonesia'),
        centerTitle: true,
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(-2.5, 118.0), // Center of Indonesia
          initialZoom: 12.0,
          minZoom: 10.0,
          maxZoom: 25.0,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.api_test2',
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
    );
  }
}