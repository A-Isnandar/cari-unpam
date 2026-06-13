import 'dart:io';

void main() async {
  final uri = Uri.parse('https://i.ibb.co/FkF70g2t/d92092c36136.jpg');
  final client = HttpClient()..badCertificateCallback = ((cert, host, port) => true);
  final request = await client.getUrl(uri);
  request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');
  request.headers.set('Accept', 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8');
  final response = await request.close();
  print('Headers: ${response.headers.contentType}');
}
