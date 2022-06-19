import 'dart:async';

import 'package:nop/nop.dart';
import 'package:nop_db/nop_db.dart';
import 'package:sqlite3/sqlite3.dart';

class NopDatabaseImpl extends NopDatabase {
  NopDatabaseImpl._(String path) : super(path);

  late Database db;

  static FutureOr<NopDatabase> open(
    String path, {
    required DatabaseOnCreate onCreate,
    int version = 1,
    DatabaseUpgrade? onUpgrade,
    DatabaseUpgrade? onDowngrade,
  }) {
    final nop = NopDatabaseImpl._(path);

    return nop
        ._open(
          version: version,
          onCreate: onCreate,
          onUpgrade: onUpgrade,
          onDowngrade: onDowngrade,
        )
        .then((_) => nop);
  }

  FutureOr<void> _open({
    int version = 1,
    required DatabaseOnCreate onCreate,
    DatabaseUpgrade? onUpgrade,
    DatabaseUpgrade? onDowngrade,
  }) {
    assert(version > 0);

    db = sqlite3.open(path);
    final oldVersion = db.userVersion;

    if (oldVersion == 0) {
      db.userVersion = version;
      return onCreate(this, version);
    } else if (oldVersion < version) {
      if (onUpgrade != null) {
        db.userVersion = version;
        return onUpgrade(this, oldVersion, version);
      }
    } else if (oldVersion > version) {
      if (onDowngrade != null) {
        db.userVersion = version;
        return onDowngrade(this, oldVersion, version);
      }
    }
  }

  @override
  void execute(String sql, [List<Object?> parameters = const []]) =>
      db.execute(sql, parameters);
  @override
  FutureOr<List<Map<String, Object?>>> rawQuery(String sql,
          [List<Object?> parameters = const []]) =>
      db.select(sql, parameters).toList();
  @override
  FutureOr<int> rawUpdate(String sql, [List<Object?> parameters = const []]) =>
      _inneridu(sql, parameters);
  @override
  FutureOr<int> rawDelete(String sql, [List<Object?> parameters = const []]) =>
      _inneridu(sql, parameters);
  @override
  FutureOr<int> rawInsert(String sql, [List<Object?> parameters = const []]) =>
      _inneridu(sql, parameters);

  int _inneridu(String sql, [List<Object?> parameters = const []]) {
    execute(sql, parameters);

    return db.getUpdatedRows();
  }

  @override
  SqlitePrepare prepare(String sql,
      {bool persistent = false, bool vtab = true, bool checkNoTail = false}) {
    return SqlitePrepare(db.prepare(sql), db);
  }

  @override
  void disposeNop() {
    db.dispose();
    super.disposeNop();
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
  FutureOr<void> execute([List<Object?> parameters = const []]) {
    sqlitePrepare.execute(parameters);
  }

  @override
  FutureOr<int> rawDelete([List<Object?> parameters = const []]) =>
      _inneridu(parameters);

  @override
  FutureOr<int> rawInsert([List<Object?> parameters = const []]) =>
      _inneridu(parameters);

  @override
  FutureOr<int> rawUpdate([List<Object?> parameters = const []]) =>
      _inneridu(parameters);

  @override
  FutureOr<List<Map<String, Object?>>> rawQuery(
      [List<Object?> parameters = const []]) {
    return sqlitePrepare.select(parameters).toList();
  }

  int _inneridu([List<Object?> parameters = const []]) {
    execute(parameters);
    return db.getUpdatedRows();
  }
}
