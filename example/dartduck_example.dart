import 'package:dartduck/dartduck.dart';
import 'dart:ffi';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:ffi/ffi.dart' as ffi;

void main() {
  var libraryPath = path.join(Directory.current.path, 'headers', 'duckdb.so');
  if (Platform.isMacOS) {
    libraryPath = path.join(Directory.current.path, 'headers', 'duckdb.dylib');
  } else if (Platform.isWindows) {
    libraryPath = path.join(Directory.current.path, 'headers', 'duckdb.dll');
  }
  final duckdb = DuckDB(DynamicLibrary.open(libraryPath));

  Pointer<Char> dbname = './example/test.db'.toNativeUtf8().cast<Char>();
  ffi.using((ffi.Arena arena) {
    final db = arena<duckdb_database>();
    final conn = arena<duckdb_connection>();
    final res = arena<duckdb_result>();

    duckdb.duckdb_open(dbname, db);
    duckdb.duckdb_connect(db.value, conn);

    duckdb.duckdb_query(
        conn.value,
        "CREATE TABLE IF NOT EXISTS integers(i INTEGER);"
            .toNativeUtf8()
            .cast<Char>(),
        nullptr);

    duckdb.duckdb_query(
        conn.value,
        "INSERT INTO integers(i) VALUES (42);".toNativeUtf8().cast<Char>(),
        nullptr);

    duckdb.duckdb_query(
        conn.value, "SELECT i FROM integers;".toNativeUtf8().cast<Char>(), res);

    final x = duckdb.duckdb_value_int32(res, 0, 0);
    print("I found the value $x");

    duckdb.duckdb_destroy_result(res);
    duckdb.duckdb_disconnect(conn);
    duckdb.duckdb_close(db);
  });
  var awesome = Awesome();
  print('awesome: ${awesome.isAwesome}');
}
