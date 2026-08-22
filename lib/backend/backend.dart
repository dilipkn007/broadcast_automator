import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/supabase/supabase_config.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '/app_state.dart';
import 'schema/util/supabase_util.dart';

import 'schema/campaigns_record.dart';
import 'schema/contacts_record.dart';
import 'schema/attachments_record.dart';

export 'dart:async' show StreamSubscription;
export '/backend/supabase/supabase_config.dart';
export 'schema/index.dart';
export 'schema/util/supabase_util.dart';
export 'schema/util/schema_util.dart';

export 'schema/campaigns_record.dart';
export 'schema/contacts_record.dart';
export 'schema/attachments_record.dart';

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
// 3. FETCHING CAMPAIGNS: AUTOMATIC ANONYMOUS DEVICE_ID FILTERING
// Filters public.campaigns queries to only return records matching the current
// user's saved 'user_device_uuid'.
// ---------------------------------------------------------------------------
Future<int> queryCampaignsRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryCollectionCount(
      CampaignsRecord.tableName,
      queryBuilder: (q) {
        var query = q.where('device_id', isEqualTo: FFAppState().userDeviceUuid);
        if (queryBuilder != null) {
          query = queryBuilder(query);
        }
        return query;
      },
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
      queryBuilder: (q) {
        var query = q.where('device_id', isEqualTo: FFAppState().userDeviceUuid);
        if (queryBuilder != null) {
          query = queryBuilder(query);
        }
        return query;
      },
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
      queryBuilder: (q) {
        var query = q.where('device_id', isEqualTo: FFAppState().userDeviceUuid);
        if (queryBuilder != null) {
          query = queryBuilder(query);
        }
        return query;
      },
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

Future<int> queryCollectionCount(
  String table, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) async {
  final builder = queryBuilder ?? (q) => q;
  final query = builder(Query());
  dynamic request = supabase.from(table).select('id');
  request = _applyFilters(request, query);
  if (limit > 0) {
    request = request.limit(limit);
  }
  try {
    final response = await request.count(CountOption.exact).timeout(const Duration(seconds: 4));
    return response.count;
  } catch (err) {
    print('Error querying $table: $err');
    return 0;
  }
}

Stream<List<T>> queryCollection<T>(
  String table,
  RecordBuilder<T> recordBuilder, {
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) async* {
  // 1. Immediately fetch initial data via REST for instant UI load & resilience
  List<T> initialData = [];
  try {
    initialData = await queryCollectionOnce(
      table,
      recordBuilder,
      queryBuilder: queryBuilder,
      limit: limit,
      singleRecord: singleRecord,
    );
  } catch (err) {
    print('Initial queryCollectionOnce error for $table: $err');
  }
  yield initialData;

  // 2. Set up realtime stream to listen for live updates
  final builder = queryBuilder ?? (q) => q;
  final query = builder(Query());

  final controller = StreamController<List<T>>();
  StreamSubscription? subscription;

  try {
    SupabaseStreamBuilder stream = supabase.from(table).stream(primaryKey: ['id']);
    stream = _applyStreamFilters(stream, query);
    if (limit > 0 || singleRecord) {
      stream = stream.limit(singleRecord ? 1 : limit);
    } else {
      stream = stream.limit(50000);
    }

    final mappedStream = stream.map((rows) => rows
        .map(
          (d) => safeGet(
            () => recordBuilder(d),
            (e) => print('Error serializing row in $table:\n$e'),
          ),
        )
        .where((d) => d != null)
        .map((d) => d!)
        .toList());

    subscription = mappedStream.listen(
      (data) {
        if (!controller.isClosed) {
          controller.add(data);
        }
      },
      onError: (err) {
        print('Realtime stream error on $table: $err');
      },
      cancelOnError: false,
    );
  } catch (e) {
    print('Failed to initialize realtime stream on $table: $e');
  }

  try {
    await for (final data in controller.stream) {
      yield data;
    }
  } finally {
    await subscription?.cancel();
    await controller.close();
  }
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
  dynamic request = supabase.from(table).select();
  request = _applyFilters(request, query);
  if (limit > 0 || singleRecord) {
    request = request.limit(singleRecord ? 1 : limit);
  } else {
    request = request.limit(50000);
  }
  try {
    final rows = await request.timeout(const Duration(seconds: 4));
    final list = rows as List;
    return list
        .map(
          (d) => safeGet(
            () => recordBuilder(d as Map<String, dynamic>),
            (e) => print('Error serializing row in $table:\n$e'),
          ),
        )
        .where((d) => d != null)
        .map((d) => d!)
        .toList();
  } catch (err) {
    print('Error querying $table: $err');
    return [];
  }
}

dynamic _applyFilters(
  dynamic request,
  Query query,
) {
  var r = request;
  for (final f in query._filters) {
    switch (f.op) {
      case 'eq':
        r = r.eq(f.field, f.value);
      case 'neq':
        r = r.neq(f.field, f.value);
      case 'lt':
        r = r.lt(f.field, f.value);
      case 'lte':
        r = r.lte(f.field, f.value);
      case 'gt':
        r = r.gt(f.field, f.value);
      case 'gte':
        r = r.gte(f.field, f.value);
      case 'is':
        r = r.isFilter(f.field, f.value);
      case 'in':
        r = r.inFilter(f.field, f.value as List);
    }
  }
  if (query.orderField != null) {
    r = r.order(query.orderField!, ascending: !query.orderDescending);
  }
  if (query.limitValue != null) {
    r = r.limit(query.limitValue!);
  }
  return r;
}

dynamic _applyStreamFilters(
  dynamic stream,
  Query query,
) {
  var s = stream;
  for (final f in query._filters) {
    switch (f.op) {
      case 'eq':
        s = s.eq(f.field, f.value);
      case 'neq':
        s = s.neq(f.field, f.value);
      case 'lt':
        s = s.lt(f.field, f.value);
      case 'lte':
        s = s.lte(f.field, f.value);
      case 'gt':
        s = s.gt(f.field, f.value);
      case 'gte':
        s = s.gte(f.field, f.value);
    }
  }
  if (query.orderField != null) {
    s = s.order(query.orderField!, ascending: !query.orderDescending);
  }
  if (query.limitValue != null) {
    s = s.limit(query.limitValue!);
  }
  return s;
}
