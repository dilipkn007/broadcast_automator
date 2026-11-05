import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/supabase_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/sqlite/local_database.dart';

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

  static Stream<AttachmentsRecord> getDocument(String id) {
    if (id.isEmpty) return const Stream.empty();
    return localDb
        .streamDocument(tableName, id)
        .where((row) => row != null)
        .map((row) => fromMap(row!));
  }

  static Future<AttachmentsRecord?> getDocumentOnce(String id) async {
    try {
      final rows = await localDb.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) return null;
      return fromMap(rows.first);
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
