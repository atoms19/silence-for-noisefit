/// Choose a place and send its weather to the watch.
library;

import 'package:flutter/material.dart';

import '../controller/silence_controller.dart';
import 'silence_theme.dart';
import 'widgets.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key, required this.controller});
  final SilenceController controller;

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final place = c.weatherPlace;
      final report = c.lastWeather;
      return SilencePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place == null ? 'No place chosen yet.' : place.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (report != null) ...[
              const SizedBox(height: 4),
              Text(
                '${report.temperature}°C · ${report.type.name} · ${report.humidity}% humidity · ${report.min}° to ${report.max}°',
                style: const TextStyle(
                  fontSize: 12,
                  color: SilenceColors.muted,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      labelText: 'Search for a city',
                    ),
                    onSubmitted: c.searchWeatherPlace,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => c.searchWeatherPlace(_query.text),
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            for (final result in c.weatherResults)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: OutlinedButton(
                  onPressed: () => c.chooseWeatherPlace(result),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(result.name),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Keep the watch weather updated (hourly while connected)',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Switch(
                  value: c.weatherEnabled,
                  onChanged: place == null ? null : c.setWeatherEnabled,
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: place != null && c.canQuery ? c.sendWeather : null,
              icon: const Icon(Icons.cloud_upload_outlined, size: 18),
              label: const Text('Send weather now'),
            ),
            if (c.weatherStatus != null) ...[
              const SizedBox(height: 10),
              Text(
                c.weatherStatus!,
                style: const TextStyle(
                  fontSize: 12,
                  color: SilenceColors.muted,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
