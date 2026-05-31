import 'package:flutter/material.dart';
import 'package:climatea/screens/city_screen.dart';
import 'package:climatea/screens/climate_radar_screen.dart';
import 'package:climatea/services/climate_advisor.dart';
import 'package:climatea/services/climate_score_service.dart';
import 'package:climatea/services/grog_advisor.dart';
import 'package:climatea/services/weather.dart';
import 'package:climatea/utilities/constants.dart';

class LocationScreen extends StatefulWidget {
  final dynamic locationWeather;

  const LocationScreen({super.key, this.locationWeather});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final WeatherModel weather = WeatherModel();
  final ClimateAdvisor advisor = ClimateAdvisor();
  final ClimateScoreService scoreService = ClimateScoreService();
  final GrogAdvisorService geminiAdvisor = GrogAdvisorService();
  final TextEditingController questionController = TextEditingController();

  Map<String, dynamic>? weatherData;
  String selectedPersona = 'Commuter';
  String selectedAnswer =
      'Ask Climatea something real. Tap a decision chip below or type your own question.';
  bool isLoading = false;
  bool isAskingAI = false;
  DateTime? _lastAiCallTime;

  @override
  void initState() {
    super.initState();
    updateUI(widget.locationWeather);
  }

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  void updateUI(dynamic incomingData) {
    if (incomingData == null) {
      setState(() {
        weatherData = null;
      });
      return;
    }

    setState(() {
      weatherData = Map<String, dynamic>.from(incomingData);
    });
  }

  Future<void> refreshLocationWeather() async {
    setState(() {
      isLoading = true;
    });

    final data = await weather.getLocationAndWeather();

    if (!mounted) return;

    setState(() {
      isLoading = false;
      weatherData = data;
    });
  }

