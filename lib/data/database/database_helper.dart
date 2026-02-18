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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 版本2：添加索引
      await _createIndexes(db);
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const integerType = 'INTEGER';

    // 创建患者表
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

    // 创建检查记录表
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

    // 创建索引以优化查询性能
    await _createIndexes(db);
  }

  Future _createIndexes(Database db) async {
    // 患者表索引
    await db.execute('CREATE INDEX idx_patients_name ON patients(name)');
    await db.execute('CREATE INDEX idx_patients_phone ON patients(phone)');
    await db.execute('CREATE INDEX idx_patients_updated_at ON patients(updated_at DESC)');

    // 检查记录表索引
    await db.execute('CREATE INDEX idx_exam_records_patient_id ON exam_records(patient_id)');
    await db.execute('CREATE INDEX idx_exam_records_exam_date ON exam_records(exam_date DESC)');
    await db.execute('CREATE INDEX idx_exam_records_is_draft ON exam_records(is_draft)');
    await db.execute('CREATE INDEX idx_exam_records_patient_date ON exam_records(patient_id, exam_date DESC)');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
