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
  final Pointer<duckdb_connection> _conn = ffi.malloc();

  Connection(Database db) {
    if (_duckdb.duckdb_connect(db._dbptr.value, _conn) ==
        duckdb_state.DuckDBError) {
      throw DbException('could not connect');
    }
  }

  void close() {
    _duckdb.duckdb_disconnect(_conn);
    ffi.malloc.free(_conn);
  }
}

class Result {
  final Pointer<duckdb_result> _res = ffi.malloc();
  int state = duckdb_state.DuckDBSuccess;

  int get columnCount => _duckdb.duckdb_column_count(_res);
  int get rowCount => _duckdb.duckdb_row_count(_res);
  int get rowsChanged => _duckdb.duckdb_rows_changed(_res);

  List<String> columnNames() {
    List<String> result = [];
    for (var column = 0; column < columnCount; column++) {
      var colptr = _duckdb.duckdb_column_name(_res, column);
      result.add(colptr.cast<ffi.Utf8>().toDartString());
    }
    return result;
  }

  List<int> columnTypes() {
    List<int> result = [];
    for (var column = 0; column < columnCount; column++) {
      var colType = _duckdb.duckdb_column_type(_res, column);
      result.add(colType);
    }
    return result;
  }

  void destroy() {
    _duckdb.duckdb_destroy_result(_res);
    ffi.malloc.free(_res);
  }

  String? firstValue() {
    if (rowCount == 0) {
      return null;
    }
    Pointer<Char> s = ffi.malloc();
    s = _duckdb.duckdb_value_varchar(_res, 0, 0);
    var result = s.cast<ffi.Utf8>().toDartString();
    // _duckdb.duckdb_free(s.cast());
    ffi.malloc.free(s);
    return result;
  }
}

class Database {
  final Pointer<duckdb_database> _dbptr = ffi.malloc();

  Database({String dbname = ':memory:', Map<String, String>? settings}) {
    var name = dbname.toNativeUtf8().cast<Char>();
    Pointer<Pointer<Char>> errMsg = ffi.malloc();
    Pointer<duckdb_config> config = ffi.malloc();

    if (_duckdb.duckdb_create_config(config) == duckdb_state.DuckDBError) {
      throw DbException("could not create database configuration");
    }

    settings?.forEach((key, value) {
      var k = key.toNativeUtf8().cast<Char>();
      var v = value.toNativeUtf8().cast<Char>();
      if (_duckdb.duckdb_set_config(config.value, k, v) ==
          duckdb_state.DuckDBError) {
        ffi.malloc.free(k);
        ffi.malloc.free(v);
        throw DbException("config error: could not set $key for $value");
      }
      ffi.malloc.free(k);
      ffi.malloc.free(v);
    });

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

Future<Result> query(Connection conn, String query) async {
  final q = query.toNativeUtf8().cast<Char>();
  final res = Result();
  if (_duckdb.duckdb_query(conn._conn.value, q, res._res) ==
      duckdb_state.DuckDBError) {
    res.state = duckdb_state.DuckDBError;
    ffi.malloc.free(q);
  }
  ffi.malloc.free(q);
  return res;
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
