import 'dart:io';
import 'dart:convert';

void main() async {
  final uri = Uri.parse('https://i.ibb.co/FkF70g2t/d92092c36136.jpg');
  final client = HttpClient()
    ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
  
  final request = await client.getUrl(uri);
  final response = await request.close();
  
  print('Status: ${response.statusCode}');
  print('Headers: ${response.headers.contentType}');
  
  final bytes = await response.expand((b) => b).toList();
  print('Bytes length: ${bytes.length}');
  if (bytes.length < 200) {
    print('Content: ${utf8.decode(bytes)}');
  }
}
