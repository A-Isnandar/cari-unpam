import 'dart:io';

void main() async {
  // We need to pass the URL without the scheme if it causes issues, or just URL encode it.
  final imgUrl = 'https://i.ibb.co/FkF70g2t/d92092c36136.jpg';
  final proxyUrl = 'https://wsrv.nl/?url=${Uri.encodeComponent(imgUrl)}';
  final uri = Uri.parse(proxyUrl);
  
  final client = HttpClient()..badCertificateCallback = ((cert, host, port) => true);
  final request = await client.getUrl(uri);
  final response = await request.close();
  print('Status: ${response.statusCode}');
  print('Headers: ${response.headers.contentType}');
}
