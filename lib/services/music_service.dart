import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class MusicService {
  final String apiKey = ""; // Get from audd.io

  Future<Map<String, dynamic>?> recognizeSong(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.audd.io/'),
    )
      ..fields['api_token'] = apiKey
      ..fields['return'] = 'spotify,deezer,apple_music'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    final data = jsonDecode(body);
    if (data['status'] == 'success' && data['result'] != null) {
      return data['result'];
    }
    return null;
  }
}
