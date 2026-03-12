import 'package:url_launcher/url_launcher.dart';

/// Shared helper — opens a lat/lng in Google Maps (or geo: fallback).
abstract class MapLauncher {
  static Future<void> open({
    required double lat,
    required double lng,
    String label = '',
  }) async {
    final encoded = Uri.encodeComponent(label.isNotEmpty ? label : 'Location');
    final gmaps = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encoded)');

    if (await canLaunchUrl(gmaps)) {
      await launchUrl(gmaps, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(geo)) {
      await launchUrl(geo);
    }
  }
}