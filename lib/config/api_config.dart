import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get startPoint {
    final value = dotenv.env['START_POINT']?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('START_POINT is missing in .env');
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static Uri uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$startPoint$normalizedPath');
  }

  static String url(String path) => uri(path).toString();
}
