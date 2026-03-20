import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final payload = {
    "title": "Test căn hộ từ script",
    "subject": "Bán căn hộ test",
    "description": "Mô tả chi tiết test",
    "price": 3500000000,
    "location": {
      "ward": "Phường 1",
      "commune": "Quận 2",
    },
    "projectInfo": {
      "projectId": "test123",
      "project": "Vinhomes",
      "building": "A",
      "floor": 5,
      "apartmentNumber": "501",
    },
    "displayCode": "CH-9999999",
    "imageUrl": "",
    "houseStatus": "Pending",
    "owner": {},
    "verifications": {
      "image": {"status": "", "staffId": null, "updatedAt": ""},
      "legal": {"status": "", "staffId": null, "updatedAt": ""},
      "ownerIntent": {"status": "", "staffId": null, "updatedAt": ""},
    },
    "postedBy": "",
  };

  print('=== Test: Multipart POST with JSON in "data" field ===');
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('http://127.0.0.1:8000/api/apartments/'),
  );
  request.fields['data'] = json.encode(payload);

  try {
    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);
    print('Status: ${resp.statusCode}');
    final body = json.decode(utf8.decode(resp.bodyBytes));
    print(const JsonEncoder.withIndent('  ').convert(body));

    print('\n--- Validation ---');
    if (body['location'] is Map) {
      print('✅ location is a nested object');
    } else {
      print('❌ location is NOT a nested object: ${body['location']}');
    }
    if (body['verifications'] is Map) {
      print('✅ verifications is a nested object');
      final v = body['verifications'];
      if (v['image'] is Map && v['legal'] is Map && v['ownerIntent'] is Map) {
        print('✅ verifications sub-fields are nested objects');
      } else {
        print('❌ verifications sub-fields are NOT nested');
      }
    } else {
      print('❌ verifications is NOT a nested object');
    }
    if (body['price'] is num) {
      print('✅ price is a number: ${body['price']}');
    } else {
      print('❌ price is a string: ${body['price']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
