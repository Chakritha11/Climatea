import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:climatea/screens/location_screen.dart';
import 'package:climatea/services/weather.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final WeatherModel weather = WeatherModel();

  @override
  void initState() {
    super.initState();
    getWeatherData();
  }

  Future<void> getWeatherData() async {
    final weatherData = await weather.getLocationAndWeather();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LocationScreen(locationWeather: weatherData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SpinKitDoubleBounce(
          color: Colors.white,
          size: 100.0,
        ),
      ),
    );
  }
}