import 'package:nop_db/database/nop.dart';
import 'package:sqlite3/sqlite3.dart';

class NopDatabaseImpl extends NopDatabase {
  NopDatabaseImpl._(String path) : super(path);

  late Database db;

  @override
  late final execute = db.execute;

  @override
  late final rawQuery = _query;

  @override
  late final rawDelete = _inneridu;

  @override
  late final rawUpdate = _inneridu;

  @override
  late final rawInsert = _inneridu;

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
    required DatabaseOnCreate onCreate,
    int version = 1,
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
      assert(onUpgrade != null, 'onUpgrade == null');

      if (onUpgrade != null) {
        db.userVersion = version;
        onUpgrade(this, _old, version);
      }
    } else if (_old > version) {
      assert(onDowngrade != null, 'onDowngrade == null');

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
  void dispose() {
    super.dispose();
    db.dispose();
  }
}
