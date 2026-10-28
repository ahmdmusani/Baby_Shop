import 'package:flutter_test/flutter_test.dart';
import 'package:the_baby_shop/utils/card_validator.dart';

void main() {
  group('CardValidator detectCardType Tests', () {
    test('Detect Visa', () {
      expect(CardValidator.detectCardType('4000123456789010'), CardType.visa);
      expect(CardValidator.detectCardType('4111 1111 1111 1111'), CardType.visa);
      expect(CardValidator.detectCardType('Visa'), CardType.visa);
      expect(CardValidator.detectCardType('VISA'), CardType.visa);
    });

    test('Detect Mastercard', () {
      expect(CardValidator.detectCardType('5100123456789010'), CardType.mastercard);
      expect(CardValidator.detectCardType('2221000000000000'), CardType.mastercard);
      expect(CardValidator.detectCardType('Mastercard'), CardType.mastercard);
    });

    test('Detect American Express', () {
      expect(CardValidator.detectCardType('340012345678901'), CardType.amex);
      expect(CardValidator.detectCardType('370012345678901'), CardType.amex);
      expect(CardValidator.detectCardType('Amex'), CardType.amex);
      expect(CardValidator.detectCardType('American Express'), CardType.amex);
    });

    test('Detect Discover', () {
      expect(CardValidator.detectCardType('6011000000000000'), CardType.discover);
      expect(CardValidator.detectCardType('6500000000000000'), CardType.discover);
      expect(CardValidator.detectCardType('Discover'), CardType.discover);
    });

    test('Detect Diners Club', () {
      expect(CardValidator.detectCardType('30000000000000'), CardType.dinersClub);
      expect(CardValidator.detectCardType('36000000000000'), CardType.dinersClub);
      expect(CardValidator.detectCardType('Diners Club'), CardType.dinersClub);
    });
  });

  group('CardValidator Luhn Check Tests', () {
    test('Valid Visa Card', () {
      // 4000 2222 2222 2222 is a valid card with Luhn check
      expect(CardValidator.isValidCardNumber('4000 2222 2222 2222'), true);
    });

    test('Invalid Visa Card', () {
      // Modified last digit so it fails Luhn
      expect(CardValidator.isValidCardNumber('4000 2222 2222 2223'), false);
    });

    test('Short Card Number', () {
      expect(CardValidator.isValidCardNumber('4000 2222'), false);
    });
  });

  group('CardValidator Expiry Validation Tests', () {
    test('Valid Future Date', () {
      expect(CardValidator.isValidExpiry('12/30'), true);
    });

    test('Invalid Month', () {
      expect(CardValidator.isValidExpiry('15/28'), false);
    });

    test('Expired Date', () {
      expect(CardValidator.isValidExpiry('01/20'), false);
    });

    test('Malformed Date', () {
      expect(CardValidator.isValidExpiry('123'), false);
    });
  });

  group('CardValidator CVV Validation Tests', () {
    test('Standard Card CVV', () {
      expect(CardValidator.isValidCVV('123', CardType.visa), true);
      expect(CardValidator.isValidCVV('12', CardType.visa), false);
      expect(CardValidator.isValidCVV('1234', CardType.visa), false);
    });

    test('Amex Card CVV', () {
      expect(CardValidator.isValidCVV('1234', CardType.amex), true);
      expect(CardValidator.isValidCVV('123', CardType.amex), false);
    });
  });
}
