import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ClimateRadarScreen extends StatefulWidget {
  final Map<String, dynamic>? weatherData;
  final String selectedPersona;

  const ClimateRadarScreen({
    super.key,
    required this.weatherData,
    required this.selectedPersona,
  });

  @override
  State<ClimateRadarScreen> createState() => _ClimateRadarScreenState();
}

class _ClimateRadarScreenState extends State<ClimateRadarScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _radarTick;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: false);

    _radarTick = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _radarTick?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weatherData = widget.weatherData;

    if (weatherData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Climate Radar'),
        ),
        body: const Center(
          child: Text('Climate data unavailable'),
        ),
      );
    }

    final double latitude = _toDouble(weatherData['latitude']);
    final double longitude = _toDouble(weatherData['longitude']);
    final String cityName = weatherData['name'] ?? 'Unknown Location';

    final current = weatherData['current'] as Map<String, dynamic>? ?? {};
    final double temp = _toDouble(current['temp']);
    final double wind = _toDouble(current['windSpeed']);
    final double gust = _toDouble(current['windGusts']);
    final double rainNow = _toDouble(current['precipitation']);
    final double humidity = _toDouble(current['humidity']);

    final hourly = (weatherData['hourly'] as List<dynamic>? ?? []);
    int nextRainChance = 0;
    for (int i = 0; i < hourly.length && i < 6; i++) {
      final item = hourly[i] as Map<String, dynamic>;
      final rain = _toInt(item['rainProbability']);
      if (rain > nextRainChance) {
        nextRainChance = rain;
      }
    }

    final riskInfo = _buildRiskInfo(
      temp: temp,
      wind: wind,
      gust: gust,
      rainNow: rainNow,
      humidity: humidity,
      nextRainChance: nextRainChance,
    );

    final LatLng center = LatLng(latitude, longitude);
    final List<_ThreatPoint> nearbyPoints = _buildThreatPoints(
      center: center,
      baseRisk: riskInfo.level,
      wind: wind,
      rainChance: nextRainChance,
      temp: temp,
    );

    final double baseRadiusMeters = riskInfo.level == 'High'
        ? 3200
        : riskInfo.level == 'Medium'
        ? 2200
        : 1300;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1020),
        elevation: 0,
        title: const Text('Climate Radar'),
      ),
      body: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final pulseValue = _pulseController.value;
          final pulseRadius = baseRadiusMeters * (1 + (pulseValue * 0.20));
          final innerOpacity = 0.18 - (pulseValue * 0.08);
          final outerOpacity = 0.10 - (pulseValue * 0.06);

          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 11.8,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.climatea',
                        ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: center,
                              radius: pulseRadius,
                              useRadiusInMeter: true,
                              color: riskInfo.color.withOpacity(
                                outerOpacity.clamp(0.02, 0.14),
                              ),
                              borderStrokeWidth: 1.5,
                              borderColor: riskInfo.color.withOpacity(0.20),
                            ),
                            CircleMarker(
                              point: center,
                              radius: baseRadiusMeters,
                              useRadiusInMeter: true,
                              color: riskInfo.color.withOpacity(
                                innerOpacity.clamp(0.05, 0.22),
                              ),
                              borderStrokeWidth: 2,
                              borderColor: riskInfo.color.withOpacity(0.70),
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: center,
                              width: 110,
                              height: 72,
                              child: _userMarker(pulseValue),
                            ),
                            ...nearbyPoints.map(
                                  (point) => Marker(
                                point: point.latLng,
                                width: 118,
                                height: 72,
                                child: _threatMarker(point, pulseValue),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: _topThreatStrip(riskInfo),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF111827),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _pill(cityName, Colors.white24),
                        _pill(
                          '${widget.selectedPersona} Mode',
                          Colors.white12,
                        ),
                        _pill(
                          '${riskInfo.level} Risk',
                          riskInfo.color.withOpacity(0.22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      riskInfo.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      riskInfo.message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            'Temp',
                            '${temp.toStringAsFixed(0)}°',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _metricCard(
                            'Wind',
                            '${wind.toStringAsFixed(0)} km/h',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _metricCard('Rain', '$nextRainChance%'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Live Radar Legend',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _legendDot(const Color(0xFF22C55E), 'Stable Zone'),
                        _legendDot(const Color(0xFFF59E0B), 'Watch Zone'),
                        _legendDot(const Color(0xFFEF4444), 'Pressure Zone'),
                        _legendDot(
                          Colors.lightBlueAccent,
                          'Pulsing Radius',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _topThreatStrip(_RadarRiskInfo riskInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: riskInfo.color.withOpacity(0.55),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          _liveDot(riskInfo.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Radar Live • ${riskInfo.level} local pressure detected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveDot(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color.withOpacity(value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.55),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _userMarker(double pulseValue) {
    final glow = 6 + (pulseValue * 10);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'You',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.45),
                blurRadius: glow,
                spreadRadius: 1.5,
              ),
            ],
          ),
          child: const Icon(
            Icons.location_pin,
            color: Colors.redAccent,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _threatMarker(_ThreatPoint point, double pulseValue) {
    final glow = 5 + (pulseValue * 9);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 98),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: point.color.withOpacity(0.92),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: point.color.withOpacity(0.30),
                blurRadius: glow,
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: Text(
            point.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Icon(
          Icons.warning_amber_rounded,
          color: point.color,
          size: 22,
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _RadarRiskInfo _buildRiskInfo({
    required double temp,
    required double wind,
    required double gust,
    required double rainNow,
    required double humidity,
    required int nextRainChance,
  }) {
    String level = 'Low';
    Color color = const Color(0xFF22C55E);
    String title = 'Local conditions look fairly stable';
    String message =
        'Nothing major stands out right now. This area looks relatively manageable in the next few hours.';

    if (temp >= 38 || wind >= 30 || gust >= 40 || nextRainChance >= 70) {
      level = 'High';
      color = const Color(0xFFEF4444);
      title = 'Elevated climate pressure around you';
      message =
      'This zone shows a stronger mix of heat, wind, or rain exposure. Outdoor plans should be handled with extra care over the next few hours.';
    } else if (temp >= 33 ||
        wind >= 20 ||
        nextRainChance >= 40 ||
        humidity >= 85 ||
        rainNow > 0) {
      level = 'Medium';
      color = const Color(0xFFF59E0B);
      title = 'Some caution is worth keeping';
      message =
      'Conditions are still workable, but this area may feel less comfortable due to rising rain, humidity, or wind exposure.';
    }

    return _RadarRiskInfo(
      level: level,
      color: color,
      title: title,
      message: message,
    );
  }

  List<_ThreatPoint> _buildThreatPoints({
    required LatLng center,
    required String baseRisk,
    required double wind,
    required int rainChance,
    required double temp,
  }) {
    final double shiftKm = baseRisk == 'High'
        ? 2.4
        : baseRisk == 'Medium'
        ? 1.8
        : 1.2;

    return [
      _ThreatPoint(
        latLng: _offset(center, shiftKm, 25),
        label: rainChance >= 55 ? 'Rain Build-up' : 'Moisture Zone',
        color: rainChance >= 55
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B),
      ),
      _ThreatPoint(
        latLng: _offset(center, shiftKm + 0.4, 140),
        label: wind >= 24 ? 'Wind Corridor' : 'Breezy Stretch',
        color: wind >= 24
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B),
      ),
      _ThreatPoint(
        latLng: _offset(center, shiftKm - 0.2, 265),
        label: temp >= 35 ? 'Heat Pocket' : 'Comfort Zone',
        color: temp >= 35
            ? const Color(0xFFEF4444)
            : const Color(0xFF22C55E),
      ),
    ];
  }

  LatLng _offset(LatLng origin, double distanceKm, double bearingDegrees) {
    const double earthRadiusKm = 6371.0;
    final double bearing = bearingDegrees * math.pi / 180.0;

    final double lat1 = origin.latitude * math.pi / 180.0;
    final double lon1 = origin.longitude * math.pi / 180.0;
    final double angularDistance = distanceKm / earthRadiusKm;

    final double lat2 = math.asin(
      math.sin(lat1) * math.cos(angularDistance) +
          math.cos(lat1) * math.sin(angularDistance) * math.cos(bearing),
    );

    final double lon2 = lon1 +
        math.atan2(
          math.sin(bearing) * math.sin(angularDistance) * math.cos(lat1),
          math.cos(angularDistance) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(
      lat2 * 180.0 / math.pi,
      lon2 * 180.0 / math.pi,
    );
  }

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

class _RadarRiskInfo {
  final String level;
  final Color color;
  final String title;
  final String message;

  _RadarRiskInfo({
    required this.level,
    required this.color,
    required this.title,
    required this.message,
  });
}

class _ThreatPoint {
  final LatLng latLng;
  final String label;
  final Color color;

  _ThreatPoint({
    required this.latLng,
    required this.label,
    required this.color,
  });
}