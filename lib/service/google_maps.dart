// ignore_for_file: empty_catches

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constants.dart';

Future<String?> getCityFromCoordinates(double lat, double lng) async {
  const String apiKey = googleMaps;
  final String url =
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);
      final results = decodedResponse['results'] as List;
      if (results.isNotEmpty) {
        for (var component in results[0]['address_components']) {
          if (component['types'].contains('locality')) {
            return component['long_name'];
          }
        }
      }
    }
  } catch (e) {
  }
  return null;
}
