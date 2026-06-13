import 'dart:convert';
import 'dart:io';

void main() async {
  final uri = Uri.parse('https://firestore.googleapis.com/v1/projects/cariunpam-d19b7/databases/(default)/documents/posts');
  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  
  final json = jsonDecode(body);
  if (json['documents'] != null) {
    for (var doc in json['documents']) {
      final fields = doc['fields'];
      if (fields != null && fields['fotoUrl'] != null) {
        print('fotoUrl: ${fields['fotoUrl']['stringValue']}');
      }
    }
  } else {
    print(body);
  }
}
