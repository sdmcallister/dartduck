import 'package:dartduck/dartduck.dart';

void main() {
  var db = Database(dbname: "./example/class.db");
  print(db.execute('CREATE TABLE IF NOT EXISTS myints (ints INTEGER)'));
  print(db.execute('INSERT INTO myints VALUES (42),(11)'));
  db.close();
}
