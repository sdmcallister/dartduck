import 'package:dartduck/dartduck.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    late Database db;
    setUp(() {
      // Additional setup goes here.
      print("opening db");
      db = Database(
          dbname: "./test/test.db", settings: {"access_mode": "READ_WRITE"});
    });

    test('create myints table', () async {
      var conn = Connection(db);
      var res = await query(
          conn, "CREATE TABLE IF NOT EXISTS test(ints INTEGER, strs TEXT)");
      res.destroy();
      conn.close();
      return true;
    });

    test('clear table myints', () async {
      var conn = Connection(db);
      var res = await query(conn, "DELETE FROM test");
      res.destroy();
      conn.close();
      return true;
    });

    test('insert data', () async {
      var conn = Connection(db);
      var res =
          await query(conn, "INSERT INTO test VALUES (42,'foo'),(null,'bar')");
      res.destroy();
      conn.close();
      return true;
    });

    test('row and column counts', () async {
      var conn = Connection(db);
      late Result res;
      res = await query(conn, "SELECT * FROM test");
      expect(res.columnCount, equals(2));
      expect(res.rowCount, equals(2));
      res.destroy();
      conn.close();

      return true;
    });
    test('list colnames', () async {
      var conn = Connection(db);
      var res = await query(conn, "SELECT *, 42 as test FROM test");
      print(res.columnNames());
      res.destroy();
      conn.close();

      return true;
    });

    test('list coltypes', () async {
      var conn = Connection(db);
      var res = await query(conn, "SELECT *, 42 as test FROM test");
      print(res.columnTypes());
      res.destroy();
      conn.close();

      return true;
    });

    tearDown(() {
      print("tearing down");
      db.close();
    });
  });
}
