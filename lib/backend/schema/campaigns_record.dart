import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/supabase_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/supabase/supabase_config.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CampaignsRecord extends SupabaseRecord {
  CampaignsRecord._(
    String id,
    Map<String, dynamic> data,
  ) : super(id, data) {
    _initializeFields();
  }

  // "device_id" field.
  String? _deviceId;
  String get deviceId => _deviceId ?? '';
  bool hasDeviceId() => _deviceId != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "contact_count" field.
  int? _contactCount;
  int get contactCount => _contactCount ?? 0;
  bool hasContactCount() => _contactCount != null;

  // "created_at" field.
  String? _createdAt;
  String get createdAt => _createdAt ?? '';
  bool hasCreatedAt() => _createdAt != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "message_body" field.
  String? _messageBody;
  String get messageBody => _messageBody ?? '';
  bool hasMessageBody() => _messageBody != null;

  // "delay_seconds" field.
  int? _delaySeconds;
  int get delaySeconds => _delaySeconds ?? 0;
  bool hasDelaySeconds() => _delaySeconds != null;

  // "randomize_delay" field.
  bool? _randomizeDelay;
  bool get randomizeDelay => _randomizeDelay ?? false;
  bool hasRandomizeDelay() => _randomizeDelay != null;

  // "skip_invalid" field.
  bool? _skipInvalid;
  bool get skipInvalid => _skipInvalid ?? false;
  bool hasSkipInvalid() => _skipInvalid != null;

  // "auto_retry" field.
  bool? _autoRetry;
  bool get autoRetry => _autoRetry ?? false;
  bool hasAutoRetry() => _autoRetry != null;

  // "current_index" field.
  int? _currentIndex;
  int get currentIndex => _currentIndex ?? 0;
  bool hasCurrentIndex() => _currentIndex != null;

  void _initializeFields() {
    _deviceId = snapshotData['device_id'] as String?;
    _name = snapshotData['name'] as String?;
    _contactCount = castToType<int>(snapshotData['contact_count']);
    _createdAt = snapshotData['created_at'] as String?;
    _status = snapshotData['status'] as String?;
    _messageBody = snapshotData['message_body'] as String?;
    _delaySeconds = castToType<int>(snapshotData['delay_seconds']);
    _randomizeDelay = snapshotData['randomize_delay'] as bool?;
    _skipInvalid = snapshotData['skip_invalid'] as bool?;
    _autoRetry = snapshotData['auto_retry'] as bool?;
    _currentIndex = castToType<int>(snapshotData['current_index']);
  }

  static String get tableName => 'campaigns';

  static CampaignsRecord fromMap(Map<String, dynamic> data) =>
      CampaignsRecord._(
        (data['id'] ?? '').toString(),
        mapFromSupabase(data),
      );

  static Stream<CampaignsRecord> getDocument(String id) async* {
    if (id.isEmpty) return;
    try {
      final doc = await getDocumentOnce(id);
      if (doc != null) yield doc;
    } catch (e) {
      print('Initial getDocumentOnce error for $tableName: $e');
    }

    final controller = StreamController<CampaignsRecord>();
    StreamSubscription? sub;
    try {
      final stream = supabase
          .from(tableName)
          .stream(primaryKey: ['id'])
          .eq('id', id)
          .map((rows) => rows.isNotEmpty ? fromMap(rows.first) : null)
          .where((e) => e != null)
          .map((e) => e!);

      sub = stream.listen(
        (data) {
          if (!controller.isClosed) controller.add(data);
        },
        onError: (err) {
          print('Realtime error on $tableName getDocument: $err');
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('Failed to setup realtime stream for $tableName: $e');
    }

    try {
      await for (final data in controller.stream) {
        yield data;
      }
    } finally {
      await sub?.cancel();
      await controller.close();
    }
  }

  static Future<CampaignsRecord?> getDocumentOnce(String id) async {
    try {
      final rows = await supabase.from(tableName).select().eq('id', id).timeout(const Duration(seconds: 4));
      if (rows.isEmpty) return null;
      return fromMap(rows.first as Map<String, dynamic>);
    } catch (e) {
      print('Error in getDocumentOnce for $tableName: $e');
      return null;
    }
  }

  @override
  String toString() => 'CampaignsRecord(id: $id, data: $snapshotData)';

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) =>
      other is CampaignsRecord && id.hashCode == other.id.hashCode;
}

Map<String, dynamic> createCampaignsRecordData({
  String? deviceId,
  String? name,
  int? contactCount,
  String? createdAt,
  String? status,
  String? messageBody,
  int? delaySeconds,
  bool? randomizeDelay,
  bool? skipInvalid,
  bool? autoRetry,
  int? currentIndex,
}) {
  final supabaseData = mapToSupabase(
    <String, dynamic>{
      'device_id': deviceId,
      'name': name,
      'contact_count': contactCount,
      'created_at': createdAt,
      'status': status,
      'message_body': messageBody,
      'delay_seconds': delaySeconds,
      'randomize_delay': randomizeDelay,
      'skip_invalid': skipInvalid,
      'auto_retry': autoRetry,
      'current_index': currentIndex,
    }.withoutNulls,
  );

  return supabaseData;
}

class CampaignsRecordDocumentEquality implements Equality<CampaignsRecord> {
  const CampaignsRecordDocumentEquality();

  @override
  bool equals(CampaignsRecord? e1, CampaignsRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.contactCount == e2?.contactCount &&
        e1?.createdAt == e2?.createdAt &&
        e1?.status == e2?.status &&
        e1?.messageBody == e2?.messageBody &&
        e1?.delaySeconds == e2?.delaySeconds &&
        e1?.randomizeDelay == e2?.randomizeDelay &&
        e1?.skipInvalid == e2?.skipInvalid &&
        e1?.autoRetry == e2?.autoRetry &&
        e1?.currentIndex == e2?.currentIndex;
  }

  @override
  int hash(CampaignsRecord? e) => const ListEquality().hash([
        e?.name,
        e?.contactCount,
        e?.createdAt,
        e?.status,
        e?.messageBody,
        e?.delaySeconds,
        e?.randomizeDelay,
        e?.skipInvalid,
        e?.autoRetry,
        e?.currentIndex
      ]);

  @override
  bool isValidKey(Object? o) => o is CampaignsRecord;
}
