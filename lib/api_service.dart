import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://visionbot.ru/apiv2';

  static Future<List<String>> getLanguages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_languages.php'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return List<String>.from(data['languages']);
      } else {
        print('Failed to load languages: ${response.statusCode}');
        throw Exception('Failed to load languages');
      }
    } catch (e) {
      print('Exception caught: $e');
      throw Exception('Failed to load languages: $e');
    }
  }

  static Future<String> uploadImage(String base64Image, String lang, int bm) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/in.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'body': base64Image,
          'lang': lang,
          'bm': bm.toString(),
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('Upload response: $data');
        return data['id'];
      } else {
        print('Failed to upload image: ${response.statusCode}');
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      print('Exception caught: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<Map<String, dynamic>> getResult(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/res.php'),
        body: {'id': id},
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('Get result response: $data');
        return data;
      } else {
        print('Failed to get result: ${response.statusCode}');
        throw Exception('Failed to get result');
      }
    } catch (e) {
      print('Exception caught: $e');
      throw Exception('Failed to get result: $e');
    }
  }
}
