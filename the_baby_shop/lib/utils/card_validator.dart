import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum CardType {
  visa,
  mastercard,
  amex,
  discover,
  dinersClub,
  jcb,
  unionPay,
  unknown,
}

extension CardTypeX on CardType {
  String get value {
    switch (this) {
      case CardType.visa:
        return 'visa';
      case CardType.mastercard:
        return 'mastercard';
      case CardType.amex:
        return 'amex';
      case CardType.discover:
        return 'discover';
      case CardType.dinersClub:
        return 'dinersClub';
      case CardType.jcb:
        return 'jcb';
      case CardType.unionPay:
        return 'unionPay';
      case CardType.unknown:
        return 'unknown';
    }
  }
}

class CardValidator {
  static CardType detectCardType(String cardNumber) {
    String val = cardNumber.trim().toLowerCase();
    if (val == 'visa') return CardType.visa;
    if (val == 'mastercard') return CardType.mastercard;
    if (val == 'amex' || val == 'american express') return CardType.amex;
    if (val == 'discover') return CardType.discover;
    if (val == 'dinersclub' || val == 'diners club' || val == 'diners') return CardType.dinersClub;
    if (val == 'jcb') return CardType.jcb;
    if (val == 'unionpay') return CardType.unionPay;

    String cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.isEmpty) return CardType.unknown;

    if (cleanNumber.startsWith('4')) {
      return CardType.visa;
    }
    
    // Mastercard: 51-55 or 2221-2720
    if (cleanNumber.length >= 2) {
      int prefix2 = int.parse(cleanNumber.substring(0, 2));
      if (prefix2 >= 51 && prefix2 <= 55) {
        return CardType.mastercard;
      }
    }
    if (cleanNumber.length >= 4) {
      int prefix4 = int.parse(cleanNumber.substring(0, 4));
      if (prefix4 >= 2221 && prefix4 <= 2720) {
        return CardType.mastercard;
      }
    }

    // Amex: 34 or 37
    if (cleanNumber.length >= 2) {
      int prefix2 = int.parse(cleanNumber.substring(0, 2));
      if (prefix2 == 34 || prefix2 == 37) {
        return CardType.amex;
      }
    }

    // Discover: 6011, 622126-622925, 644-649, 65
    if (cleanNumber.startsWith('65')) return CardType.discover;
    if (cleanNumber.length >= 4) {
      int prefix4 = int.parse(cleanNumber.substring(0, 4));
      if (prefix4 == 6011) return CardType.discover;
      if (prefix4 >= 644 && prefix4 <= 649) return CardType.discover;
    }
    if (cleanNumber.length >= 6) {
      int prefix6 = int.parse(cleanNumber.substring(0, 6));
      if (prefix6 >= 622126 && prefix6 <= 622925) return CardType.discover;
    }

    // Diners Club: 300-305, 309, 36, 38-39
    if (cleanNumber.length >= 2) {
      int prefix2 = int.parse(cleanNumber.substring(0, 2));
      if (prefix2 == 36 || prefix2 == 38 || prefix2 == 39) return CardType.dinersClub;
    }
    if (cleanNumber.length >= 3) {
      int prefix3 = int.parse(cleanNumber.substring(0, 3));
      if ((prefix3 >= 300 && prefix3 <= 305) || prefix3 == 309) return CardType.dinersClub;
    }

    // JCB: 3528-3589
    if (cleanNumber.length >= 4) {
      int prefix4 = int.parse(cleanNumber.substring(0, 4));
      if (prefix4 >= 3528 && prefix4 <= 3589) return CardType.jcb;
    }

    // UnionPay: 62 or 81
    if (cleanNumber.startsWith('62') || cleanNumber.startsWith('81')) {
      return CardType.unionPay;
    }