  Future<void> searchCityWeather() async {
    final typedName = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CityScreen(),
      ),
    );

    if (typedName != null && typedName.toString().trim().isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      final data = await weather.getCityWeather(typedName.toString());

      if (!mounted) return;

      setState(() {
        isLoading = false;
        weatherData = data;
      });
    }
  }

  Future<void> askGeminiQuestion(String question) async {
    if (question.trim().isEmpty) return;

    final now = DateTime.now();
    if (_lastAiCallTime != null &&
        now.difference(_lastAiCallTime!).inSeconds < 12) {
      setState(() {
        selectedAnswer =
        'Give me a few seconds before the next AI request. For now, here’s a quick local advisory:\n\n${advisor.answerQuestion(
          weatherData: weatherData,
          persona: selectedPersona,
          question: question,
        )}';
      });
      return;
    }

    _lastAiCallTime = now;

    setState(() {
      isAskingAI = true;
      selectedAnswer = 'Climatea is thinking...';
    });

    final aiAnswer = await geminiAdvisor.generateClimateAdvice(
      weatherData: weatherData,
      persona: selectedPersona,
      question: question,
    );

    if (!mounted) return;

    String finalAnswer;

    if (aiAnswer == '__QUOTA_EXCEEDED__') {
      finalAnswer =
      'AI advice is temporarily busy right now, so I’m giving you Climatea’s built-in local guidance instead.\n\n${advisor.answerQuestion(
        weatherData: weatherData,
        persona: selectedPersona,
        question: question,
      )}';
    } else if (aiAnswer == null) {
      finalAnswer = advisor.answerQuestion(
        weatherData: weatherData,
        persona: selectedPersona,
        question: question,
      );
    } else {
      finalAnswer = aiAnswer;
    }

    setState(() {
      isAskingAI = false;
      selectedAnswer = finalAnswer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final advisory = advisor.buildAdvisory(
      weatherData: weatherData,
      persona: selectedPersona,
    );

    final climateScore = scoreService.buildScore(weatherData);

    final Color riskColor = advisory['riskColor'] as Color;
    final current = weatherData?['current'] as Map<String, dynamic>?;
    final hourly = (weatherData?['hourly'] as List<dynamic>?) ?? [];
    final upcomingHourly = _getUpcomingHourlyData(hourly);

    final int weatherCode =
    current == null ? 0 : _toInt(current['weatherCode']);
    final bool isDay = current == null ? true : _toInt(current['isDay']) == 1;
    final String weatherIcon = weather.getWeatherIcon(weatherCode, isDay);
    final String weatherLabel = weather.getWeatherLabel(weatherCode);
    final String cityName = weatherData?['name'] ?? 'Unknown Location';

    final int temp = current == null ? 0 : _toDouble(current['temp']).toInt();
    final int feelsLike =
    current == null ? 0 : _toDouble(current['feelsLike']).toInt();
    final int humidity =
    current == null ? 0 : _toDouble(current['humidity']).toInt();
    final int wind =
    current == null ? 0 : _toDouble(current['windSpeed']).toInt();
    final double rainNow =
    current == null ? 0 : _toDouble(current['precipitation']);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              riskColor.withOpacity(0.95),
              const Color(0xFF0B1020),
              const Color(0xFF111827),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
            child: CircularProgressIndicator(color: Colors.white),
          )
              : weatherData == null
              ? _buildErrorState()
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topBar(),
                const SizedBox(height: 16),
                _heroCard(
                  cityName: cityName,
                  temp: temp,
                  weatherIcon: weatherIcon,
                  weatherLabel: weatherLabel,
                  risk: advisory['risk'],
                ),
                const SizedBox(height: 16),
                _climateSafetyScoreCard(climateScore),
                const SizedBox(height: 16),
                _radarCard(),
                const SizedBox(height: 16),
                _personaPicker(),
                const SizedBox(height: 16),
                _advisoryCard(advisory),
                const SizedBox(height: 16),
                _metricsGrid(
                  feelsLike: feelsLike,
                  humidity: humidity,
                  wind: wind,
                  rainNow: rainNow,
                ),
                const SizedBox(height: 16),
                _hourlySection(upcomingHourly),
                const SizedBox(height: 16),
                _decisionHub(),
                const SizedBox(height: 16),
                _customQuestionBox(),
                const SizedBox(height: 16),
                _answerCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: glassCard(Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 60, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Climate data unavailable',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Refresh location access or search for a city manually.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: refreshLocationWeather,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use Current Location'),
                  ),
                  OutlinedButton.icon(
                    onPressed: searchCityWeather,
                    icon: const Icon(Icons.search),
                    label: const Text('Search City'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Climatea',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          onPressed: refreshLocationWeather,
          icon: const Icon(Icons.my_location, size: 28),
        ),
        IconButton(
          onPressed: searchCityWeather,
          icon: const Icon(Icons.search, size: 28),
        ),
      ],
    );
  }

  Widget _heroCard({
    required String cityName,
    required int temp,
    required String weatherIcon,
    required String weatherLabel,
    required String risk,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: glassCard(Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cityName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your Personal Climate Consultant',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(
                '$temp°',
                style: kTempTextStyle,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  weatherIcon,
                  style: kConditionTextStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  weatherLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: risk == 'High'
                      ? Colors.red.withOpacity(0.18)
                      : risk == 'Medium'
                      ? Colors.orange.withOpacity(0.18)
                      : Colors.green.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$risk Risk',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _climateSafetyScoreCard(Map<String, dynamic> climateScore) {
    final int score = climateScore['score'] ?? 0;
    final String status = climateScore['status'] ?? 'Unknown';
    final Color color = climateScore['color'] as Color? ?? Colors.blueGrey;
    final String summary = climateScore['summary'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: glassCard(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Climate Safety Score', style: kSectionTitleStyle),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.20),
                  border: Border.all(
                    color: color.withOpacity(0.85),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _scoreMiniCard(
                  'Heat',
                  climateScore['heatScore'] ?? 0,
                  climateScore['heatLabel'] ?? '',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _scoreMiniCard(
                  'Wind',
                  climateScore['windScore'] ?? 0,
                  climateScore['windLabel'] ?? '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _scoreMiniCard(
                  'Humidity',
                  climateScore['humidityScore'] ?? 0,
                  climateScore['humidityLabel'] ?? '',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreMiniCard(String title, int value, String label) {
    final Color chipColor = label == 'High'
        ? const Color(0xFFEF4444)
        : label == 'Medium'
        ? const Color(0xFFF59E0B)
        : const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: chipColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _radarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: glassCard(Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Climate Radar', style: kSectionTitleStyle),
          const SizedBox(height: 10),
          const Text(
            'See your location, surrounding threat radius, and nearby pressure zones on a live map.',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClimateRadarScreen(
                      weatherData: weatherData,
                      selectedPersona: selectedPersona,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.radar),
              label: const Text('Open Climate Radar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _personaPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Context Persona',
          style: kSectionTitleStyle,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ClimateAdvisor.personas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final persona = ClimateAdvisor.personas[index];
              final selected = selectedPersona == persona;

              return ChoiceChip(
                selected: selected,
                label: Text(persona),
                onSelected: (_) {
                  setState(() {
                    selectedPersona = persona;
                  });
                },
                selectedColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.12),
                labelStyle: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _advisoryCard(Map<String, dynamic> advisory) {
    final List<dynamic> reasons = advisory['reasons'] ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: glassCard(advisory['riskColor'] as Color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Climate Advisory',
            style: kSectionTitleStyle,
          ),
          const SizedBox(height: 10),
          Text(
            advisory['headline'] ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            advisory['advice'] ?? '',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.white,
            ),
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reasons.map((reason) {
                return Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reason.toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricsGrid({
    required int feelsLike,
    required int humidity,
    required int wind,
    required double rainNow,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Metrics',
          style: kSectionTitleStyle,
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.9,
          children: [
            _metricCard('Feels Like', '$feelsLike°', Icons.thermostat),
            _metricCard('Humidity', '$humidity%', Icons.water_drop),
            _metricCard('Wind', '$wind km/h', Icons.air),
            _metricCard(
              'Rain Now',
              '${rainNow.toStringAsFixed(1)} mm',
              Icons.umbrella,
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: glassCard(Colors.white),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hourlySection(List<Map<String, dynamic>> hourly) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Next Hours',
          style: kSectionTitleStyle,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 145,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: hourly.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = hourly[index];
              final time = _formatHour(item['time']?.toString() ?? '');
              final temp = _toDouble(item['temp']).toInt();
              final rain = _toInt(item['rainProbability']);
              final code = _toInt(item['weatherCode']);
              final icon = weather.getWeatherIcon(code, true);

              return Container(
                width: 92,
                padding: const EdgeInsets.all(14),
                decoration: glassCard(Colors.white),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    Text(
                      '$temp°',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$rain% rain',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _decisionHub() {
    final questions = [
      'Is my commute safe?',
      'Is an outdoor event safe?',
      'Should I do an outdoor workout?',
      'Should I travel now?',
      'Should I irrigate today?',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Decision Hub',
          style: kSectionTitleStyle,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: questions.map((q) {
            return ActionChip(
              backgroundColor: Colors.white.withOpacity(0.12),
              label: Text(
                q,
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: () {
                askGeminiQuestion(q);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _customQuestionBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: glassCard(Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ask Climatea', style: kSectionTitleStyle),
          const SizedBox(height: 10),
          TextField(
            controller: questionController,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Example: Is my 4 PM outdoor wedding safe?',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isAskingAI
                  ? null
                  : () {
                askGeminiQuestion(questionController.text.trim());
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(isAskingAI ? 'Thinking...' : 'Ask AI'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _answerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: glassCard(Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Climatea Says', style: kSectionTitleStyle),
          const SizedBox(height: 10),
          Text(
            selectedAnswer,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getUpcomingHourlyData(List<dynamic> hourly) {
    if (hourly.isEmpty) return [];

    final now = DateTime.now();
    final roundedNow = DateTime(now.year, now.month, now.day, now.hour);

    int startIndex = 0;

    for (int i = 0; i < hourly.length; i++) {
      final item = hourly[i] as Map<String, dynamic>;
      final rawTime = item['time']?.toString();

      if (rawTime == null || rawTime.isEmpty) continue;

      try {
        final itemTime = DateTime.parse(rawTime);
        if (!itemTime.isBefore(roundedNow)) {
          startIndex = i;
          break;
        }
      } catch (_) {}
    }

    final sliced = hourly.skip(startIndex).take(6).toList();
    return sliced.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  String _formatHour(String value) {
    if (value.isEmpty || !value.contains('T')) return '--';
    final parts = value.split('T');
    if (parts.length < 2) return '--';
    final hourPart = parts[1];
    final hour = int.tryParse(hourPart.split(':').first) ?? 0;

    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    return '$displayHour $suffix';
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