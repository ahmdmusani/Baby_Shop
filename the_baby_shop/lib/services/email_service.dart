
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmailService {
  // Keep the Brevo API key on your backend.
  // Configure this URL to point to your own email API endpoint.
  static const String _emailApiUrl = String.fromEnvironment(
    'EMAIL_API_URL',
  );

  static const String _senderEmail = 'ahmdmusanii@gmail.com';
  static const String _senderName = 'The Baby Shop';

  static const Duration _requestTimeout = Duration(seconds: 30);

  /// Sends an email through your backend.
  ///
  /// The backend should securely store the Brevo API key and send
  /// the email through the Brevo REST API.
  static Future<bool> sendEmail({
    required String toEmail,
    required String subject,
    required String htmlContent,
  }) async {
    if (_emailApiUrl.isEmpty) {
      debugPrint(
        'EmailService: EMAIL_API_URL is not configured.',
      );
      return false;
    }

    if (toEmail.trim().isEmpty ||
        subject.trim().isEmpty ||
        htmlContent.trim().isEmpty) {
      debugPrint(
        'EmailService: Recipient, subject, and content are required.',
      );
      return false;
    }

    final Uri endpoint;

    try {
      endpoint = Uri.parse(_emailApiUrl);

      if (!endpoint.hasScheme ||
          (endpoint.scheme != 'https' &&
              !(kDebugMode && endpoint.scheme == 'http'))) {
        debugPrint(
          'EmailService: Configure a valid HTTPS email API endpoint.',
        );
        return false;
      }
    } catch (e) {
      debugPrint('EmailService: Invalid email API URL.');
      return false;
    }

    try {
      final response = await http
          .post(
            endpoint,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'toEmail': toEmail.trim(),
              'subject': subject,
              'htmlContent': htmlContent,
              'sender': {
                'name': _senderName,
                'email': _senderEmail,
              },
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        debugPrint(
          'EmailService: Email request accepted '
          '(HTTP ${response.statusCode}).',
        );
        return true;
      }

      // Avoid logging response bodies that could contain sensitive data.
      debugPrint(
        'EmailService: Request failed '
        '(HTTP ${response.statusCode}).',
      );
      return false;
    } catch (e) {
      debugPrint(
        'EmailService: Could not send email request '
        '(${e.runtimeType}).',
      );
      return false;
    }
  }

  /// Sends a checkout invoice email.
  /// Original method signature is preserved.
  static Future<bool> sendInvoiceEmail({
    required String toEmail,
    required String subject,
    required String htmlContent,
  }) async {
    return sendEmail(
      toEmail: toEmail,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Sends an order-delivered notification with a review link.
  static Future<bool> sendOrderDeliveredEmail({
    required String toEmail,
    required String customerName,
    required String orderId,
    required String orderNumber,
  }) async {
    final subject =
        'Your order has been delivered! - #$orderNumber';

    final htmlContent = _generateDeliveredEmailHtml(
      customerName,
      orderId,
      orderNumber,
    );

    return sendEmail(
      toEmail: toEmail,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Sends an order-cancelled notification.
  static Future<bool> sendOrderCancelledEmail({
    required String toEmail,
    required String customerName,
    required String orderNumber,
  }) async {
    final subject =
        'Important update regarding your order #$orderNumber';

    final htmlContent = _generateCancelledEmailHtml(
      customerName,
      orderNumber,
    );

    return sendEmail(
      toEmail: toEmail,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  static String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String _generateDeliveredEmailHtml(
    String customerName,
    String orderId,
    String orderNumber,
  ) {
    final safeName = _escapeHtml(customerName);
    final safeOrderNumber = _escapeHtml(orderNumber);

    // Encode the order ID for use in a URI query parameter.
    final reviewUri = Uri(
      scheme: 'thebabyshop',
      host: 'reviews',
      queryParameters: {'orderId': orderId},
    );

    final safeReviewUrl = _escapeHtml(reviewUri.toString());
    final year = DateTime.now().year;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Your Order Has Been Delivered!</title>
</head>
<body style="font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8f9fa; margin: 0; padding: 0;">
  <div style="width: 100%; background-color: #f8f9fa; padding: 30px 0;">
    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; overflow: hidden;">
      <div style="background: linear-gradient(135deg, #FF4B81 0%, #FF6B9A 100%); padding: 40px 30px; text-align: center; color: #ffffff;">
        <h1 style="margin: 0; font-size: 28px;">The Baby Shop</h1>
        <p style="margin: 10px 0 0; font-size: 16px;">Your order has arrived!</p>
      </div>

      <div style="padding: 30px 40px; text-align: center;">
        <h2 style="color: #1e293b; font-size: 20px;">Hi $safeName,</h2>
        <p style="color: #475569; font-size: 15px; line-height: 1.6;">
          Great news! Your order <strong>#$safeOrderNumber</strong>
          has been successfully delivered. We hope you and your little one
          love your new items.
        </p>

        <div style="background-color: #f8f9fa; border-radius: 16px; padding: 24px; margin: 24px 0; border: 1px solid #f1f5f9;">
          <p style="color: #475569; font-size: 14px; line-height: 1.6;">
            How was your shopping experience? Let us know what you think!
          </p>
          <a href="$safeReviewUrl"
             style="display: inline-block; background-color: #FF4071; color: #ffffff; text-decoration: none; padding: 14px 24px; border-radius: 30px; font-weight: bold;">
            Rate Your Order &amp; Leave a Review
          </a>
        </div>

        <p style="color: #64748b; font-size: 13px; line-height: 1.5;">
          If you have any questions, please contact our support team.
        </p>
      </div>

      <div style="background-color: #f8f9fa; padding: 30px; text-align: center; border-top: 1px solid #e2e8f0;">
        <p style="font-size: 13px; color: #64748b;">
          Thank you for shopping with us!
        </p>
        <p style="font-size: 11px; color: #94a3b8;">
          &copy; $year The Baby Shop. All rights reserved.
        </p>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }

  static String _generateCancelledEmailHtml(
    String customerName,
    String orderNumber,
  ) {
    final safeName = _escapeHtml(customerName);
    final safeOrderNumber = _escapeHtml(orderNumber);
    final year = DateTime.now().year;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Order Cancelled</title>
</head>
<body style="font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8f9fa; margin: 0; padding: 0;">
  <div style="width: 100%; background-color: #f8f9fa; padding: 30px 0;">
    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; overflow: hidden;">
      <div style="background-color: #475569; padding: 40px 30px; text-align: center; color: #ffffff;">
        <h1 style="margin: 0; font-size: 28px;">The Baby Shop</h1>
        <p style="margin: 10px 0 0; font-size: 16px;">Order Update</p>
      </div>

      <div style="padding: 30px 40px;">
        <h2 style="color: #1e293b; font-size: 20px; text-align: center;">
          Dear $safeName,
        </h2>

        <p style="color: #475569; font-size: 15px; line-height: 1.6;">
          We are sorry, but your order <strong>#$safeOrderNumber</strong>
          has been cancelled. We understand this may be disappointing
          and apologize for the inconvenience.
        </p>

        <div style="background-color: #fffbeb; border-radius: 16px; padding: 24px; margin: 24px 0; border-left: 4px solid #f59e0b;">
          <h3 style="color: #b45309; font-size: 15px;">
            Refund Information
          </h3>
          <p style="color: #92400e; font-size: 13px; line-height: 1.5;">
            If you paid online, please check your order or payment provider
            for the current refund status. Refund timing depends on the
            payment method and provider.
          </p>
        </div>

        <p style="color: #475569; font-size: 14px; line-height: 1.6; text-align: center;">
          If you need help, please contact our customer support team.
        </p>

        <div style="text-align: center; margin: 24px 0;">
          <a href="mailto:support@thebabyshop.com"
             style="display: inline-block; background-color: #475569; color: #ffffff; text-decoration: none; padding: 14px 32px; border-radius: 30px; font-weight: bold;">
            Contact Customer Support
          </a>
        </div>
      </div>

      <div style="background-color: #f8f9fa; padding: 30px; text-align: center; border-top: 1px solid #e2e8f0;">
        <p style="font-size: 13px; color: #64748b;">
          We hope to serve you better next time.
        </p>
        <p style="font-size: 11px; color: #94a3b8;">
          &copy; $year The Baby Shop. All rights reserved.
        </p>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }
}
