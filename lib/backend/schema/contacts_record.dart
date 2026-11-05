import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/supabase_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/sqlite/local_database.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ContactsRecord extends SupabaseRecord {
  ContactsRecord._(
    String id,
    Map<String, dynamic> data,
  ) : super(id, data) {
    _initializeFields();
  }

  // "campaign_id" field.
  String? _campaignId;
  String get campaignId => _campaignId ?? '';
  bool hasCampaignId() => _campaignId != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "phone" field.
  String? _phone;
  String get phone => _phone ?? '';
  bool hasPhone() => _phone != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  void _initializeFields() {
    _campaignId = snapshotData['campaign_id'] as String?;
    _name = snapshotData['name'] as String?;
    _phone = snapshotData['phone'] as String?;
    _status = snapshotData['status'] as String?;
  }

  static String get tableName => 'contacts';

  static ContactsRecord fromMap(Map<String, dynamic> data) => ContactsRecord._(
        (data['id'] ?? '').toString(),
        mapFromSupabase(data),
      );

  static Stream<ContactsRecord> getDocument(String id) {
    if (id.isEmpty) return const Stream.empty();
    return localDb
        .streamDocument(tableName, id)
        .where((row) => row != null)
        .map((row) => fromMap(row!));
  }

  static Future<ContactsRecord?> getDocumentOnce(String id) async {
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
  String toString() => 'ContactsRecord(id: $id, data: $snapshotData)';

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) =>
      other is ContactsRecord && id.hashCode == other.id.hashCode;
}

Map<String, dynamic> createContactsRecordData({
  String? campaignId,
  String? name,
  String? phone,
  String? status,
}) {
  final supabaseData = mapToSupabase(
    <String, dynamic>{
      'campaign_id': campaignId,
      'name': name,
      'phone': phone,
      'status': status,
    }.withoutNulls,
  );

  return supabaseData;
}

class ContactsRecordDocumentEquality implements Equality<ContactsRecord> {
  const ContactsRecordDocumentEquality();

  @override
  bool equals(ContactsRecord? e1, ContactsRecord? e2) {
    return e1?.campaignId == e2?.campaignId &&
        e1?.name == e2?.name &&
        e1?.phone == e2?.phone &&
        e1?.status == e2?.status;
  }

  @override
  int hash(ContactsRecord? e) =>
      const ListEquality().hash([e?.campaignId, e?.name, e?.phone, e?.status]);

  @override
  bool isValidKey(Object? o) => o is ContactsRecord;
}
