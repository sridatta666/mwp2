import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class BunnyStreamService {
  final String _libraryId = dotenv.env['BUNNY_LIBRARY_ID'] ?? '';
  final String _apiKey = dotenv.env['BUNNY_API_KEY'] ?? '';
  final String _pullZone = dotenv.env['BUNNY_PULL_ZONE'] ?? '';

  String get libraryId => _libraryId;
  
  String getStreamUrl(String videoId) {
    if (videoId.startsWith('http')) {
      return videoId;
    }
    if (videoId == 'test_video_id' || videoId.isEmpty) {
      return 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
    }

    // Use direct MP4 from pull zone for native player (ExoPlayer)
    if (_pullZone.isNotEmpty) {
      final url = 'https://$_pullZone/$videoId/playlist.m3u8';
      print('[BunnyStream] Direct MP4 URL: $url');
      return url;
    }

    // Fallback: HLS playlist via pull zone
    final url = 'https://player.mediadelivery.net/play/$_libraryId/$videoId';
    print('[BunnyStream] Fallback URL: $url');
    return url;
  }

  /// Returns the direct MP4 URL for fallback playback
  String getDirectMp4Url(String videoId) {
    if (_pullZone.isEmpty) return '';
    return 'https://$_pullZone/$videoId/play_720p.mp4';
  }

  /// Checks the encoding status of a video on Bunny.net.
  /// Returns a map with 'status' (int), 'encodeProgress' (int), etc.
  Future<Map<String, dynamic>> getVideoStatus(String videoId) async {
    if (_libraryId.isEmpty || _apiKey.isEmpty) {
      throw Exception("Missing BunnyCDN credentials in .env");
    }

    final res = await http.get(
      Uri.parse('https://video.bunnycdn.com/library/$_libraryId/videos/$videoId'),
      headers: {
        'AccessKey': _apiKey,
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to get video status: ${res.body}');
    }

    final data = jsonDecode(res.body);
    print('[BunnyStream] Video status: ${data['status']}, encodeProgress: ${data['encodeProgress']}');
    return data;
  }

  Future<String> uploadVideo(String filePath, String title) async {
    if (_libraryId.isEmpty || _apiKey.isEmpty) {
      throw Exception("Missing BunnyCDN credentials in .env");
    }

    // 1. Create a video object
    final createRes = await http.post(
      Uri.parse('https://video.bunnycdn.com/library/$_libraryId/videos'),
      headers: {
        'AccessKey': _apiKey,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': title}),
    );

    if (createRes.statusCode != 200) {
      throw Exception('Failed to create video object in Bunny Stream: ${createRes.body}');
    }

    final videoId = jsonDecode(createRes.body)['guid'];

    // 2. Upload the binary data
    final file = File(filePath);
    final fileBytes = await file.readAsBytes();

    final uploadRes = await http.put(
      Uri.parse('https://video.bunnycdn.com/library/$_libraryId/videos/$videoId'),
      headers: {
        'AccessKey': _apiKey,
        'Content-Type': 'application/octet-stream',
      },
      body: fileBytes,
    );

    if (uploadRes.statusCode != 200 && uploadRes.statusCode != 201) {
      throw Exception('Failed to upload video data to Bunny Stream: ${uploadRes.body}');
    }

    return videoId;
  }

  Future<void> deleteVideo(String videoId) async {
    if (_libraryId.isEmpty || _apiKey.isEmpty) {
      throw Exception("Missing BunnyCDN credentials in .env");
    }

    // Bunny API documentation says to send a DELETE request
    final res = await http.delete(
      Uri.parse('https://video.bunnycdn.com/library/$_libraryId/videos/$videoId'),
      headers: {
        'AccessKey': _apiKey,
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      // 404 might mean the video doesn't exist anymore, which we can ignore or throw
      if (res.statusCode != 404) {
        throw Exception('Failed to delete video from Bunny Stream: ${res.body}');
      }
    }
  }
}
