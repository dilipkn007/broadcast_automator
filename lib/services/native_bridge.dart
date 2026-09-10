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

  /// Persists the automation job (contacts + message + settings + attachments) natively so
  /// the accessibility service can run it.
  static Future<void> saveJob({
    required String campaignId,
    required String campaignName,
    required String message,
    required int delaySeconds,
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
