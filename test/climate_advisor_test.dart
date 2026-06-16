import 'package:flutter_test/flutter_test.dart';
import 'package:climatea/services/climate_advisor.dart';

void main() {
  group('ClimateAdvisor Tests', () {
    final advisor = ClimateAdvisor();

    test('buildAdvisory returns Unknown when weatherData is null', () {
      final result = advisor.buildAdvisory(weatherData: null, persona: 'Commuter');

      expect(result['risk'], 'Unknown');
      expect(result['headline'], 'Climate data unavailable');
    });

    test('buildAdvisory returns Low risk for good weather', () {
      final weatherData = {
        'current': {
          'temp': 22.0,
          'feelsLike': 21.0,
          'humidity': 50.0,
          'windSpeed': 5.0,
          'windGusts': 8.0,
          'weatherCode': 0,
        },
        'hourly': [
          {
            'rainProbability': 10,
            'weatherCode': 0,
            'windSpeed': 5.0,
          },
        ],
      };

      final result = advisor.buildAdvisory(weatherData: weatherData, persona: 'Commuter');

      expect(result['risk'], 'Low');
      expect(result.containsKey('headline'), true);
      expect(result.containsKey('advice'), true);
    });

    test('buildAdvisory returns High risk for extreme weather', () {
      final weatherData = {
        'current': {
          'temp': 45.0,
          'feelsLike': 48.0,
          'humidity': 90.0,
          'windSpeed': 40.0,
          'windGusts': 50.0,
          'weatherCode': 95,
        },
        'hourly': [
          {
            'rainProbability': 90,
            'weatherCode': 95,
            'windSpeed': 40.0,
          },
        ],
      };

      final result = advisor.buildAdvisory(weatherData: weatherData, persona: 'Commuter');

      expect(result['risk'], 'High');
    });

    test('buildAdvisory supports all personas', () {
      final weatherData = {
        'current': {
          'temp': 25.0,
          'feelsLike': 24.0,
          'humidity': 60.0,
          'windSpeed': 10.0,
          'windGusts': 15.0,
          'weatherCode': 1,
        },
        'hourly': [
          {
            'rainProbability': 20,
            'weatherCode': 1,
            'windSpeed': 10.0,
          },
        ],
      };

      for (final persona in ClimateAdvisor.personas) {
        final result = advisor.buildAdvisory(weatherData: weatherData, persona: persona);
        expect(result['risk'], isNotNull);
        expect(result['advice'], isNotNull);
      }
    });

    test('answerQuestion returns answer for valid question', () {
      final weatherData = {
        'current': {
          'temp': 22.0,
          'feelsLike': 21.0,
          'humidity': 50.0,
          'windSpeed': 5.0,
          'windGusts': 8.0,
          'weatherCode': 0,
        },
        'hourly': [
          {
            'rainProbability': 10,
            'weatherCode': 0,
            'windSpeed': 5.0,
          },
        ],
      };

      final answer = advisor.answerQuestion(
        weatherData: weatherData,
        persona: 'Commuter',
        question: 'Can I go for a workout?',
      );

      expect(answer, isNotEmpty);
    });

    test('answerQuestion returns null answer when weatherData is null', () {
      final answer = advisor.answerQuestion(
        weatherData: null,
        persona: 'Commuter',
        question: 'Can I go for a workout?',
      );

      expect(answer, isNotEmpty);
    });
  });
}
