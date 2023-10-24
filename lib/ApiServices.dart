import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiServices {
  Future<Map<String, dynamic>> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://drive.google.com/uc?id=1FEOTw_ioZ4SR4Iq5UxqsqcEgKAg3bNtX'));

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON
      return json.decode(response.body);
    } else {
      // If the server did not return a 200 OK response, throw an exception
      throw Exception('Failed to load data');
    }
  }
}
