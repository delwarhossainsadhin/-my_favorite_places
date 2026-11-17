import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/favorite_location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  final List<FavoriteLocation> favoriteLocations = [
    FavoriteLocation(
      id: 1,
      name: 'Ahsan Manzil',
      latitude: 23.7086,
      longitude: 90.4060,
    ),
    FavoriteLocation(
      id: 2,
      name: "Cox's Bazar",
      latitude: 21.4272,
      longitude: 91.9702,
    ),
    FavoriteLocation(
      id: 3,
      name: 'Sundarbans',
      latitude: 21.9497,
      longitude: 89.1833,
    ),
  ];

  Position? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.'),
          ),
        );
      }
      return;
    }

    // When permissions are granted, get the current position
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    if (mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    await _determinePosition();

    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0, // Zoom level
      );
    }

    setState(() {
      _isLoadingLocation = false;
    });
  }

  void _showLocationDetails(FavoriteLocation location) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    location.id.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  location.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle:
                    Text('Lat: ${location.latitude}\\nLng: ${location.longitude}'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> mapMarkers = favoriteLocations.map((location) {
      return Marker(
        point: LatLng(location.latitude, location.longitude),
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _showLocationDetails(location),
          child: const Icon(
            Icons.location_on,
            size: 40,
            color: Colors.red,
          ),
        ),
      );
    }).toList();

    // Add current location marker if available
    if (_currentPosition != null) {
      mapMarkers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 60,
          height: 60,
          child: const Icon(
            Icons.my_location,
            size: 35,
            color: Colors.blue,
          ),
        ),
      );
    }

    return mapMarkers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorite Places'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(23.6850, 90.3563), // Center of Bangladesh
          initialZoom: 6.5,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.my_favorite_places',
          ),
          MarkerLayer(
            markers: _buildMarkers(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoadingLocation ? null : _goToCurrentLocation,
        label: _isLoadingLocation
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('My Location'),
        icon: _isLoadingLocation ? null : const Icon(Icons.my_location),
      ),
    );
  }
}
