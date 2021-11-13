import 'dart:async';

import 'package:nop_db/database/nop.dart';
import 'package:sqlite3/sqlite3.dart';

class NopDatabaseImpl extends NopDatabase {
  NopDatabaseImpl._(String path) : super(path);

  late Database db;
  @override
  void execute(String sql, [List<Object?> paramters = const []]) =>
      db.execute(sql, paramters);
  @override
  FutureOr<List<Map<String, Object?>>> rawQuery(String sql,
          [List<Object?> paramters = const []]) =>
      _query(sql, paramters);
  @override
  FutureOr<int> rawUpdate(String sql, [List<Object?> paramters = const []]) =>
      _inneridu(sql, paramters);
  @override
  FutureOr<int> rawDelete(String sql, [List<Object?> paramters = const []]) =>
      _inneridu(sql, paramters);
  @override
  FutureOr<int> rawInsert(String sql, [List<Object?> paramters = const []]) =>
      _inneridu(sql, paramters);

  static NopDatabase openInMemory({
    required DatabaseOnCreate onCreate,
    int version = 1,
    DatabaseUpgrade? onUpgrade,
    DatabaseUpgrade? onDowngrade,
  }) {
    return open(NopDatabase.memory,
        version: version,
        onCreate: onCreate,
        onDowngrade: onDowngrade,
        onUpgrade: onUpgrade);
  }

  static NopDatabase open(
    String path, {
    required DatabaseOnCreate onCreate,
    int version = 1,
    DatabaseUpgrade? onUpgrade,
    DatabaseUpgrade? onDowngrade,
  }) {
    // if (_openlist.containsKey(path)) return _openlist[path]!;

    final nop = NopDatabaseImpl._(path);

    nop._open(
      version: version,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
      onDowngrade: onDowngrade,
    );
    return nop;
  }

  void _open({
    int version = 1,
    required DatabaseOnCreate onCreate,
    DatabaseUpgrade? onUpgrade,
    DatabaseUpgrade? onDowngrade,
  }) {
    assert(version > 0);

    db = sqlite3.open(path);
    final _old = db.userVersion;

    if (_old == 0) {
      onCreate(this, version);
      db.userVersion = version;
    } else if (_old < version) {
      if (onUpgrade != null) {
        db.userVersion = version;
        onUpgrade(this, _old, version);
      }
    } else if (_old > version) {
      if (onDowngrade != null) {
        db.userVersion = version;
        onDowngrade(this, _old, version);
      }
    }
  }

  List<Map<String, Object?>> _query(String sql,
      [List<Object?> parameters = const []]) {
    return db.select(sql, parameters).toList();
  }

  int _inneridu(String sql, [List<Object?> paramters = const []]) {
    execute(sql, paramters);

    return db.getUpdatedRows();
  }

  @override
  SqlitePrepare prepare(String sql,
      {bool persistent = false, bool vtab = true, bool checkNoTail = false}) {
    return SqlitePrepare(db.prepare(sql), db);
  }

  @override
  void dispose() {
    super.dispose();
    db.dispose();
  }
}

class SqlitePrepare extends NopPrepare {
  SqlitePrepare(this.sqlitePrepare, this.db);
  final PreparedStatement sqlitePrepare;
  final Database db;
  @override
  void dispose() {
    sqlitePrepare.dispose();
  }

  @override
  FutureOr<void> execute([List<Object?> paramters = const []]) {
    sqlitePrepare.execute(paramters);
  }

  @override
  FutureOr<int> rawDelete([List<Object?> paramters = const []]) =>
      _inneridu(paramters);

  @override
  FutureOr<int> rawInsert([List<Object?> paramters = const []]) =>
      _inneridu(paramters);

  @override
  FutureOr<int> rawUpdate([List<Object?> paramters = const []]) =>
      _inneridu(paramters);

  @override
  FutureOr<List<Map<String, Object?>>> rawQuery(
      [List<Object?> paramters = const []]) {
    return sqlitePrepare.select(paramters).toList();
  }

  int _inneridu([List<Object?> paramters = const []]) {
    execute(paramters);
    return db.getUpdatedRows();
  }
}
