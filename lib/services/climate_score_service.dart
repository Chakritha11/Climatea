import 'package:flutter/material.dart';

class ClimateScoreService {
  Map<String, dynamic> buildScore(Map<String, dynamic>? weatherData) {
    if (weatherData == null) {
      return {
        'score': 0,
        'status': 'Unavailable',
        'color': Colors.blueGrey,
        'summary':
        'I could not calculate a climate safety score right now because local data is unavailable.',
        'heatScore': 0,
        'windScore': 0,
        'humidityScore': 0,
        'heatLabel': 'Unknown',
        'windLabel': 'Unknown',
        'humidityLabel': 'Unknown',
      };
    }

    final current = weatherData['current'] as Map<String, dynamic>? ?? {};
    final hourly = weatherData['hourly'] as List<dynamic>? ?? [];

    final double temp = _toDouble(current['temp']);
    final double feelsLike = _toDouble(current['feelsLike']);
    final double humidity = _toDouble(current['humidity']);
    final double wind = _toDouble(current['windSpeed']);
    final double gust = _toDouble(current['windGusts']);

    int nextRainChance = 0;
    for (int i = 0; i < hourly.length && i < 6; i++) {
      final item = hourly[i] as Map<String, dynamic>;
      final int chance = _toInt(item['rainProbability']);
      if (chance > nextRainChance) {
        nextRainChance = chance;
      }
    }

    final int heatPenalty = _heatPenalty(temp, feelsLike);
    final int rainPenalty = _rainPenalty(nextRainChance);
    final int windPenalty = _windPenalty(wind, gust);
    final int humidityPenalty = _humidityPenalty(humidity, temp);

    int score = 100 - heatPenalty - rainPenalty - windPenalty - humidityPenalty;
    if (score < 0) score = 0;
    if (score > 100) score = 100;

    final String status;
    final Color color;
    final String summary;

    if (score >= 80) {
      status = 'Very Safe';
      color = const Color(0xFF22C55E);
      summary =
      'Conditions look supportive right now. Most outdoor plans should feel manageable.';
    } else if (score >= 65) {
      status = 'Mostly Safe';
      color = const Color(0xFF84CC16);
      summary =
      'Overall conditions look fairly usable, though a little caution may still help.';
    } else if (score >= 45) {
      status = 'Use Caution';
      color = const Color(0xFFF59E0B);
      summary =
      'Some climate pressure is building. Plans are possible, but comfort or safety may be affected.';
    } else {
      status = 'Risky';
      color = const Color(0xFFEF4444);
      summary =
      'Conditions are leaning rough right now. Outdoor activity needs extra care or a backup plan.';
    }

    return {
      'score': score,
      'status': status,
      'color': color,
      'summary': summary,
      'heatScore': 100 - heatPenalty,
      'windScore': 100 - windPenalty,
      'humidityScore': 100 - humidityPenalty,
      'heatLabel': _heatLabel(heatPenalty),
      'windLabel': _windLabel(windPenalty),
      'humidityLabel': _humidityLabel(humidityPenalty),
    };
  }

  int _heatPenalty(double temp, double feelsLike) {
    double value = feelsLike > temp ? feelsLike : temp;

    if (value >= 44) return 38;
    if (value >= 40) return 30;
    if (value >= 36) return 22;
    if (value >= 32) return 14;
    if (value <= 10) return 14;
    return 4;
  }

  int _rainPenalty(int rainChance) {
    if (rainChance >= 80) return 28;
    if (rainChance >= 60) return 20;
    if (rainChance >= 40) return 12;
    if (rainChance >= 20) return 6;
    return 2;
  }

  int _windPenalty(double wind, double gust) {
    final double effectiveWind = gust > wind ? gust : wind;

    if (effectiveWind >= 45) return 24;
    if (effectiveWind >= 35) return 18;
    if (effectiveWind >= 25) return 12;
    if (effectiveWind >= 18) return 7;
    return 2;
  }

  int _humidityPenalty(double humidity, double temp) {
    if (humidity >= 90 && temp >= 30) return 18;
    if (humidity >= 85 && temp >= 28) return 14;
    if (humidity >= 75) return 8;
    if (humidity >= 60) return 4;
    return 2;
  }

  String _heatLabel(int penalty) {
    if (penalty >= 30) return 'High';
    if (penalty >= 18) return 'Medium';
    return 'Low';
  }

  String _windLabel(int penalty) {
    if (penalty >= 18) return 'High';
    if (penalty >= 10) return 'Medium';
    return 'Low';
  }

  String _humidityLabel(int penalty) {
    if (penalty >= 14) return 'High';
    if (penalty >= 8) return 'Medium';
    return 'Low';
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