import 'package:flutter_test/flutter_test.dart';
import 'package:climatea/services/climate_score_service.dart';

void main() {
  group('ClimateScoreService Tests', () {
    final service = ClimateScoreService();

    test('buildScore returns Unavailable when weatherData is null', () {
      final result = service.buildScore(null);

      expect(result['status'], 'Unavailable');
      expect(result['score'], 0);
    });

    test('buildScore calculates score for normal weather', () {
      final weatherData = {
        'current': {
          'temp': 22.0,
          'feelsLike': 21.0,
          'humidity': 60.0,
          'windSpeed': 5.0,
          'windGusts': 8.0,
          'precipitation': 0.0,
          'weatherCode': 0,
          'isDay': 1,
        },
        'hourly': [
          {
            'rainProbability': 10,
            'weatherCode': 0,
            'windSpeed': 5.0,
          },
          {
            'rainProbability': 5,
            'weatherCode': 0,
            'windSpeed': 4.0,
          },
        ],
      };

      final result = service.buildScore(weatherData);

      expect(result['score'], isNotNull);
      expect(result['status'], isNotNull);
      expect(result['color'], isNotNull);
    });

    test('buildScore returns High risk for extreme heat', () {
      final weatherData = {
        'current': {
          'temp': 45.0,
          'feelsLike': 48.0,
          'humidity': 80.0,
          'windSpeed': 5.0,
          'windGusts': 8.0,
          'precipitation': 0.0,
          'weatherCode': 0,
          'isDay': 1,
        },
        'hourly': [],
      };

      final result = service.buildScore(weatherData);

      expect(result['score'], lessThanOrEqualTo(50));
    });

    test('buildScore returns score with all fields', () {
      final weatherData = {
        'current': {
          'temp': 25.0,
          'feelsLike': 24.0,
          'humidity': 50.0,
          'windSpeed': 10.0,
          'windGusts': 15.0,
          'precipitation': 0.0,
          'weatherCode': 1,
          'isDay': 1,
        },
        'hourly': [
          {
            'rainProbability': 20,
            'weatherCode': 1,
            'windSpeed': 10.0,
          },
        ],
      };

      final result = service.buildScore(weatherData);

      expect(result.containsKey('score'), true);
      expect(result.containsKey('status'), true);
      expect(result.containsKey('color'), true);
      expect(result.containsKey('heatScore'), true);
      expect(result.containsKey('windScore'), true);
      expect(result.containsKey('humidityScore'), true);
    });
  });
}
