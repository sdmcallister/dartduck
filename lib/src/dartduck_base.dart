import 'dart:io';
import 'package:path/path.dart' as path;
import 'duckdb_bindings.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart' as ffi;

class DbException implements Exception {
  String message = 'unknown database error';

  DbException(this.message);
}

class Database {
  final Pointer<duckdb_database> _dbptr = ffi.malloc();
  final _duckdb = DuckDB(DynamicLibrary.open(getLibraryPath()));

  Database({String dbname = ':memory:'}) {
    var name = dbname.toNativeUtf8().cast<Char>();
    if (_duckdb.duckdb_open(name, _dbptr) == duckdb_state.DuckDBError) {
      ffi.malloc.free(name);
      throw DbException("could not open database");
    }
    ffi.malloc.free(name);
  }

  void close() {
    _duckdb.duckdb_close(_dbptr);
    ffi.malloc.free(_dbptr);
  }

  int execute(String query) {
    var result = duckdb_state.DuckDBSuccess;
    ffi.using((ffi.Arena arena) {
      final conn = arena<duckdb_connection>();
      if (_duckdb.duckdb_connect(_dbptr.value, conn) ==
          duckdb_state.DuckDBError) {
        result = duckdb_state.DuckDBError;
      }
      final q = query.toNativeUtf8(allocator: arena).cast<Char>();
      if (_duckdb.duckdb_query(conn.value, q, nullptr) ==
          duckdb_state.DuckDBError) {
        _duckdb.duckdb_disconnect(conn);
        result = duckdb_state.DuckDBError;
      }
      _duckdb.duckdb_disconnect(conn);
    });
    return result;
  }
}

String getLibraryPath() {
  var libraryPath = path.join(Directory.current.path, 'headers', 'duckdb.so');
  if (Platform.isMacOS) {
    libraryPath = path.join(Directory.current.path, 'headers', 'duckdb.dylib');
  } else if (Platform.isWindows) {
    libraryPath = path.join(Directory.current.path, 'headers', 'duckdb.dll');
  }
  return libraryPath;
}
