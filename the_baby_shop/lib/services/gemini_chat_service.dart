
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message_model.dart';

class GeminiChatService {
  // Pass the API key at runtime/build time.
  // Never paste the real API key directly into this source file.
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const String _model = 'gemini-3.1-flash-lite';

  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static final http.Client _client = http.Client();

  static const int _maxRetries = 3;
  static const Duration _requestTimeout = Duration(seconds: 30);

  static const String _systemPrompt = '''
You are the AI Chatbot Assistant for "The Baby Shop", a premium e-commerce mobile application specializing in baby products (clothing, feeding, toys, shoes, etc.).

Your job is to assist users with questions about the application's features, functionality, layout, modules, and how to use the app.

APPLICATION FEATURES

1. CUSTOMER PORTAL / USER PANEL

- Greeting and Welcome:
  Custom greeting depending on Pakistan local time with elegant emojis.

- Home Screen:
  - Promos and Deals: Home promo carousel showcasing active sales, banners, and discount events. Clicking "Shop Now" directs users to the catalog.
  - Search Bar: Quick and responsive product search.
  - Categories List: Visual category filters such as All, Clothing, Shoes, Toys, and Feeds.
  - Featured Products: Dynamic grid listing with real-time stock levels, original and discounted prices, discount percentage tags, and an instant Add to Cart button.
  - Out-of-stock protection: Overlay indicating "OUT OF STOCK" on products with zero stock.

- Navigation:
  Curved floating bottom navigation bar with quick access to Home, Wishlist, Cart, and Profile.

- Wishlist:
  Personal saved catalog. Items can be favorited and unfavorited instantly.

- Cart Screen:
  In-cart item count, dynamic quantity selectors, total calculation, and size selection for clothing, such as default Medium (M).

- Product Details:
  High-resolution images, fabric descriptions, available sizes and colors, size charts, specifications, price details, and product reviews.

- Checkout and Order Tracking:
  Payment method choices such as Cash on Delivery, Bank Transfer, and Card; order summary, order placement, and order tracking steps.

- Help and Support:
  FAQ section, customer support contact options, and support tickets.

- Reviews and Ratings:
  Ability to write reviews, rate products, and read feedback from other customers.

2. ADMIN DASHBOARD AND MANAGEMENT PANEL

- Dashboard:
  Graphical metrics for total orders, users, sales, and products.

- Product Management:
  Add, edit, delete, and update products, including names, stock, prices, discounts, sizes, fabrics, and images.

- Category and Banner Management:
  Edit categories and add promotional banners.

- Order and Review Moderation:
  Manage orders, view user reviews, and approve or delete content.

- Support Ticketing:
  Real-time support responses between administrators and users.

CONSTRAINTS AND POLICIES

1. Only answer questions directly related to The Baby Shop application's features, functionality, layout, usage, rules, modules, and products.

2. If the user asks a general knowledge question, coding or programming question, historical question, science question, general mathematics question, or anything unrelated to this application, politely refuse.

3. For unrelated questions, respond exactly with:
"I can only assist with questions related to this application. Please ask a question about the app's features, functionality, or usage."

4. Do not provide code snippets, general knowledge answers, calculations, translations of unrelated items, or other responses that bypass this rule.

5. Keep the tone extremely friendly, polite, clean, and helpful. Avoid extremely long paragraphs. Use clear lists or short responses.
''';