    return CardType.unknown;
  }

  static String getCardName(CardType type) {
    switch (type) {
      case CardType.visa: return 'Visa';
      case CardType.mastercard: return 'Mastercard';
      case CardType.amex: return 'American Express';
      case CardType.discover: return 'Discover';
      case CardType.dinersClub: return 'Diners Club';
      case CardType.jcb: return 'JCB';
      case CardType.unionPay: return 'UnionPay';
      case CardType.unknown: return 'Card';
    }
  }

  static IconData getCardIconData(CardType type) {
    switch (type) {
      case CardType.visa: return FontAwesomeIcons.ccVisa;
      case CardType.mastercard: return FontAwesomeIcons.ccMastercard;
      case CardType.amex: return FontAwesomeIcons.ccAmex;
      case CardType.discover: return FontAwesomeIcons.ccDiscover;
      case CardType.dinersClub: return FontAwesomeIcons.ccDinersClub;
      case CardType.jcb: return FontAwesomeIcons.ccJcb;
      case CardType.unionPay: return FontAwesomeIcons.creditCard;
      case CardType.unknown: return Icons.credit_card_rounded;
    }
  }

  static Widget getCardIconWidget(CardType type, {double size = 24, Color? color}) {
    switch (type) {
      case CardType.visa:
        return Icon(FontAwesomeIcons.ccVisa, color: color ?? const Color(0xFF1A1F71), size: size);
      case CardType.mastercard:
        return Icon(FontAwesomeIcons.ccMastercard, color: color ?? const Color(0xFFEB001B), size: size);
      case CardType.amex:
        return Icon(FontAwesomeIcons.ccAmex, color: color ?? const Color(0xFF007CC3), size: size);
      case CardType.discover:
        return Icon(FontAwesomeIcons.ccDiscover, color: color ?? const Color(0xFFFF6000), size: size);
      case CardType.dinersClub:
        return Icon(FontAwesomeIcons.ccDinersClub, color: color ?? const Color(0xFF0079C1), size: size);
      case CardType.jcb:
        return Icon(FontAwesomeIcons.ccJcb, color: color ?? const Color(0xFF002F87), size: size);
      default:
        return Icon(Icons.credit_card_rounded, color: color ?? Colors.grey.shade400, size: size);
    }
  }

  static bool isValidCardNumber(String cardNumber) {
    String cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.isEmpty) return false;

    CardType type = detectCardType(cleanNumber);
    int expectedLength;
    switch (type) {
      case CardType.amex: expectedLength = 15; break;
      case CardType.dinersClub: expectedLength = 14; break;
      default: expectedLength = 16;
    }

    if (cleanNumber.length != expectedLength) return false;

    // Luhn Check
    int sum = 0;
    bool alternate = false;
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cleanNumber[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  static bool isValidExpiry(String expiry) {
    if (expiry.isEmpty) return false;
    String clean = expiry.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 4) return false;

    int month = int.parse(clean.substring(0, 2));
    int year = int.parse(clean.substring(2, 4)) + 2000;

    if (month < 1 || month > 12) return false;

    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;

    if (year < currentYear) return false;
    if (year == currentYear && month < currentMonth) return false;

    return true;
  }

  static bool isValidCVV(String cvv, CardType type) {
    String clean = cvv.replaceAll(RegExp(r'\D'), '');
    int expectedLength = (type == CardType.amex) ? 4 : 3;
    return clean.length == expectedLength;
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    var selectionEnd = newValue.selection.end;
    
    // If the user deleted a space, delete the character before it too to avoid getting stuck
    if (oldValue.text.length - text.length == 1 &&
        selectionEnd < oldValue.text.length &&
        oldValue.text[selectionEnd] == ' ') {
      if (selectionEnd > 0) {
        text = text.substring(0, selectionEnd - 1) + text.substring(selectionEnd);
        selectionEnd--;
      }
    }
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }
    
    // Remove all non-digits
    final cleanString = text.replaceAll(RegExp(r'\D'), '');
    final type = CardValidator.detectCardType(cleanString);
    
    int maxDigits;
    List<int> spacePositions;
    if (type == CardType.amex) {
      maxDigits = 15;
      spacePositions = [4, 10]; // Spaces after index 4 and 10 of digits
    } else if (type == CardType.dinersClub) {
      maxDigits = 14;
      spacePositions = [4, 10]; // Spaces after index 4 and 10 of digits
    } else {
      maxDigits = 16;
      spacePositions = [4, 8, 12]; // Spaces after index 4, 8, and 12 of digits
    }
    
    // Truncate to maximum length
    String truncatedString = cleanString;
    if (cleanString.length > maxDigits) {
      truncatedString = cleanString.substring(0, maxDigits);
    }
    
    final formatted = StringBuffer();
    for (int i = 0; i < truncatedString.length; i++) {
      formatted.write(truncatedString[i]);
      if (spacePositions.contains(i + 1) && i != truncatedString.length - 1) {
        formatted.write(' ');
      }
    }
    
    final newText = formatted.toString();
    
    // Count digits before cursor in clean text
    int digitsBeforeCursor = 0;
    for (int i = 0; i < selectionEnd && i < text.length; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) {
        digitsBeforeCursor++;
      }
    }
    
    int digitsFound = 0;
    int selectionOffset = 0;
    for (int i = 0; i < newText.length; i++) {
      selectionOffset = i + 1;
      if (RegExp(r'\d').hasMatch(newText[i])) {
        digitsFound++;
      }
      if (digitsFound == digitsBeforeCursor) {
        break;
      }
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}

class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    var selectionEnd = newValue.selection.end;
    
    // If the user deleted a slash, delete the character before it too to avoid getting stuck
    if (oldValue.text.length - text.length == 1 &&
        selectionEnd < oldValue.text.length &&
        oldValue.text[selectionEnd] == '/') {
      if (selectionEnd > 0) {
        text = text.substring(0, selectionEnd - 1) + text.substring(selectionEnd);
        selectionEnd--;
      }
    }
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }
    
    // Remove all non-digits
    String cleanString = text.replaceAll(RegExp(r'\D'), '');
    
    // Auto-prefix if first digit is > 1
    if (cleanString.length == 1 && int.parse(cleanString) > 1) {
      cleanString = '0$cleanString';
    }
    
    // Limit to 4 digits (MMYY)
    if (cleanString.length > 4) {
      cleanString = cleanString.substring(0, 4);
    }
    
    final formatted = StringBuffer();
    for (int i = 0; i < cleanString.length; i++) {
      formatted.write(cleanString[i]);
      if (i == 1 && cleanString.length > 2) {
        formatted.write('/');
      }
    }
    
    final newText = formatted.toString();
    
    // Count digits before cursor
    int digitsBeforeCursor = 0;
    for (int i = 0; i < selectionEnd && i < text.length; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) {
        digitsBeforeCursor++;
      }
    }
    
    // Adjust if we auto-prefixed
    if (text.length == 1 && cleanString.length == 2 && cleanString.startsWith('0')) {
      digitsBeforeCursor = 2;
    }
    
    int digitsFound = 0;
    int selectionOffset = 0;
    for (int i = 0; i < newText.length; i++) {
      selectionOffset = i + 1;
      if (RegExp(r'\d').hasMatch(newText[i])) {
        digitsFound++;
      }
      if (digitsFound == digitsBeforeCursor) {
        break;
      }
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}
