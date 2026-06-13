import 'dart:io';
import 'dart:convert';

void main() async {
  final uri = Uri.parse('https://i.ibb.co/FkF70g2t/d92092c36136.jpg');
  final client = HttpClient()..badCertificateCallback = ((cert, host, port) => true);
  final request = await client.getUrl(uri);
  final response = await request.close();
  final bytes = await response.expand((b) => b).toList();
  final html = utf8.decode(bytes, allowMalformed: true);
  
  final match = RegExp(r'<title>(.*?)</title>').firstMatch(html);
  if (match != null) {
    print('Title: ${match.group(1)}');
  } else {
    print('No title found');
  }
}
