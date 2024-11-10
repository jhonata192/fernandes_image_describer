import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://visionbot.ru/apiv2';
  static const String _languagesEndpoint = '/get_languages.php';
  static const String _uploadEndpoint = '/in.php';
  static const String _resultEndpoint = '/res.php';
  static const Duration _timeoutDuration = Duration(seconds: 10);

  static Future<List<String>> getLanguages() async {
    final url = Uri.parse('$_baseUrl$_languagesEndpoint');
    final response = await _makeRequest(() => http.get(url));
    return List<String>.from(response['languages']);
  }

  static Future<String> uploadImage(String base64Image, String lang, int bm) async {
    final url = Uri.parse('$_baseUrl$_uploadEndpoint');
    final response = await _makeRequest(() => http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'body': base64Image, 'lang': lang, 'bm': bm.toString()},
    ));
    return response['id'];
  }

  static Future<Map<String, dynamic>> getResult(String id) async {
    final url = Uri.parse('$_baseUrl$_resultEndpoint');
    final response = await _makeRequest(() => http.post(url, body: {'id': id}));
    return response;
  }

  static Future<Map<String, dynamic>> _makeRequest(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeoutDuration);
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        print('Failed request with status code: ${response.statusCode}');
        throw Exception('Failed to complete request: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Exception caught: $e\nStackTrace: $stackTrace');
      throw Exception('Error during API request: $e');
    }
  }
}
