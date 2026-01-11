import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tourmate_app/data/cebu_graph_data.dart';
import 'package:tourmate_app/data/tour_spot_model.dart';
import 'package:tourmate_app/utils/app_theme.dart';

class TourMapScreen extends StatefulWidget {
  final String tourId;

  const TourMapScreen({super.key, required this.tourId});

  @override
  State<TourMapScreen> createState() => _TourMapScreenState();
}

class _TourMapScreenState extends State<TourMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  TourSpot? _currentSpot;

  @override
  void initState() {
    super.initState();
    _loadTourSpot();
  }

  void _loadTourSpot() {
    final spot = CebuGraphData.getSpotById(widget.tourId);
    if (spot != null) {
      setState(() {
        _currentSpot = spot;
        _addMarker(spot);
      });
    } else {
      // Handle case where tour spot is not found
      print('Tour spot not found for ID: ${widget.tourId}');
      // You could show an error message or fallback to a default location
    }
  }

  void _addMarker(TourSpot spot) {
    final marker = Marker(
      markerId: MarkerId(spot.id),
      position: LatLng(spot.coordinate.latitude, spot.coordinate.longitude),
      infoWindow: InfoWindow(
        title: spot.name,
        snippet: spot.description,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      _markers.add(marker);
    });

    // Move camera to the marker
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(spot.coordinate.latitude, spot.coordinate.longitude),
        15.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSpot?.name ?? 'Tour Map'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _currentSpot == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Tour ID: ${widget.tourId}'),
                  const SizedBox(height: 8),
                  const Text(
                      'Location not found. This tour may not have map data.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            )
          : Builder(
              builder: (context) {
                try {
                  return GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      // Safely animate camera to the spot location
                      if (_currentSpot != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(
                              _currentSpot!.coordinate.latitude,
                              _currentSpot!.coordinate.longitude,
                            ),
                            15.0,
                          ),
                        );
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentSpot!.coordinate.latitude,
                        _currentSpot!.coordinate.longitude,
                      ),
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapType: MapType.normal,
                  );
                } catch (e) {
                  print('Error loading Google Map: $e');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Failed to load map'),
                        const SizedBox(height: 8),
                        Text('Error: $e', style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
    );
  }
}
