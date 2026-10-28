
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main() async {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');

  if (apiKey.isEmpty) {
    stderr.writeln(
      'Error: Gemini API key is missing.\n'
      'Run with --dart-define=GEMINI_API_KEY=YOUR_NEW_API_KEY',
    );
    exitCode = 1;
    return;
  }

  final uri = Uri.https(
    'generativelanguage.googleapis.com',
    '/v1beta/models',
    {'key': apiKey},
  );

  final client = http.Client();

  try {
    final response = await client
        .get(
          uri,
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      String message = 'HTTP ${response.statusCode}';

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final error = decoded['error'];

          if (error is Map<String, dynamic> &&
              error['message'] is String) {
            message = error['message'] as String;
          }
        }
      } catch (_) {
        // Keep the HTTP status if the error response isn't JSON.
      }

      stderr.writeln('Failed to retrieve models: $message');
      exitCode = 1;
      return;
    }

    // Validate that the response is valid JSON.
    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      stderr.writeln('Error: Unexpected API response format.');
      exitCode = 1;
      return;
    }

    // Save the response without exposing the API key in the file.
    final outputFile = File('lib/models_list.json');

    await outputFile.parent.create(recursive: true);

    const encoder = JsonEncoder.withIndent('  ');
    await outputFile.writeAsString(
      '${encoder.convert(decoded)}\n',
      flush: true,
    );

    stdout.writeln(
      'Models list saved successfully!\n'
      'HTTP status: ${response.statusCode}\n'
      'File: ${outputFile.path}',
    );
  } on http.ClientException catch (e) {
    stderr.writeln('Network error: $e');
    exitCode = 1;
  } on FormatException catch (e) {
    stderr.writeln('Invalid JSON response: $e');
    exitCode = 1;
  } on Exception catch (e) {
    stderr.writeln('Request failed: $e');
    exitCode = 1;
  } finally {
    client.close();
  }
}
