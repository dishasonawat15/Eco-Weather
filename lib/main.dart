import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const EcoWeatherApp());
}

class WeatherService {
  static const String apiKey = 'YOUR_OPENWEATHER_API_KEY';
  static const String _weatherUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const String _pollutionUrl = 'https://api.openweathermap.org/data/2.5/air_pollution';

  Future getWeather(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('$_weatherUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
      );
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_weather', response.body);
        return json.decode(response.body);
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('last_weather');
      if (cachedData != null) return json.decode(cachedData);
    }
    return null;
  }

  Future getWeatherByCity(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$_weatherUrl?q=$city&appid=$apiKey&units=metric'),
      );
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {
      debugPrint("Error: $e");
    }
    return null;
  }

  Future getPollution(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('$_pollutionUrl?lat=$lat&lon=$lon&appid=$apiKey'),
      );
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {
      debugPrint("Error: $e");
    }
    return null;
  }
}

class EcoWeatherApp extends StatelessWidget {
  const EcoWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco Weather Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _searchController = TextEditingController();
  Map? _weatherData;
  Map? _pollutionData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchLocalWeather();
  }

  Future<void> _fetchLocalWeather() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final weather = await _weatherService.getWeather(
        position.latitude,
        position.longitude,
      );
      final pollution = await _weatherService.getPollution(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _weatherData = weather;
        _pollutionData = pollution;
        _isLoading = false;
      });

      if (pollution != null) {
        final aqi = pollution['list'][0]['main']['aqi'];
        if (aqi != null) NotificationService.showPollutionAlert(aqi as int);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchCity(String cityName) async {
    if (cityName.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final weather = await _weatherService.getWeatherByCity(cityName);
      if (weather != null) {
        final lat = weather['coord']['lat'];
        final lon = weather['coord']['lon'];
        final pollution = await _weatherService.getPollution(lat, lon);
        setState(() {
          _weatherData = weather;
          _pollutionData = pollution;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'City not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Eco Weather Dashboard',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchLocalWeather();
            },
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_weatherData == null) {
      return const Center(child: Text("No data available"));
    }

    final cityName = _weatherData!['name'];
    final temp = _weatherData!['main']['temp'].round();
    final feelsLike = _weatherData!['main']['feels_like'].round();
    final condition =
        _weatherData!['weather'][0]['description'].toString().toUpperCase();
    final humidity = _weatherData!['main']['humidity'];
    final pressure = _weatherData!['main']['pressure'];
    final visibilityKm = _weatherData!['visibility'] / 1000;
    final visibility = visibilityKm.toStringAsFixed(1);
    final windSpeed = _weatherData!['wind']['speed'];
    final aqi =
        _pollutionData != null ? _pollutionData!['list'][0]['main']['aqi'] : 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search city...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (val) => _searchCity(val),
          ),
          const SizedBox(height: 16),

          // Main Hero Weather Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cityName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  condition,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$temp°C',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(
                      Icons.wb_sunny_rounded,
                      size: 80,
                      color: Colors.amber,
                    ),
                  ],
                ),
                Text(
                  'Feels like $feelsLike°C',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dashboard Metric Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildMetricCard(
                'AIR QUALITY (AQI)',
                '$aqi / 5',
                aqi <= 2 ? 'Good' : 'Moderate/Poor',
                Icons.air,
              ),
              _buildMetricCard(
                'WIND SPEED',
                '$windSpeed m/s',
                'Light Breeze',
                Icons.air,
              ),
              _buildMetricCard(
                'HUMIDITY',
                '$humidity%',
                'Normal dew point',
                Icons.water_drop,
              ),
              _buildMetricCard(
                'VISIBILITY',
                '$visibility km',
                visibilityKm > 5 ? 'Clear view' : 'Hazy',
                Icons.visibility,
              ),
              _buildMetricCard(
                'PRESSURE',
                '$pressure hPa',
                'Stable condition',
                Icons.speed,
              ),
              _buildMetricCard(
                'UV INDEX',
                '3.2',
                'Low risk',
                Icons.wb_sunny,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: Colors.blueAccent, size: 18),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}