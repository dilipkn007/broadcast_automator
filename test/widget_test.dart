import 'package:flutter_test/flutter_test.dart';
import 'package:broadcast_automator/services/native_bridge.dart';

void main() {
  test('Smoke test', () {
    expect(1 + 1, equals(2));
  });

  group('CSV Parsing & Contacts', () {
    test('parseCsv handles standard commas and quoted strings', () {
      const csv = 'Name,Phone\n"John, Jr.",+123456789\nJane,+987654321';
      final rows = parseCsv(csv);
      expect(rows.length, equals(3));
      expect(rows[0], equals(['Name', 'Phone']));
      expect(rows[1], equals(['John, Jr.', '+123456789']));
      expect(rows[2], equals(['Jane', '+987654321']));
    });

    test('csvRowsToContacts maps headers correctly', () {
      final rows = [
        ['Customer Name', 'Mobile Phone', 'Notes'],
        ['Alice', '+111111111', 'VIP'],
        ['Bob', '+222222222', 'Lead'],
      ];
      final contacts = csvRowsToContacts(rows);
      expect(contacts.length, equals(2));
      expect(contacts[0], equals({'name': 'Alice', 'phone': '+111111111'}));
      expect(contacts[1], equals({'name': 'Bob', 'phone': '+222222222'}));
    });

    test('resolveMessageTemplate replaces dynamic tags', () {
      const template = 'Hi {name}, your phone is {{phone}}!';
      final resolved = resolveMessageTemplate(template, {
        'name': 'Alice',
        'phone': '+123456789',
      });
      expect(resolved, equals('Hi Alice, your phone is +123456789!'));
    });
  });

  group('Smart Quick-Paste Contacts Parsing', () {
    test('parses plain phone numbers one per line with sanitization', () {
      const input = '9876543210\n+91 98765 43211\n(555) 234-5678';
      final contacts = parseRawTextContacts(input);
      expect(contacts.length, equals(3));
      expect(contacts[0], equals({'name': '', 'phone': '9876543210'}));
      expect(contacts[1], equals({'name': '', 'phone': '+919876543211'}));
      expect(contacts[2], equals({'name': '', 'phone': '5552345678'}));
    });

    test('parses names and numbers with various separators and numbering', () {
      const input = '''
John Doe - +91 9876543210
Alice: 9876543211
Bob | +1 (555) 123-4567
1. Rahul Sharma: 9876543212
~ Vikram: +91 98765 43213
9876543214 - Charlie Brown
''';
      final contacts = parseRawTextContacts(input);
      expect(contacts.length, equals(6));
      expect(contacts[0], equals({'name': 'John Doe', 'phone': '+919876543210'}));
      expect(contacts[1], equals({'name': 'Alice', 'phone': '9876543211'}));
      expect(contacts[2], equals({'name': 'Bob', 'phone': '+15551234567'}));
      expect(contacts[3], equals({'name': 'Rahul Sharma', 'phone': '9876543212'}));
      expect(contacts[4], equals({'name': 'Vikram', 'phone': '+919876543213'}));
      expect(contacts[5], equals({'name': 'Charlie Brown', 'phone': '9876543214'}));
    });

    test('parses tab-separated text copied from Excel / Google Sheets', () {
      const input = 'Product Sales\t+919876543210\nSupport Desk\t+919876543211';
      final contacts = parseRawTextContacts(input);
      expect(contacts.length, equals(2));
      expect(contacts[0], equals({'name': 'Product Sales', 'phone': '+919876543210'}));
      expect(contacts[1], equals({'name': 'Support Desk', 'phone': '+919876543211'}));
    });

    test('parses comma-separated numbers on a single line and deduplicates', () {
      const input = '9876543210, 9876543211, 9876543210, 9876543212';
      final contacts = parseRawTextContacts(input);
      expect(contacts.length, equals(3));
      expect(contacts[0]['phone'], equals('9876543210'));
      expect(contacts[1]['phone'], equals('9876543211'));
      expect(contacts[2]['phone'], equals('9876543212'));
    });

    test('ignores non-phone text and lines with fewer than 7 digits', () {
      const input = 'Hello World!\nShort 12345\nValid: 9876543210';
      final contacts = parseRawTextContacts(input);
      expect(contacts.length, equals(1));
      expect(contacts[0], equals({'name': 'Valid', 'phone': '9876543210'}));
    });
  });
}
