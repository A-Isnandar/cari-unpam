import 'dart:io';

void main() async {
  final uri = Uri.parse('https://i.ibb.co/FkF70g2t/d92092c36136.jpg');
  final client = HttpClient()..badCertificateCallback = ((cert, host, port) => true);
  final request = await client.getUrl(uri);
  request.headers.set('User-Agent', 'Mozilla/5.0');
  request.headers.set('Referer', 'https://ibb.co/');
  final response = await request.close();
  print('Headers: ${response.headers.contentType}');
}
