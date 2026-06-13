import 'dart:convert';
import 'dart:io';

void main() async {
  // Create a 1x1 dummy PNG
  final bytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');
  final base64Image = base64Encode(bytes);
  
  final uri = Uri.parse('https://api.imgbb.com/1/upload');
  final request = await HttpClient().postUrl(uri);
  request.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
  
  final body = 'key=d4f1cf96b33b452691d02094d3245cbf&image=${Uri.encodeComponent(base64Image)}';
  request.write(body);
  
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  
  print('Status: ${response.statusCode}');
  print('Response: $responseBody');
}
