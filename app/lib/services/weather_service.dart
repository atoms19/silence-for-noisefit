/// Free weather and city lookup via Open-Meteo (no API key).
library;

import 'dart:convert';
import 'dart:io';

import 'touchgui_weather.dart';

class WeatherPlace {
  const WeatherPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
  final String name;
  final double latitude;
  final double longitude;

  String encode() =>
      jsonEncode({'name': name, 'lat': latitude, 'lon': longitude});

  static WeatherPlace? decode(String? raw) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return WeatherPlace(
        name: m['name'] as String,
        latitude: (m['lat'] as num).toDouble(),
        longitude: (m['lon'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

abstract interface class WeatherService {
  Future<List<WeatherPlace>> search(String query);
  Future<WeatherReport> fetch(WeatherPlace place);
}

/// Builds a [WeatherReport] from an Open-Meteo forecast response (Celsius).
WeatherReport parseOpenMeteo(Map<String, dynamic> json) {
  final current = json['current'] as Map<String, dynamic>;
  final daily = json['daily'] as Map<String, dynamic>;
  final maxes = (daily['temperature_2m_max'] as List).cast<num>();
  final mins = (daily['temperature_2m_min'] as List).cast<num>();
  final codes = (daily['weather_code'] as List).cast<num>();
  return WeatherReport(
    type: weatherFromWmo((current['weather_code'] as num).toInt()),
    temperature: (current['temperature_2m'] as num).round(),
    max: maxes.first.round(),
    min: mins.first.round(),
    humidity: (current['relative_humidity_2m'] as num).round(),
    days: [
      for (var i = 1; i < codes.length; i++)
        DayForecast(
          type: weatherFromWmo(codes[i].toInt()),
          max: maxes[i].round(),
          min: mins[i].round(),
        ),
    ],
  );
}

class OpenMeteoWeatherService implements WeatherService {
  Future<Map<String, dynamic>> _get(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != 200) {
        throw HttpException('Weather service answered ${response.statusCode}');
      }
      return jsonDecode(await response.transform(utf8.decoder).join())
          as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  @override
  Future<List<WeatherPlace>> search(String query) async {
    final json = await _get(
      Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': query,
        'count': '5',
        'language': 'en',
      }),
    );
    return [
      for (final r
          in (json['results'] as List? ?? const [])
              .cast<Map<String, dynamic>>())
        WeatherPlace(
          name: [
            r['name'],
            r['admin1'],
            r['country'],
          ].whereType<String>().join(', '),
          latitude: (r['latitude'] as num).toDouble(),
          longitude: (r['longitude'] as num).toDouble(),
        ),
    ];
  }

  @override
  Future<WeatherReport> fetch(WeatherPlace place) async => parseOpenMeteo(
    await _get(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${place.latitude}',
        'longitude': '${place.longitude}',
        'current': 'temperature_2m,relative_humidity_2m,weather_code',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
        'forecast_days': '5',
        'timezone': 'auto',
      }),
    ),
  );
}
