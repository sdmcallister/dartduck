import 'package:dartduck/dartduck.dart';

void main() {
  // var db = Database(dbname: "./example/class.db");
  var db = Database();

  // db.execute('CREATE TABLE IF NOT EXISTS myints (ints INTEGER)');
  // db.execute('INSERT INTO myints VALUES (42),(11)');
  db.close();
}
