import 'dart:async';
import 'dart:convert';
import 'package:utils/utils.dart';
import 'package:drift/drift.dart';
import 'package:drift/web.dart';
import 'package:nop_db/nop_db.dart';

class _QueryExe extends QueryExecutorUser {
  _QueryExe(this.schemaVersion, this.db, this.onCreate,
      {this.onDowngrade, this.onUpgrade});
  final NopDatabase db;
  DatabaseOnCreate onCreate;
  DatabaseUpgrade? onUpgrade;
  DatabaseUpgrade? onDowngrade;
  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {
    Log.e('version: ${details.versionNow}');
    if (!details.wasCreated) {
      return onCreate(db, details.versionNow);
    }
    if (details.hadUpgrade) {
      return onUpgrade?.call(
          db, details.versionBefore ?? 0, details.versionNow);
    } else {
      return onDowngrade?.call(
          db, details.versionBefore ?? 0, details.versionNow);
    }
  }

  @override
  final int schemaVersion;
}

class NopDatabaseImpl extends NopDatabase {
  NopDatabaseImpl._(String path) : super(path);

  late WebDatabase db;

  static Future<NopDatabase> open(
    String path, {
    required DatabaseOnCreate onCreate,
    int version = 1,
    DatabaseUpgrade? onUpgrade,
    DatabaseUpgrade? onDowngrade,
  }) async {
    final nop = NopDatabaseImpl._(path);

    await nop._open(
      version: version,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
      onDowngrade: onDowngrade,
    );
    return nop;
  }

  Future<void> _open({
    int version = 1,
    required DatabaseOnCreate onCreate,
    DatabaseUpgrade? onUpgrade,
    DatabaseUpgrade? onDowngrade,
  }) async {
    assert(version > 0);
    Log.e('sqlite_web: ____ open _____', onlyDebug: false);
    // final body = html.querySelector('body');
    // if (body != null) {
    //   for (var element in body.children) {
    //     if (element is html.ScriptElement) {
    //       var src = element.src;
    //       if (src.split('/').last == 'sql-wasm.js') {
    //         Log.i('waiting: sql-wasm.js loading..', onlyDebug: false);
    //         // await release(const Duration(milliseconds: 100));
    //         break;
    //       }
    //     }
    //   }
    // }

    db = WebDatabase(path);

    await db.ensureOpen(_QueryExe(version, this, onCreate,
        onUpgrade: onUpgrade, onDowngrade: onDowngrade));
    var count = 10;

    while (count > 0) {
      try {
        await release(const Duration(milliseconds: 100));
        final version = await rawInsert('PRAGMA user_version;');
        Log.w('version : $version', onlyDebug: false);
        break;
      } catch (e) {
        count--;
        Log.e('error: $e', onlyDebug: false);
      }
    }
  }

  @override
  Future<void> execute(String sql, [List<Object?> parameters = const []]) =>
      db.runCustom(sql, parameters);
  @override
  FutureOr<List<Map<String, Object?>>> rawQuery(String sql,
          [List<Object?> parameters = const []]) =>
      db.runSelect(sql, parameters);
  @override
  FutureOr<int> rawUpdate(String sql, [List<Object?> parameters = const []]) =>
      db.runUpdate(sql, parameters);
  @override
  FutureOr<int> rawDelete(String sql, [List<Object?> parameters = const []]) =>
      db.runDelete(sql, parameters);
  @override
  FutureOr<int> rawInsert(String sql, [List<Object?> parameters = const []]) =>
      db.runInsert(sql, parameters);

  @override
  NopPrepare prepare(String sql,
      {bool persistent = false, bool vtab = true, bool checkNoTail = false}) {
    throw UnimplementedError('暂未支持web');
  }

  @override
  Future<void> disposeNop() async {
    await db.close();
    return super.disposeNop();
  }
}

// class ImportJsLibraryWeb {
//   /// Injects the library by its [url]
//   static Future<void> import(String url) {
//     return _importJSLibraries([url]);
//   }

//   static html.ScriptElement _createScriptTag(String library) {
//     final html.ScriptElement script = html.ScriptElement()
//       ..type = "application/wasm"
//       ..charset = "utf-8"
//       // ..async = true
//       //..defer = true
//       ..src = library;
//     return script;
//   }

//   /// Injects a bunch of libraries in the <head> and returns a
//   /// Future that resolves when all load.
//   static Future<void> _importJSLibraries(List<String> libraries) async {
//     final List<Future<void>> loading = <Future<void>>[];
//     final head = html.querySelector('Body');
//     for (var library in libraries) {
//       if (!isImported(library)) {
//         final scriptTag = _createScriptTag(library);
//         loading
//             .add(scriptTag.onLoad.first.then((value) => Log.e('l.....$value')));
//         head?.children.add(scriptTag);
//       }
//     }

//     if (loading.isNotEmpty) {
//       head?.children.add(_createScriptTag(''));
//     }

//     Log.i('load..... ${head == null}');
//     await Future.any(loading);
//     Timer(const Duration(seconds: 1), () {
//       final has = context.hasProperty('initSqlJs');
//       Log.w('has ..... $has');
//     });
//     Log.i('load... end');
//   }

//   static bool _isLoaded(html.Element head, String url) {
//     for (var element in head.children) {
//       if (element is html.ScriptElement) {
//         if (element.src == url) {
//           return true;
//         }
//       }
//     }
//     return false;
//   }

//   static bool isImported(String url) {
//     final head = html.querySelector('head');
//     return head == null ? false : _isLoaded(head, url);
//   }
// }
