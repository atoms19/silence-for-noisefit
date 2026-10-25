/// Weather command encoder for the watch (`0A 04` current + forecast).
///
/// Layout recovered from NoiseFit 5.4.6 (`internal/l9.U`, `bean/TGWeather`);
/// see docs/silence-os/12-weather-protocol.md.
library;

import 'dart:typed_data';

/// Type codes NoiseFit sends, keyed by OpenWeather-style condition names.
enum WatchWeather {
  clear(1),
  clouds(2),
  rain(4),
  thunderstorm(6),
  snow(7),
  tornado(9),
  sand(10),
  other(0x11),
  drizzle(0x12);

  const WatchWeather(this.code);
  final int code;
}

/// Maps a WMO weather code (Open-Meteo) to the watch's types.
WatchWeather weatherFromWmo(int code) {
  if (code == 0) {
    return WatchWeather.clear;
  }
  if (code <= 3) {
    return WatchWeather.clouds;
  }
  if (code == 45 || code == 48) {
    return WatchWeather.other;
  }
  if (code >= 51 && code <= 57) {
    return WatchWeather.drizzle;
  }
  if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
    return WatchWeather.rain;
  }
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
    return WatchWeather.snow;
  }
  if (code >= 95) {
    return WatchWeather.thunderstorm;
  }
  return WatchWeather.other;
}

class DayForecast {
  const DayForecast({required this.type, required this.max, required this.min});
  final WatchWeather type;
  final int max;
  final int min;
}

/// Current conditions plus today's range and the following days.
class WeatherReport {
  const WeatherReport({
    required this.type,
    required this.temperature,
    required this.max,
    required this.min,
    required this.humidity,
    required this.days,
  });
  final WatchWeather type;
  final int temperature;
  final int max;
  final int min;
  final int humidity;

  /// Days after today (up to four are sent).
  final List<DayForecast> days;
}

int _byte(int value) => value & 0xFF;

/// New format (`0A 04`): type, temperature, max, min, humidity, six unknown
/// bytes (zero), then three bytes per future day. Temperatures are signed bytes.
Uint8List buildWeatherCommand(WeatherReport r) {
  final days = r.days.take(4).toList();
  final out = <int>[
    0x0A,
    0x04,
    r.type.code,
    _byte(r.temperature),
    _byte(r.max),
    _byte(r.min),
    _byte(r.humidity),
    0,
    0,
    0,
    0,
    0,
    0,
    for (final d in days) ...[d.type.code, _byte(d.max), _byte(d.min)],
  ];
  return Uint8List.fromList(out);
}

/// Older format (`0A 01`): type, temperature, max, min, humidity, two unknown
/// bytes, then three bytes per future day in an 18-byte buffer (so three days).
Uint8List buildLegacyWeatherCommand(WeatherReport r) {
  final days = r.days.take(3).toList();
  final body = <int>[
    r.type.code,
    _byte(r.temperature),
    _byte(r.max),
    _byte(r.min),
    _byte(r.humidity),
    0,
    0,
    for (final d in days) ...[d.type.code, _byte(d.max), _byte(d.min)],
  ];
  while (body.length < 18) {
    body.add(0);
  }
  return Uint8List.fromList([0x0A, 0x01, ...body]);
}

/// Whether the device uses the new weather command (`internal/a0.o`).
bool usesNewWeatherFormat({
  required int protocolVersion,
  required int deviceId,
}) => (protocolVersion >> 8) == 3 || deviceId == 0x1fa;
