import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherModel {
  Future<Map<String, dynamic>?> getCityWeather(String cityName) async {
    try {
      if (cityName.trim().isEmpty) return null;

      final geoUrl = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(cityName)}&count=1&language=en&format=json',
      );

      final geoResponse = await http.get(geoUrl);

      if (geoResponse.statusCode != 200) {
        print('Geocoding failed: ${geoResponse.statusCode}');
        return null;
      }

      final geoData = jsonDecode(geoResponse.body);
      final results = geoData['results'];

      if (results == null || results.isEmpty) {
        print('No city found.');
        return null;
      }

      final first = results[0];
      final double latitude = (first['latitude'] as num).toDouble();
      final double longitude = (first['longitude'] as num).toDouble();
      final String name = first['name'] ?? cityName;
      final String? country = first['country'];

      return await _fetchForecast(
        latitude: latitude,
        longitude: longitude,
        cityName: country != null ? '$name, $country' : name,
      );
    } catch (e) {
      print('Error in getCityWeather: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLocationAndWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied.');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return await _fetchForecast(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: 'Your Location',
      );
    } catch (e) {
      print('Error in getLocationAndWeather: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchForecast({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    try {
      final forecastUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
            '?latitude=$latitude'
            '&longitude=$longitude'
            '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_gusts_10m,is_day,precipitation'
            '&hourly=temperature_2m,precipitation_probability,weather_code,wind_speed_10m,relative_humidity_2m'
            '&timezone=auto'
            '&forecast_days=1',
      );

      final response = await http.get(forecastUrl);

      if (response.statusCode != 200) {
        print('Forecast failed: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);

      final current = data['current'];
      final hourly = data['hourly'];

      if (current == null || hourly == null) {
        return null;
      }

      final List<dynamic> times = hourly['time'] ?? [];
      final List<dynamic> temps = hourly['temperature_2m'] ?? [];
      final List<dynamic> rainProb = hourly['precipitation_probability'] ?? [];
      final List<dynamic> weatherCodes = hourly['weather_code'] ?? [];
      final List<dynamic> windSpeeds = hourly['wind_speed_10m'] ?? [];
      final List<dynamic> humidity = hourly['relative_humidity_2m'] ?? [];

      final List<Map<String, dynamic>> hourlyData = [];

      for (int i = 0; i < times.length; i++) {
        hourlyData.add({
          'time': times[i],
          'temp': i < temps.length ? temps[i] : null,
          'rainProbability': i < rainProb.length ? rainProb[i] : null,
          'weatherCode': i < weatherCodes.length ? weatherCodes[i] : null,
          'windSpeed': i < windSpeeds.length ? windSpeeds[i] : null,
          'humidity': i < humidity.length ? humidity[i] : null,
        });
      }

      return {
        'name': cityName,
        'latitude': latitude,
        'longitude': longitude,
        'current': {
          'temp': current['temperature_2m'],
          'humidity': current['relative_humidity_2m'],
          'feelsLike': current['apparent_temperature'],
          'weatherCode': current['weather_code'],
          'windSpeed': current['wind_speed_10m'],
          'windGusts': current['wind_gusts_10m'],
          'precipitation': current['precipitation'],
          'isDay': current['is_day'],
          'time': current['time'],
        },
        'hourly': hourlyData,
      };
    } catch (e) {
      print('Error in _fetchForecast: $e');
      return null;
    }
  }

  String getWeatherIcon(int code, bool isDay) {
    if (code == 0) return isDay ? '☀️' : '🌙';
    if (code == 1 || code == 2) return isDay ? '🌤' : '☁️';
    if (code == 3) return '☁️';
    if (code == 45 || code == 48) return '🌫';
    if (code == 51 || code == 53 || code == 55) return '🌦';
    if (code == 61 || code == 63 || code == 65) return '🌧';
    if (code == 66 || code == 67) return '🌧';
    if (code == 71 || code == 73 || code == 75) return '❄️';
    if (code == 77) return '🌨';
    if (code == 80 || code == 81 || code == 82) return '⛈';
    if (code == 85 || code == 86) return '❄️';
    if (code == 95 || code == 96 || code == 99) return '🌩';
    return '🌍';
  }

  String getWeatherLabel(int code) {
    switch (code) {
      case 0:
        return 'Clear';
      case 1:
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Cloudy';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 66:
      case 67:
        return 'Freezing Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 77:
        return 'Snow Grains';
      case 80:
      case 81:
      case 82:
        return 'Rain Showers';
      case 85:
      case 86:
        return 'Snow Showers';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }
}