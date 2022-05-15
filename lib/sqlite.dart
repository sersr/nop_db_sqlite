library nop_db_sqlite;

import 'dart:async';

import 'package:nop/nop.dart';
import 'nop_db_sqlite.dart' if (dart.library.html) 'nop_db_sqlite_web.dart';

FutureOr<NopDatabase> open(
  String path, {
  required DatabaseOnCreate onCreate,
  int version = 1,
  DatabaseUpgrade? onUpgrade,
  DatabaseUpgrade? onDowngrade,
}) {
  return NopDatabaseImpl.open(path,
      onCreate: onCreate, onUpgrade: onUpgrade, onDowngrade: onDowngrade);
}
