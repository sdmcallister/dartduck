import 'dart:io';
import 'package:path/path.dart' as path;
import 'duckdb_bindings.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart' as ffi;

final _duckdb = DuckDB(DynamicLibrary.open(_getLibraryPath()));

class DbException implements Exception {
  String message = 'unknown database error';

  DbException(this.message);

  @override
  String toString() {
    return message;
  }
}

class Connection {
  final Database _db;
  final Pointer<duckdb_connection> _conn = ffi.malloc();
  final Pointer<duckdb_result> _res = ffi.malloc();

  Connection(this._db);

  void execute(String query) {
    if (_duckdb.duckdb_connect(_db._dbptr.value, _conn) ==
        duckdb_state.DuckDBError) {
      throw DbException('could not connect');
    }
    final q = query.toNativeUtf8().cast<Char>();
    if (_duckdb.duckdb_query(_conn.value, q, _res) ==
        duckdb_state.DuckDBError) {
      _duckdb.duckdb_destroy_result(_res);
      _duckdb.duckdb_disconnect(_conn);
    }
    _duckdb.duckdb_destroy_result(_res);
    _duckdb.duckdb_disconnect(_conn);
  }
}

class Database {
  final Pointer<duckdb_database> _dbptr = ffi.malloc();

  Database({String dbname = ':memory:'}) {
    var name = dbname.toNativeUtf8().cast<Char>();
    Pointer<Pointer<Char>> errMsg = ffi.malloc();
    Pointer<duckdb_config> config = ffi.malloc();

    if (_duckdb.duckdb_create_config(config) == duckdb_state.DuckDBError) {
      throw DbException("could not create database configuration");
    }

    if (_duckdb.duckdb_open_ext(name, _dbptr, config.value, errMsg) ==
        duckdb_state.DuckDBError) {
      var msg = errMsg.value.cast<ffi.Utf8>().toDartString();
      ffi.malloc.free(name);
      ffi.malloc.free(errMsg);
      _duckdb.duckdb_destroy_config(config);
      throw DbException(msg);
    }
    _duckdb.duckdb_destroy_config(config);
    ffi.malloc.free(config);
    ffi.malloc.free(errMsg);
    ffi.malloc.free(name);
  }

  void close() {
    _duckdb.duckdb_close(_dbptr);
    ffi.malloc.free(_dbptr);
  }
}

String _getLibraryPath() {
  var libraryPath = path.join(Directory.current.path, 'headers', 'duckdb.so');
  if (Platform.isMacOS) {
    libraryPath = path.join(Directory.current.path, 'headers', 'duckdb.dylib');
  } else if (Platform.isWindows) {
    libraryPath = path.join(Directory.current.path, 'headers', 'duckdb.dll');
  }
  return libraryPath;
}
