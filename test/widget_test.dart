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
}
