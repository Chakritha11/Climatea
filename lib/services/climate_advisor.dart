import 'package:flutter/material.dart';

class ClimateAdvisor {
  static const List<String> personas = [
    'Commuter',
    'Farmer',
    'Construction',
    'Event Planner',
    'Traveller',
  ];

  Map<String, dynamic> buildAdvisory({
    required Map<String, dynamic>? weatherData,
    required String persona,
  }) {
    if (weatherData == null) {
      return {
        'risk': 'Unknown',
        'riskColor': Colors.blueGrey,
        'headline': 'Climate data unavailable',
        'advice':
        'I’m not getting reliable local climate data right now. Please try refreshing or search for another city.',
      };
    }

    final current = weatherData['current'] as Map<String, dynamic>;
    final hourly = weatherData['hourly'] as List<dynamic>;

    final double temp = _toDouble(current['temp']);
    final double feelsLike = _toDouble(current['feelsLike']);
    final double humidity = _toDouble(current['humidity']);
    final double wind = _toDouble(current['windSpeed']);
    final double gust = _toDouble(current['windGusts']);
    final int code = _toInt(current['weatherCode']);

    int maxRainChance = 0;
    for (int i = 0; i < hourly.length && i < 6; i++) {
      final item = hourly[i] as Map<String, dynamic>;
      final int chance = _toInt(item['rainProbability']);
      if (chance > maxRainChance) {
        maxRainChance = chance;
      }
    }

    String risk = 'Low';
    Color riskColor = const Color(0xFF1DB954);
    final List<String> reasons = [];

    if (temp >= 38 || feelsLike >= 42) {
      risk = 'High';
      riskColor = const Color(0xFFFF6B6B);
      reasons.add('Extreme heat stress');
    } else if (temp >= 33 || feelsLike >= 36) {
      risk = 'Medium';
      riskColor = const Color(0xFFFFB020);
      reasons.add('Hot outdoor conditions');
    }

    if (wind >= 30 || gust >= 40) {
      risk = 'High';
      riskColor = const Color(0xFFFF6B6B);
      reasons.add('Strong winds may affect outdoor plans');
    } else if (wind >= 20) {
      if (risk != 'High') {
        risk = 'Medium';
        riskColor = const Color(0xFFFFB020);
      }
      reasons.add('Moderate wind exposure');
    }

    if (maxRainChance >= 70 || code >= 80 || code == 61 || code == 63 || code == 65) {
      risk = 'High';
      riskColor = const Color(0xFFFF6B6B);
      reasons.add('Rain risk is quite high');
    } else if (maxRainChance >= 40) {
      if (risk != 'High') {
        risk = 'Medium';
        riskColor = const Color(0xFFFFB020);
      }
      reasons.add('Possible rain later');
    }

    if (humidity >= 85 && temp >= 30) {
      if (risk == 'Low') {
        risk = 'Medium';
        riskColor = const Color(0xFFFFB020);
      }
      reasons.add('High humidity may make it feel more uncomfortable');
    }

    final headline = _headlineForRisk(risk);

    String advice = _generalAdvice(
      temp: temp,
      feelsLike: feelsLike,
      humidity: humidity,
      wind: wind,
      rainChance: maxRainChance,
      code: code,
    );

    advice = _personaAdvice(
      persona: persona,
      temp: temp,
      feelsLike: feelsLike,
      humidity: humidity,
      wind: wind,
      rainChance: maxRainChance,
      baseAdvice: advice,
      reasons: reasons,
    );

    return {
      'risk': risk,
      'riskColor': riskColor,
      'headline': headline,
      'advice': advice,
      'reasons': reasons,
    };
  }

