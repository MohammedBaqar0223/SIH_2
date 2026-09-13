import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const backendUrl = 'http://10.0.2.2:8000';

Future<List<dynamic>> fetchProducts() async {
  final url = Uri.parse('$backendUrl/products');
  final response = await http.get(url).timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw Exception('Backend returned error ${response.statusCode}');
  }

  return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
}

Future<List<dynamic>> fetchPublishedProducts() async {
  final response = await http
      .get(Uri.parse('$backendUrl/catalog'))
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw Exception('Backend returned error ${response.statusCode}');
  }

  return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
}

Future<Map<String, dynamic>> fetchProductById(int id) async {
  final response = await http
      .get(Uri.parse('$backendUrl/products/$id'))
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw Exception('Backend returned error ${response.statusCode}');
  }

  return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> createProduct({
  required String name,
  required String material,
  required int pricePaise,
  required int quantity,
  required String description,
  required String artisan,
}) async {
  final response = await http
      .post(
        Uri.parse('$backendUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'material': material,
          'price_paise': pricePaise,
          'quantity': quantity,
          'description': description,
          'artisan': artisan,
          'published': 0,
        }),
      )
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 201) {
    throw Exception(
      'Could not add product: ${response.statusCode}\n'
      '${response.body}',
    );
  }

  return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> updateProduct({
  required int id,
  required String name,
  required String material,
  required int pricePaise,
  required int quantity,
  required String description,
  required String artisan,
}) async {
  final response = await http
      .put(
        Uri.parse('$backendUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'material': material,
          'price_paise': pricePaise,
          'quantity': quantity,
          'description': description,
          'artisan': artisan,
        }),
      )
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw Exception(
      'Could not update product: ${response.statusCode}\n'
      '${response.body}',
    );
  }

  return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> publishProduct(int id) async {
  final response = await http
      .post(Uri.parse('$backendUrl/products/$id/publish'))
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw Exception(
      'Could not publish product: ${response.statusCode}\n'
      '${response.body}',
    );
  }

  return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
}

String productPhotoUrl(Map<String, dynamic> product) {
  final photoPath = product['photo_path'];
  if (photoPath is! String || photoPath.trim().isEmpty) {
    return '';
  }
  return '$backendUrl$photoPath';
}

Future<void> uploadProductPhoto({
  required int productId,
  required XFile photo,
}) async {
  final bytes = await photo.readAsBytes();
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$backendUrl/products/$productId/photo'),
  );

  request.files.add(
    http.MultipartFile.fromBytes('file', bytes, filename: photo.name),
  );

  final streamed = await request.send().timeout(const Duration(seconds: 15));
  final response = await http.Response.fromStream(streamed);

  if (response.statusCode != 200) {
    throw Exception(
      'Could not upload photo: ${response.statusCode}\n'
      '${response.body}',
    );
  }
}
