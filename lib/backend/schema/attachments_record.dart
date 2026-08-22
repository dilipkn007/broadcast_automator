import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/supabase_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/supabase/supabase_config.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AttachmentsRecord extends SupabaseRecord {
  AttachmentsRecord._(
    String id,
    Map<String, dynamic> data,
  ) : super(id, data) {
    _initializeFields();
  }

  // "campaign_id" field.
  String? _campaignId;
  String get campaignId => _campaignId ?? '';
  bool hasCampaignId() => _campaignId != null;

  // "source_url" field.
  String? _sourceUrl;
  String get sourceUrl => _sourceUrl ?? '';
  bool hasSourceUrl() => _sourceUrl != null;

  // "type" field.
  String? _type;
  String get type => _type ?? '';
  bool hasType() => _type != null;

  void _initializeFields() {
    _campaignId = snapshotData['campaign_id'] as String?;
    _sourceUrl = snapshotData['source_url'] as String?;
    _type = snapshotData['type'] as String?;
  }

  static String get tableName => 'attachments';

  static AttachmentsRecord fromMap(Map<String, dynamic> data) =>
      AttachmentsRecord._(
        (data['id'] ?? '').toString(),
        mapFromSupabase(data),
      );

  static Stream<AttachmentsRecord> getDocument(String id) async* {
    if (id.isEmpty) return;
    try {
      final doc = await getDocumentOnce(id);
      if (doc != null) yield doc;
    } catch (e) {
      print('Initial getDocumentOnce error for $tableName: $e');
    }

    final controller = StreamController<AttachmentsRecord>();
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

  static Future<AttachmentsRecord?> getDocumentOnce(String id) async {
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
  String toString() => 'AttachmentsRecord(id: $id, data: $snapshotData)';

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) =>
      other is AttachmentsRecord && id.hashCode == other.id.hashCode;
}

Map<String, dynamic> createAttachmentsRecordData({
  String? campaignId,
  String? sourceUrl,
  String? type,
}) {
  final supabaseData = mapToSupabase(
    <String, dynamic>{
      'campaign_id': campaignId,
      'source_url': sourceUrl,
      'type': type,
    }.withoutNulls,
  );

  return supabaseData;
}

class AttachmentsRecordDocumentEquality implements Equality<AttachmentsRecord> {
  const AttachmentsRecordDocumentEquality();

  @override
  bool equals(AttachmentsRecord? e1, AttachmentsRecord? e2) {
    return e1?.campaignId == e2?.campaignId &&
        e1?.sourceUrl == e2?.sourceUrl &&
        e1?.type == e2?.type;
  }

  @override
  int hash(AttachmentsRecord? e) =>
      const ListEquality().hash([e?.campaignId, e?.sourceUrl, e?.type]);

  @override
  bool isValidKey(Object? o) => o is AttachmentsRecord;
}
