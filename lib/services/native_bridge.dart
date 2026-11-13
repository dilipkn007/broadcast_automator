import 'dart:convert';

import 'package:flutter/services.dart';

/// Bridges Flutter <-> native Android for WhatsApp automation, system
/// overlay, CSV import and attachment picking.
class NativeBridge {
  NativeBridge._();

  static const MethodChannel _channel =
      MethodChannel('com.makhanchor.broadcastautomator/native');

  /// Starts an automated WhatsApp broadcast for [campaignId].
  /// Returns a map with `started`, `accessibilityEnabled`, `overlayPermission`
  /// and optionally `error`.
  static Future<Map<String, dynamic>> startBroadcast(String campaignId) async {
    final result = await _channel.invokeMethod('startBroadcast', {
      'campaignId': campaignId,
    });
    return _toMap(result);
  }

  static Future<void> stopBroadcast() async {
    await _channel.invokeMethod('stopBroadcast');
  }

  static Future<void> pauseBroadcast() async {
    await _channel.invokeMethod('pauseBroadcast');
  }

  static Future<void> resumeBroadcast() async {
    await _channel.invokeMethod('resumeBroadcast');
  }

  /// Live status of the running broadcast job (read from native prefs).
  static Future<Map<String, dynamic>> getBroadcastStatus() async {
    final result = await _channel.invokeMethod('getBroadcastStatus');
    return _toMap(result);
  }

  /// Full report of the last broadcast job including duration and contact results.
  static Future<Map<String, dynamic>> getBroadcastReport() async {
    final result = await _channel.invokeMethod('getBroadcastReport');
    return _toMap(result);
  }

  static Future<bool> isAccessibilityEnabled() async {
    final result = await _channel.invokeMethod('isAccessibilityEnabled');
    return result == true;
  }

  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  static Future<bool> canDrawOverlays() async {
    final result = await _channel.invokeMethod('canDrawOverlays');
    return result == true;
  }

  static Future<void> openOverlaySettings() async {
    await _channel.invokeMethod('openOverlaySettings');
  }

  /// Picks a .csv file and returns `{content, name}`.
  /// Throws [MissingPluginException] / [PlatformException] when unavailable
  /// or cancelled (error code `cancelled`).
  static Future<Map<String, dynamic>> pickCsv() async {
    final result = await _channel.invokeMethod('pickCsv');
    return _toMap(result);
  }

  /// Picks a media/document attachment, copies it into app storage and
  /// returns `{path, mimeType, name}`.
  static Future<Map<String, dynamic>> pickAttachment() async {
    final result = await _channel.invokeMethod('pickAttachment');
    return _toMap(result);
  }

  /// Checks whether READ_CONTACTS permission has been granted.
  static Future<bool> hasContactsPermission() async {
    final result = await _channel.invokeMethod('hasContactsPermission');
    return result == true;
  }

  /// Retrieves all contacts from the Android phonebook that have phone numbers.
  /// Automatically prompts for permission if not yet granted.
  /// Throws [PlatformException] with code `permission_denied` if denied by user.
  static Future<List<Map<String, String>>> getPhoneContacts() async {
    final result = await _channel.invokeMethod('getDeviceContacts');
    if (result is List) {
      return result.map((item) {
        if (item is Map) {
          return {
            'name': item['name']?.toString() ?? '',
            'phone': item['phone']?.toString() ?? '',
          };
        }
        return <String, String>{};
      }).where((c) => (c['phone'] ?? '').isNotEmpty).toList();
    }
    return [];
  }

  /// Opens the system contact picker to select a single contact without requiring permissions.
  static Future<Map<String, String>?> pickSingleContact() async {
    final result = await _channel.invokeMethod('pickSingleContact');
    if (result is Map) {
      return {
        'name': result['name']?.toString() ?? '',
        'phone': result['phone']?.toString() ?? '',
      };
    }
    return null;
  }

  /// Persists the automation job (contacts + message + settings + attachments) natively so
  /// the accessibility service can run it.
  static Future<void> saveJob({
    required String campaignId,
    required String campaignName,
    required String message,
    required int delaySeconds,
    int? preSendDelaySeconds,
    required bool randomizeDelay,
    required bool autoRetry,
    required bool skipInvalid,
    required List<Map<String, String>> contacts,
    String? attachmentPath,
    String? attachmentMime,
    List<Map<String, String>>? attachments,
    int? autoPauseMinutes,
  }) async {
    await _channel.invokeMethod('saveJob', {
      'campaignId': campaignId,
      'campaignName': campaignName,
      'message': message,
      'delaySeconds': delaySeconds,
      'preSendDelaySeconds': preSendDelaySeconds ?? 2,
      'randomizeDelay': randomizeDelay,
      'autoRetry': autoRetry,
      'skipInvalid': skipInvalid,
      'contacts': contacts,
      'attachmentPath': attachmentPath,
      'attachmentMime': attachmentMime,
      'attachments': attachments,
      'autoPauseMinutes': autoPauseMinutes,
    });
  }

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}

/// Sanitizes a phone number for WhatsApp deep links (Indian format default).
String normalizeWhatsAppNumber(String phone) {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return digits;
  if (digits.startsWith('0')) digits = digits.substring(1);
  if (digits.length == 10) digits = '91$digits';
  return digits;
}

/// Replaces `{Placeholder}` or `{{Placeholder}}` tokens in [message] with contact values (case-insensitive).
String resolveMessageTemplate(String message, Map<String, String> values) {
  var resolved = message;
  values.forEach((key, value) {
    final pattern = RegExp(
      '\\{\\{\\s*${RegExp.escape(key)}\\s*\\}\\}|\\{\\s*${RegExp.escape(key)}\\s*\\}',
      caseSensitive: false,
    );
    resolved = resolved.replaceAll(pattern, value);
  });
  return resolved;
}