  Future<String> sendMessage(
    String text,
    List<ChatMessageModel> history,
  ) async {
    if (_apiKey.trim().isEmpty) {
      throw Exception(
        'Gemini API key is not configured. '
        'Run the app with --dart-define=GEMINI_API_KEY=YOUR_API_KEY.',
      );
    }

    if (text.trim().isEmpty) {
      throw Exception('Please enter a message.');
    }

    int retryCount = 0;
    Duration delay = const Duration(seconds: 1);

    while (true) {
      try {
        final uri = Uri.parse(_apiUrl).replace(
          queryParameters: {'key': _apiKey},
        );

        final contents = <Map<String, dynamic>>[];

        // Include previous messages, excluding error messages.
        for (final msg in history) {
          if (msg.isError) continue;

          // Gemini accepts "user" and "model" roles.
          final role = msg.role == 'assistant' ? 'model' : msg.role;

          if (role != 'user' && role != 'model') {
            continue;
          }

          contents.add({
            'role': role,
            'parts': [
              {'text': msg.text},
            ],
          });
        }

        // Add the current user message.
        contents.add({
          'role': 'user',
          'parts': [
            {'text': text.trim()},
          ],
        });

        final requestBody = jsonEncode({
          'contents': contents,
          'systemInstruction': {
            'parts': [
              {'text': _systemPrompt},
            ],
          },
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 800,
          },
        });

        final response = await _client
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
              },
              body: requestBody,
            )
            .timeout(_requestTimeout);

        if (response.statusCode == 200) {
          final dynamic decoded = jsonDecode(response.body);

          if (decoded is! Map<String, dynamic>) {
            throw Exception('Invalid response received from Gemini.');
          }

          final candidates = decoded['candidates'];

          if (candidates is List && candidates.isNotEmpty) {
            final candidate = candidates.first;

            if (candidate is Map<String, dynamic>) {
              final content = candidate['content'];

              if (content is Map<String, dynamic>) {
                final parts = content['parts'];

                if (parts is List && parts.isNotEmpty) {
                  final textParts = <String>[];

                  for (final part in parts) {
                    if (part is Map<String, dynamic>) {
                      final partText = part['text'];

                      if (partText is String &&
                          partText.trim().isNotEmpty) {
                        textParts.add(partText);
                      }
                    }
                  }

                  if (textParts.isNotEmpty) {
                    return textParts.join('\n');
                  }
                }
              }

              final finishReason = candidate['finishReason'];

              if (finishReason == 'SAFETY') {
                throw Exception(
                  'The response could not be generated because '
                  'of the model safety settings. Please try another question.',
                );
              }
            }
          }

          throw Exception(
            'Gemini returned an empty response. Please try again.',
          );
        }

        // Decode API error details safely.
        String errorMessage = 'Request failed (${response.statusCode}).';
        int errorCode = response.statusCode;

        try {
          final dynamic errorBody = jsonDecode(response.body);

          if (errorBody is Map<String, dynamic>) {
            final error = errorBody['error'];

            if (error is Map<String, dynamic>) {
              final message = error['message'];
              final code = error['code'];

              if (message is String && message.isNotEmpty) {
                errorMessage = message;
              }

              if (code is int) {
                errorCode = code;
              }
            }
          }
        } catch (_) {
          // Keep the default error message if the response is not JSON.
        }

        // Retry temporary server errors and rate limits.
        if ((errorCode == 429 || errorCode == 503) &&
            retryCount < _maxRetries) {
          retryCount++;
          await Future.delayed(delay);
          delay = Duration(seconds: delay.inSeconds * 2);
          continue;
        }

        throw Exception('Gemini API error: $errorMessage');
      } on TimeoutException {
        if (retryCount < _maxRetries) {
          retryCount++;
          await Future.delayed(delay);
          delay = Duration(seconds: delay.inSeconds * 2);
          continue;
        }

        throw Exception(
          'The request timed out. Please check your connection and try again.',
        );
      } on http.ClientException {
        if (retryCount < _maxRetries) {
          retryCount++;
          await Future.delayed(delay);
          delay = Duration(seconds: delay.inSeconds * 2);
          continue;
        }

        throw Exception(
          'Could not connect to the Gemini service. Please check your internet connection.',
        );
      } catch (e) {
        final message = e.toString();

        if (message.startsWith('Exception:')) {
          rethrow;
        }

        throw Exception('Could not reach Gemini service: $message');
      }
    }
  }

  // Call this when the service is no longer needed.
  static void dispose() {
    _client.close();
  }
}
