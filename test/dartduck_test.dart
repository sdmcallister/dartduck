import 'package:dartduck/dartduck.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final awesome = true;
    late Database db;
    setUp(() {
      // Additional setup goes here.
      print("setting up");
      db = Database(dbname: "./example/class.db");
    });

    test('First Test', () {
      expect(awesome, isTrue);
    });

    tearDown(() {
      print("done");
      db.close();
    });
  });
}