List<String> _parseCsvRow(String line) {
  final cells = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buffer.write(ch);
      }
    } else {
      if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        cells.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
  }
  cells.add(buffer.toString().trim());
  return cells;
}

/// Parses [csvText] into rows of cells, handling quoted fields and
/// embedded commas/newlines.
List<List<String>> parseCsv(String csvText) {
  final rows = <List<String>>[];
  final lines = csvText.split(RegExp(r'\r?\n'));
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    rows.add(_parseCsvRow(line));
  }
  return rows;
}

/// Converts parsed CSV rows into `{name, phone}` contact maps, using the
/// header row (Name/Phone, case-insensitive) to locate columns. Falls back
/// to column order when no header matches.
List<Map<String, String>> csvRowsToContacts(List<List<String>> rows) {
  if (rows.isEmpty) return const [];

  var nameIdx = 0;
  var phoneIdx = 1;

  final header = rows.first.map((h) => h.toLowerCase()).toList();
  final nameHeader = header.indexWhere((h) => h.contains('name'));
  final phoneHeader = header.indexWhere((h) => h.contains('phone'));

  var startRow = 0;
  if (nameHeader != -1) nameIdx = nameHeader;
  if (phoneHeader != -1) phoneIdx = phoneHeader;
  if (nameHeader != -1 || phoneHeader != -1) startRow = 1;

  final contacts = <Map<String, String>>[];
  for (var r = startRow; r < rows.length; r++) {
    final row = rows[r];
    if (row.isEmpty) continue;
    final name = nameIdx < row.length ? row[nameIdx] : '';
    final phone = phoneIdx < row.length ? row[phoneIdx] : '';
    if (phone.trim().isEmpty) continue;
    contacts.add({'name': name.trim(), 'phone': phone.trim()});
  }
  return contacts;
}

String encodeJson(Object? value) => json.encode(value);

/// Parses raw pasted text (e.g. from WhatsApp, Notes, or Sheets) into contacts with name & phone.
/// Supports formats:
/// - Plain numbers: "9876543210" or "+91 98765 43210"
/// - "Name - Number": "John - +91 9876543210"
/// - "Name: Number": "Alice: 9876543211"
/// - "Name, Number": "Bob, 9876543212"
/// - "Number - Name": "9876543210 - David"
/// - Numbered lists: "1. Rahul: 9876543210"
/// - Tab or comma separated: "Jane Smith\t9876543210" or comma-separated lists of numbers
List<Map<String, String>> parseRawTextContacts(String rawText) {
  if (rawText.trim().isEmpty) return const [];

  final contacts = <Map<String, String>>[];
  final seenPhones = <String>{};

  final lines = rawText.split(RegExp(r'\r?\n'));
  final phonePattern = RegExp(r'(?:\+?\d[\d\s\-\(\)\.]{5,}\d)');

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    // Check for TSV or multiple separated segments
    if (line.contains('\t')) {
      final parts = line.split('\t').map((p) => p.trim()).toList();
      _extractFromParts(parts, contacts, seenPhones);
      continue;
    }

    final allMatches = phonePattern.allMatches(line).toList();

    if (allMatches.length > 1 && (line.contains(',') || line.contains(';'))) {
      final commaParts = line.split(RegExp(r'[,;]')).map((p) => p.trim()).toList();
      final allPhones = commaParts.every((p) {
        final digits = p.replaceAll(RegExp(r'[^\d]'), '');
        return digits.length >= 7 && digits.length <= 16;
      });

      if (allPhones) {
        for (final p in commaParts) {
          _addContact('', p, contacts, seenPhones);
        }
      } else {
        _extractFromParts(commaParts, contacts, seenPhones);
      }
    } else if (allMatches.isNotEmpty) {
      final match = allMatches.first;
      final phoneString = match.group(0)!;
      final cleanDigits = phoneString.replaceAll(RegExp(r'[^\d]'), '');

      if (cleanDigits.length >= 7 && cleanDigits.length <= 16) {
        var name = line.replaceFirst(phoneString, '').trim();
        name = name
            .replaceAll(RegExp(r'^[0-9]+[\.\)\-]\s*'), '')
            .replaceAll(RegExp(r'^[\s\-:,|~<>\(\)"]+|[\s\-:,|~<>\(\)"]+$'), '')
            .trim();

        _addContact(name, phoneString, contacts, seenPhones);
      }
    }
  }

  return contacts;
}

void _addContact(String name, String rawPhone, List<Map<String, String>> contacts, Set<String> seenPhones) {
  final trimmed = rawPhone.trim();
  final hasPlus = trimmed.startsWith('+');
  final digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.length < 7 || digits.length > 16) return;

  final cleanPhone = hasPlus ? '+$digits' : digits;
  if (seenPhones.add(cleanPhone)) {
    contacts.add({
      'name': name.trim(),
      'phone': cleanPhone,
    });
  }
}

void _extractFromParts(List<String> parts, List<Map<String, String>> contacts, Set<String> seenPhones) {
  if (parts.isEmpty) return;
  var name = '';
  var phone = '';

  for (final part in parts) {
    final digits = part.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 7 && digits.length <= 16 && phone.isEmpty) {
      phone = part;
    } else if (name.isEmpty && digits.length < 7) {
      name = part.replaceAll(RegExp(r'^"+|"+$'), '');
    }
  }

  if (phone.isNotEmpty) {
    _addContact(name, phone, contacts, seenPhones);
  }
}