  String answerQuestion({
    required Map<String, dynamic>? weatherData,
    required String persona,
    required String question,
  }) {
    if (weatherData == null) {
      return 'I’m not able to answer that properly right now because the climate data is unavailable.';
    }

    final current = weatherData['current'] as Map<String, dynamic>;
    final hourly = weatherData['hourly'] as List<dynamic>;

    final double temp = _toDouble(current['temp']);
    final double wind = _toDouble(current['windSpeed']);
    final int currentRain = hourly.isNotEmpty
        ? _toInt((hourly[0] as Map<String, dynamic>)['rainProbability'])
        : 0;

    int next3hRain = 0;
    for (int i = 0; i < hourly.length && i < 3; i++) {
      final chance = _toInt((hourly[i] as Map<String, dynamic>)['rainProbability']);
      if (chance > next3hRain) next3hRain = chance;
    }

    final q = question.toLowerCase();

    if (q.contains('wedding') || q.contains('outdoor event')) {
      if (next3hRain >= 60 || wind >= 28) {
        return 'I’d be a little careful here. An outdoor setup may struggle because rain or wind risk looks fairly strong.';
      }
      if (next3hRain >= 35) {
        return 'It should be manageable, but I’d strongly keep a covered backup ready because rain is still possible.';
      }
      return 'This looks fairly safe for an outdoor event right now. Conditions seem manageable.';
    }

    if (q.contains('commute')) {
      if (next3hRain >= 60 || wind >= 30) {
        return 'Your commute may get messy. It would be smart to leave a bit earlier and expect some delay.';
      }
      if (currentRain >= 35) {
        return 'You should be okay, but keep a little buffer time and carry rain protection just in case.';
      }
      return 'Your commute looks pretty normal right now.';
    }

    if (q.contains('workout')) {
      if (temp >= 35 || wind >= 28 || next3hRain >= 50) {
        return 'Not the best window for an outdoor workout. Indoor activity or a later slot would be the safer call.';
      }
      return 'You should be fine for an outdoor workout. Just stay hydrated.';
    }

    if (q.contains('travel')) {
      if (wind >= 32 || next3hRain >= 65) {
        return 'Travel is still possible, but conditions look a bit rough. Do check routes and allow extra time.';
      }
      return 'Travel looks manageable right now.';
    }

    if (q.contains('farm') || q.contains('irrigation')) {
      if (next3hRain >= 55) {
        return 'You may want to hold irrigation for now. There’s a decent chance nature handles some of it for you soon.';
      }
      if (temp >= 34) {
        return 'Heat stress may rise today, so it’s a good idea to keep an eye on soil moisture.';
      }
      return 'Conditions look fairly stable for field planning right now.';
    }

    return 'At the moment, this looks reasonably manageable, but a little caution would still be wise depending on how conditions shift in the next few hours.';
  }

  String _headlineForRisk(String risk) {
    switch (risk) {
      case 'High':
        return 'High Climate Risk';
      case 'Medium':
        return 'A Bit of Caution Helps';
      default:
        return 'Conditions Look Fairly Stable';
    }
  }

  String _generalAdvice({
    required double temp,
    required double feelsLike,
    required double humidity,
    required double wind,
    required int rainChance,
    required int code,
  }) {
    final List<String> lines = [];

    if (temp >= 35 || feelsLike >= 38) {
      lines.add('It may feel quite harsh outdoors, especially in open areas.');
    } else if (temp <= 12) {
      lines.add('It is on the cooler side right now.');
    } else {
      lines.add('Current temperature looks fairly manageable for normal activity.');
    }

    if (rainChance >= 60 || code >= 80 || code == 61 || code == 63 || code == 65) {
      lines.add('Rain may affect comfort, visibility, and outdoor plans.');
    }

    if (wind >= 28) {
      lines.add('Wind could make travel or outdoor setups a little tricky.');
    }

    if (humidity >= 85) {
      lines.add('Humidity is high, so it may feel more tiring than the temperature alone suggests.');
    }

    if (lines.isEmpty) {
      lines.add('No major near-term climate concern stands out right now.');
    }

    return lines.join(' ');
  }

  String _personaAdvice({
    required String persona,
    required double temp,
    required double feelsLike,
    required double humidity,
    required double wind,
    required int rainChance,
    required String baseAdvice,
    required List<String> reasons,
  }) {
    switch (persona) {
      case 'Farmer':
        if (rainChance >= 55) {
          return '$baseAdvice It may be better to hold irrigation unless the soil is already too dry.';
        }
        if (temp >= 34) {
          return '$baseAdvice Crop moisture stress could build quickly today, so water planning matters.';
        }
        return '$baseAdvice Overall, this looks usable for regular farm planning.';
      case 'Construction':
        if (wind >= 28 || rainChance >= 55) {
          return '$baseAdvice Open-site work may need extra care, especially for lifting, scaffolding, or exposed surfaces.';
        }
        return '$baseAdvice Site activity looks manageable, though normal safety checks still matter.';
      case 'Event Planner':
        if (rainChance >= 40 || wind >= 24) {
          return '$baseAdvice I’d keep a fallback option ready because decor, sound, and guest comfort could be affected.';
        }
        return '$baseAdvice Conditions look fairly supportive for your event right now.';
      case 'Traveller':
        if (rainChance >= 50 || wind >= 28) {
          return '$baseAdvice A little extra buffer time would be a smart move.';
        }
        return '$baseAdvice Travel conditions seem fairly smooth right now.';
      case 'Commuter':
      default:
        if (rainChance >= 45 || wind >= 26) {
          return '$baseAdvice Leaving a little earlier would be a good idea.';
        }
        if (temp >= 34 || humidity >= 85) {
          return '$baseAdvice Carrying water and avoiding long sun exposure would help.';
        }
        return '$baseAdvice Your normal movement looks mostly fine right now.';
    }
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