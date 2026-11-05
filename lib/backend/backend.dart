import 'dart:async';

import '/backend/sqlite/local_database.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '/app_state.dart';
import 'schema/util/supabase_util.dart';

import 'schema/campaigns_record.dart';
import 'schema/contacts_record.dart';
import 'schema/attachments_record.dart';

export 'dart:async' show StreamSubscription;
export '/backend/sqlite/local_database.dart';
export 'schema/index.dart';
export 'schema/util/supabase_util.dart';
export 'schema/util/schema_util.dart';

export 'schema/campaigns_record.dart';
export 'schema/contacts_record.dart';
export 'schema/attachments_record.dart';

// Backward compatibility alias so existing calls to supabase.from() work seamlessly
LocalDatabase get supabase => localDb;

/// Filter/ordering wrapper that mirrors the generated FlutterFlow query
/// builder API and translates into PostgREST filters.
class Query {
  Query();

  String? orderField;
  bool orderDescending = false;
  int? limitValue;
  final List<_QueryFilter> _filters = [];

  Query where(
    String field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    bool? isNull,
    List? whereIn,
  }) {
    if (isEqualTo != null) {
      _filters.add(_QueryFilter(field, 'eq', isEqualTo));
    } else if (isNotEqualTo != null) {
      _filters.add(_QueryFilter(field, 'neq', isNotEqualTo));
    } else if (isLessThan != null) {
      _filters.add(_QueryFilter(field, 'lt', isLessThan));
    } else if (isLessThanOrEqualTo != null) {
      _filters.add(_QueryFilter(field, 'lte', isLessThanOrEqualTo));
    } else if (isGreaterThan != null) {
      _filters.add(_QueryFilter(field, 'gt', isGreaterThan));
    } else if (isGreaterThanOrEqualTo != null) {
      _filters.add(_QueryFilter(field, 'gte', isGreaterThanOrEqualTo));
    } else if (isNull != null) {
      _filters.add(_QueryFilter(field, 'is', isNull));
    } else if (whereIn != null) {
      _filters.add(_QueryFilter(field, 'in', whereIn));
    }
    return this;
  }

  Query orderBy(String field, {bool descending = false}) {
    orderField = field;
    orderDescending = descending;
    return this;
  }

  Query limit(int limit) {
    limitValue = limit;
    return this;
  }
}

class _QueryFilter {
  _QueryFilter(this.field, this.op, this.value);
  final String field;
  final String op;
  final Object value;
}

// ---------------------------------------------------------------------------
// 3. FETCHING CAMPAIGNS (OFFLINE LOCAL SQLITE)
// ---------------------------------------------------------------------------
Future<int> queryCampaignsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      CampaignsRecord.tableName,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<CampaignsRecord>> queryCampaignsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      CampaignsRecord.tableName,
      CampaignsRecord.fromMap,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<CampaignsRecord>> queryCampaignsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      CampaignsRecord.tableName,
      CampaignsRecord.fromMap,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query ContactsRecords (as a Stream and as a Future).
Future<int> queryContactsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      ContactsRecord.tableName,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<ContactsRecord>> queryContactsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      ContactsRecord.tableName,
      ContactsRecord.fromMap,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ContactsRecord>> queryContactsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      ContactsRecord.tableName,
      ContactsRecord.fromMap,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

/// Functions to query AttachmentsRecords (as a Stream and as a Future).
Future<int> queryAttachmentsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      AttachmentsRecord.tableName,
      queryBuilder: queryBuilder,
      limit: limit,
    );

