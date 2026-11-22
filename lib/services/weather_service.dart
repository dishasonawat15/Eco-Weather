import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  // Paste your API key right here between the quotes!
  static const String _apiKey = 'fa86352a9062ea631bf705456e53f0b9';
  static const String _weatherUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const String _pollutionUrl = 'https://api.openweathermap.org/data/2.5/air_pollution';

  Future getWeather(double lat, double lon) async {
    try {
      final response = await http.get(Uri.parse('$_weatherUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric'));
      
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_weather', response.body);
        return json.decode(response.body);
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('last_weather');
      if (cachedData != null) {
        return json.decode(cachedData);
      }
    }
    return null;
  }

  // 🌟 NEW: Fetch weather by typing a city name!
  Future getWeatherByCity(String city) async {
    try {
      final response = await http.get(Uri.parse('$_weatherUrl?q=$city&appid=$_apiKey&units=metric'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Error fetching city: $e");
    }
    return null;
  }

  Future getPollution(double lat, double lon) async {
    try {
      final response = await http.get(Uri.parse('$_pollutionUrl?lat=$lat&lon=$lon&appid=$_apiKey'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Error fetching pollution data: $e");
    }
    return null;
  }
}