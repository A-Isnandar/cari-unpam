import 'dart:io';

void main() async {
  final uri = Uri.parse('https://i.ibb.co/cKmvp614/414be3438583.png');
  final client = HttpClient()
    ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
  
  final request = await client.getUrl(uri);
  final response = await request.close();
  print('Status without UA: ${response.statusCode}');
  
  final request2 = await client.getUrl(uri);
  request2.headers.set('User-Agent', 'Mozilla/5.0');
  final response2 = await request2.close();
  print('Status with UA: ${response2.statusCode}');
}
