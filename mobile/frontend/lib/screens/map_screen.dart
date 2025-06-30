import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EnhancedMapScreen extends StatefulWidget {
  const EnhancedMapScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedMapScreen> createState() => _EnhancedMapScreenState();
}

class _EnhancedMapScreenState extends State<EnhancedMapScreen> with TickerProviderStateMixin {
  LatLng? currentLocation;
  LatLng? selectedLocation;
  String selectedPlace = '';
  bool isLoading = false;
  bool showSearch = false;
  
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  
  List<SearchResult> searchResults = [];
  List<Marker> markers = [];
  
  // Animation controllers
  late AnimationController _searchAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _searchAnimation;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadLastPosition();
    _getCurrentLocation();
  }

  void _setupAnimations() {
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    
    _fabAnimationController.forward();
  }

  Future<void> _loadLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('last_map_lat');
    final lng = prefs.getDouble('last_map_lng');
    final zoom = prefs.getDouble('last_map_zoom') ?? 13.0;

    if (lat != null && lng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(LatLng(lat, lng), zoom);
      });
    }
  }

  Future<void> _saveLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final center = mapController.center;
    await prefs.setDouble('last_map_lat', center.latitude);
    await prefs.setDouble('last_map_lng', center.longitude);
    await prefs.setDouble('last_map_zoom', mapController.zoom);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoading = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permissions are denied.');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        _updateMarkers();
      });
      
      mapController.move(currentLocation!, 15.0);
    } catch (e) {
      _showSnackBar('Failed to get location: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _updateMarkers() {
    markers.clear();
    
    if (currentLocation != null) {
      markers.add(
        Marker(
          point: currentLocation!,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }
    
    if (selectedLocation != null) {
      markers.add(
        Marker(
          point: selectedLocation!,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _getPlaceName(LatLng point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> components = [];
        
        if (place.name?.isNotEmpty == true && place.name != place.street) {
          components.add(place.name!);
        }
        if (place.thoroughfare?.isNotEmpty == true) {
          components.add(place.thoroughfare!);
        }
        if (place.subLocality?.isNotEmpty == true) {
          components.add(place.subLocality!);
        }
        if (place.locality?.isNotEmpty == true) {
          components.add(place.locality!);
        }
        if (place.administrativeArea?.isNotEmpty == true) {
          components.add(place.administrativeArea!);
        }
        
        setState(() {
          selectedLocation = point;
          selectedPlace = components.isNotEmpty 
              ? components.join(', ') 
              : 'Unknown location';
          _updateMarkers();
        });
      }
    } catch (e) {
      setState(() {
        selectedLocation = point;
        selectedPlace = 'Location details unavailable';
        _updateMarkers();
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() => searchResults.clear());
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1'
        ),
        headers: {'User-Agent': 'Flutter Map App'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          searchResults = data.map((item) => SearchResult.fromJson(item)).toList();
        });
      }
    } catch (e) {
      _showSnackBar('Search failed: $e');
    }
  }

  void _selectSearchResult(SearchResult result) {
    final point = LatLng(result.lat, result.lon);
    mapController.move(point, 15.0);
    _getPlaceName(point);
    _toggleSearch();
    searchController.clear();
    setState(() => searchResults.clear());
  }

  void _toggleSearch() {
    setState(() {
      showSearch = !showSearch;
      if (showSearch) {
        _searchAnimationController.forward();
        _fabAnimationController.reverse();
        searchFocusNode.requestFocus();
      } else {
        _searchAnimationController.reverse();
        _fabAnimationController.forward();
        searchController.clear();
        searchResults.clear();
        searchFocusNode.unfocus();
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _fabAnimationController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: LatLng(36.7528, 3.0422),
              zoom: 13.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) => _getPlaceName(point),
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) _saveLastPosition();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.enhanced_map',
                maxZoom: 19,
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Search Bar
          AnimatedBuilder(
            animation: _searchAnimation,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Transform.translate(
                  offset: Offset(0, -60 * (1 - _searchAnimation.value)),
                  child: Opacity(
                    opacity: _searchAnimation.value,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[900],
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: searchController,
                                    focusNode: searchFocusNode,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: 'Search places...',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: _searchPlaces,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey),
                                  onPressed: _toggleSearch,
                                ),
                              ],
                            ),
                          ),
                          if (searchResults.isNotEmpty)
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  final result = searchResults[index];
                                  return ListTile(
                                    leading: const Icon(Icons.location_on, color: Colors.grey),
                                    title: Text(
                                      result.displayName,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _selectSearchResult(result),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Location Info Panel
          if (selectedPlace.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Selected Location',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                          onPressed: () {
                            setState(() {
                              selectedPlace = '';
                              selectedLocation = null;
                              _updateMarkers();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedPlace,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (selectedLocation != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${selectedLocation!.latitude.toStringAsFixed(6)}, ${selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Loading Indicator
          if (isLoading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Search FAB
          AnimatedBuilder(
            animation: _fabAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _fabAnimation.value,
                child: FloatingActionButton(
                  heroTag: "search",
                  backgroundColor: Colors.grey[800],
                  onPressed: showSearch ? null : _toggleSearch,
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Location FAB
          AnimatedBuilder(
            animation: _fabAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _fabAnimation.value,
                child: FloatingActionButton(
                  heroTag: "location",
                  backgroundColor: Colors.blue,
                  onPressed: showSearch ? null : () {
                    if (currentLocation != null) {
                      mapController.move(currentLocation!, 15.0);
                    } else {
                      _getCurrentLocation();
                    }
                  },
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SearchResult {
  final String displayName;
  final double lat;
  final double lon;

  SearchResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      displayName: json['display_name'] ?? '',
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
    );
  }
}