import 'dart:io';

void main() async {
  final uri = Uri.parse('https://i.ibb.co/cKmvp614/414be3438583.png');
  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  print('Status: ${response.statusCode}');
}
