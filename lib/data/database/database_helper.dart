import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vision_analyzer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const integerType = 'INTEGER';

    await db.execute('''
      CREATE TABLE patients (
        id $idType,
        name $textType NOT NULL,
        age $integerType,
        gender $textType,
        phone $textType,
        note $textType,
        created_at $integerType NOT NULL,
        updated_at $integerType NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exam_records (
        id $idType,
        patient_id $textType,
        exam_type $textType NOT NULL,
        exam_date $integerType NOT NULL,
        created_at $integerType NOT NULL,
        is_draft $integerType DEFAULT 0,
        pdf_path $textType,
        indicator_values $textType,
        FOREIGN KEY (patient_id) REFERENCES patients(id)
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