Stream<List<AttachmentsRecord>> queryAttachmentsRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollection(
      AttachmentsRecord.tableName,
      AttachmentsRecord.fromMap,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<AttachmentsRecord>> queryAttachmentsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCollectionOnce(
      AttachmentsRecord.tableName,
      AttachmentsRecord.fromMap,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );

class _SqlClause {
  final String? where;
  final List<Object?> whereArgs;
  final String? orderBy;
  final int? limit;

  _SqlClause({this.where, required this.whereArgs, this.orderBy, this.limit});
}

_SqlClause _translateQuery(Query query,
    {int limit = -1, bool singleRecord = false}) {
  final whereParts = <String>[];
  final whereArgs = <Object?>[];

  for (final f in query._filters) {
    switch (f.op) {
      case 'eq':
        whereParts.add('${f.field} = ?');
        whereArgs.add(f.value is bool ? ((f.value as bool) ? 1 : 0) : f.value);
        break;
      case 'neq':
        whereParts.add('${f.field} != ?');
        whereArgs.add(f.value is bool ? ((f.value as bool) ? 1 : 0) : f.value);
        break;
      case 'lt':
        whereParts.add('${f.field} < ?');
        whereArgs.add(f.value);
        break;
      case 'lte':
        whereParts.add('${f.field} <= ?');
        whereArgs.add(f.value);
        break;
      case 'gt':
        whereParts.add('${f.field} > ?');
        whereArgs.add(f.value);
        break;
      case 'gte':
        whereParts.add('${f.field} >= ?');
        whereArgs.add(f.value);
        break;
      case 'is':
        if (f.value == null) {
          whereParts.add('${f.field} IS NULL');
        } else {
          whereParts.add('${f.field} IS ?');
          whereArgs.add(f.value);
        }
        break;
      case 'in':
        final list = f.value as List;
        if (list.isEmpty) {
          whereParts.add('1 = 0');
        } else {
          final placeholders = List.filled(list.length, '?').join(', ');
          whereParts.add('${f.field} IN ($placeholders)');
          whereArgs.addAll(list);
        }
        break;
    }
  }

  String? orderBy;
  if (query.orderField != null) {
    orderBy = '${query.orderField} ${query.orderDescending ? 'DESC' : 'ASC'}';
  }

  int? finalLimit;
  if (singleRecord) {
    finalLimit = 1;
  } else if (limit > 0) {
    finalLimit = limit;
  } else if (query.limitValue != null) {
    finalLimit = query.limitValue;
  }

  return _SqlClause(
    where: whereParts.isNotEmpty ? whereParts.join(' AND ') : null,
    whereArgs: whereArgs,
    orderBy: orderBy,
    limit: finalLimit,
  );
}

Future<int> queryCollectionCount(
  String table, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) async {
  final builder = queryBuilder ?? (q) => q;
  final query = builder(Query());
  final sql = _translateQuery(query, limit: limit);
  return await localDb.queryCount(
    table,
    where: sql.where,
    whereArgs: sql.whereArgs,
  );
}

Stream<List<T>> queryCollection<T>(
  String table,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) {
  final builder = queryBuilder ?? (q) => q;
  final query = builder(Query());
  final sql = _translateQuery(query, limit: limit, singleRecord: singleRecord);

  return localDb
      .streamQuery(
        table,
        where: sql.where,
        whereArgs: sql.whereArgs,
        orderBy: sql.orderBy,
        limit: sql.limit,
      )
      .map((rows) => rows
          .map((d) => safeGet(
                () => recordBuilder(d),
                (e) => print('Error serializing row in $table:\n$e'),
              ))
          .where((d) => d != null)
          .map((d) => d!)
          .toList());
}

Future<List<T>> queryCollectionOnce<T>(
  String table,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) async {
  final builder = queryBuilder ?? (q) => q;
  final query = builder(Query());
  final sql = _translateQuery(query, limit: limit, singleRecord: singleRecord);

  final rows = await localDb.query(
    table,
    where: sql.where,
    whereArgs: sql.whereArgs,
    orderBy: sql.orderBy,
    limit: sql.limit,
  );

  return rows
      .map((d) => safeGet(
            () => recordBuilder(d),
            (e) => print('Error serializing row in $table:\n$e'),
          ))
      .where((d) => d != null)
      .map((d) => d!)
      .toList();
}
