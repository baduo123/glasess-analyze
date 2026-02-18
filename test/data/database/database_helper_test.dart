import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vision_analyzer/data/database/database_helper.dart';

void main() {
  group('DatabaseHelper', () {
    late DatabaseHelper databaseHelper;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      databaseHelper = DatabaseHelper.instance;
    });

    tearDown(() async {
      try {
        final db = await databaseHelper.database;
        await db.close();
      } catch (e) {
        // 忽略关闭错误
      }
    });

    group('Initialization', () {
      test('should create singleton instance', () {
        final instance1 = DatabaseHelper.instance;
        final instance2 = DatabaseHelper.instance;

        expect(identical(instance1, instance2), isTrue);
      });

      test('should initialize database successfully', () async {
        final db = await databaseHelper.database;

        expect(db, isNotNull);
        expect(db.isOpen, isTrue);
      });

      test('should return same database instance on multiple calls', () async {
        final db1 = await databaseHelper.database;
        final db2 = await databaseHelper.database;

        expect(identical(db1, db2), isTrue);
      });
    });

    group('Table Creation', () {
      test('should create patients table', () async {
        final db = await databaseHelper.database;

        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='patients'",
        );

        expect(result, isNotEmpty);
        expect(result.first['name'], equals('patients'));
      });

      test('should create exam_records table', () async {
        final db = await databaseHelper.database;

        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='exam_records'",
        );

        expect(result, isNotEmpty);
        expect(result.first['name'], equals('exam_records'));
      });

      test('should create patients table with correct columns', () async {
        final db = await databaseHelper.database;

        final columns = await db.rawQuery('PRAGMA table_info(patients)');
        final columnNames = columns.map((c) => c['name'] as String).toList();

        expect(columnNames, contains('id'));
        expect(columnNames, contains('name'));
        expect(columnNames, contains('age'));
        expect(columnNames, contains('gender'));
        expect(columnNames, contains('phone'));
        expect(columnNames, contains('note'));
        expect(columnNames, contains('created_at'));
        expect(columnNames, contains('updated_at'));
      });

      test('should create exam_records table with correct columns', () async {
        final db = await databaseHelper.database;

        final columns = await db.rawQuery('PRAGMA table_info(exam_records)');
        final columnNames = columns.map((c) => c['name'] as String).toList();

        expect(columnNames, contains('id'));
        expect(columnNames, contains('patient_id'));
        expect(columnNames, contains('exam_type'));
        expect(columnNames, contains('exam_date'));
        expect(columnNames, contains('created_at'));
        expect(columnNames, contains('is_draft'));
        expect(columnNames, contains('pdf_path'));
        expect(columnNames, contains('indicator_values'));
      });

      test('should set id as primary key in patients table', () async {
        final db = await databaseHelper.database;

        final columns = await db.rawQuery('PRAGMA table_info(patients)');
        final idColumn = columns.firstWhere((c) => c['name'] == 'id');

        expect(idColumn['pk'], equals(1));
      });

      test('should set id as primary key in exam_records table', () async {
        final db = await databaseHelper.database;

        final columns = await db.rawQuery('PRAGMA table_info(exam_records)');
        final idColumn = columns.firstWhere((c) => c['name'] == 'id');

        expect(idColumn['pk'], equals(1));
      });
    });

    group('Patients Table CRUD', () {
      test('should insert a patient', () async {
        final db = await databaseHelper.database;

        final patientData = {
          'id': 'patient-001',
          'name': '张三',
          'age': 25,
          'gender': '男',
          'phone': '13800138000',
          'note': '测试患者',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        };

        final id = await db.insert('patients', patientData);

        expect(id, isNotNull);
      });

      test('should read a patient by id', () async {
        final db = await databaseHelper.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        final patientData = {
          'id': 'patient-002',
          'name': '李四',
          'age': 30,
          'gender': '女',
          'phone': '13900139000',
          'note': null,
          'created_at': now,
          'updated_at': now,
        };

        await db.insert('patients', patientData);

        final result = await db.query(
          'patients',
          where: 'id = ?',
          whereArgs: ['patient-002'],
        );

        expect(result, isNotEmpty);
        expect(result.first['name'], equals('李四'));
        expect(result.first['age'], equals(30));
      });

      test('should update a patient', () async {
        final db = await databaseHelper.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        await db.insert('patients', {
          'id': 'patient-003',
          'name': '王五',
          'age': 35,
          'gender': '男',
          'phone': '13700137000',
          'note': null,
          'created_at': now,
          'updated_at': now,
        });

        final updated = await db.update(
          'patients',
          {
            'name': '王五(已更新)',
            'age': 36,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: ['patient-003'],
        );

        expect(updated, equals(1));

        final result = await db.query(
          'patients',
          where: 'id = ?',
          whereArgs: ['patient-003'],
        );

        expect(result.first['name'], equals('王五(已更新)'));
        expect(result.first['age'], equals(36));
      });

      test('should delete a patient', () async {
        final db = await databaseHelper.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        await db.insert('patients', {
          'id': 'patient-004',
          'name': '赵六',
          'age': 28,
          'gender': '女',
          'created_at': now,
          'updated_at': now,
        });

        final deleted = await db.delete(
          'patients',
          where: 'id = ?',
          whereArgs: ['patient-004'],
        );

        expect(deleted, equals(1));

        final result = await db.query(
          'patients',
          where: 'id = ?',
          whereArgs: ['patient-004'],
        );

        expect(result, isEmpty);
      });

      test('should query all patients', () async {
        final db = await databaseHelper.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        await db.insert('patients', {
          'id': 'patient-005',
          'name': '患者A',
          'age': 20,
          'gender': '男',
          'created_at': now,
          'updated_at': now,
        });

        await db.insert('patients', {
          'id': 'patient-006',
          'name': '患者B',
          'age': 25,
          'gender': '女',
          'created_at': now,
          'updated_at': now,
        });

        final results = await db.query('patients');

        expect(results.length, greaterThanOrEqualTo(2));
      });

      test('should handle null values in patient data', () async {
        final db = await databaseHelper.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        final patientData = {
          'id': 'patient-007',
          'name': '测试患者',
          'age': 40,
          'gender': '男',
          'phone': null,
          'note': null,
          'created_at': now,
          'updated_at': now,
        };

        await db.insert('patients', patientData);

        final result = await db.query(
          'patients',
          where: 'id = ?',
          whereArgs: ['patient-007'],
        );

        expect(result.first['phone'], isNull);
        expect(result.first['note'], isNull);
      });
    });

    group('Exam Records Table CRUD', () {
      test('should insert an exam record', () async {
        final db = await databaseHelper.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        final examData = {
          'id': 'exam-001',
          'patient_id': 'patient-001',
          'exam_type': 'standardFullSet',
          'exam_date': now,
          'created_at': now,
          'is_draft': 0,
          'pdf_path': '/path/to/pdf',
          'indicator_values': '{"va": 1.0}',
        };

        final id = await db.insert('exam_records', examData);

        expect(id, isNotNull);
      });

      test('should read an exam record by id', () async {
        final db = await databaseHelper.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        await db.insert('exam_records', {
          'id': 'exam-002',
          'patient_id': 'patient-001',
          'exam_type': 'binocularVision',
          'exam_date': now,
          'created_at': now,
          'is_draft': 1,
          'pdf_path': null,
          'indicator_values': null,
        });

        final result = await db.query(
          'exam_records',
          where: 'id = ?',
          whereArgs: ['exam-002'],
        );

        expect(result, isNotEmpty);
        expect(result.first['exam_type'], equals('binocularVision'));
        expect(result.first['is_draft'], equals(1));
      });

      test('should update an exam record', () async {
        final db = await databaseHelper.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        await db.insert('exam_records', {
          'id': 'exam-003',
          'patient_id': 'patient-001',
          'exam_type': 'standardFullSet',
          'exam_date': now,
          'created_at': now,
          'is_draft': 1,
        });

        final updated = await db.update(
          'exam_records',
          {
            'is_draft': 0,
            'pdf_path': '/new/path/to/pdf',
          },
          where: 'id = ?',
          whereArgs: ['exam-003'],
        );

        expect(updated, equals(1));

        final result = await db.query(
          'exam_records',
          where: 'id = ?',
          whereArgs: ['exam-003'],
        );

        expect(result.first['is_draft'], equals(0));
        expect(result.first['pdf_path'], equals('/new/path/to/pdf'));
      });

      test('should delete an exam record', () async {
        final db = await databaseHelper.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        await db.insert('exam_records', {
          'id': 'exam-004',
          'exam_type': 'custom',
          'exam_date': now,
          'created_at': now,
          'is_draft': 0,
        });

        final deleted = await db.delete(
          'exam_records',
          where: 'id = ?',
          whereArgs: ['exam-004'],
        );

        expect(deleted, equals(1));

        final result = await db.query(
          'exam_records',
          where: 'id = ?',
          whereArgs: ['exam-004'],
        );

        expect(result, isEmpty);
      });

      test('should query exam records by patient_id', () async {
        final db = await databaseHelper.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        await db.insert('exam_records', {
          'id': 'exam-005',
          'patient_id': 'patient-test',
          'exam_type': 'standardFullSet',
          'exam_date': now,
          'created_at': now,
          'is_draft': 0,
        });

        await db.insert('exam_records', {
          'id': 'exam-006',
          'patient_id': 'patient-test',
          'exam_type': 'standardFullSet',
          'exam_date': now,
          'created_at': now,
          'is_draft': 0,
        });

        final results = await db.query(
          'exam_records',
          where: 'patient_id = ?',
          whereArgs: ['patient-test'],
        );

        expect(results.length, equals(2));
      });

      test('should query draft exam records', () async {
        final db = await databaseHelper.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        await db.insert('exam_records', {
          'id': 'exam-007',
          'exam_type': 'standardFullSet',
          'exam_date': now,
          'created_at': now,
          'is_draft': 1,
        });

        await db.insert('exam_records', {
          'id': 'exam-008',
          'exam_type': 'binocularVision',
          'exam_date': now,
          'created_at': now,
          'is_draft': 0,
        });

        final drafts = await db.query(
          'exam_records',
          where: 'is_draft = ?',
          whereArgs: [1],
        );

        expect(drafts.any((r) => r['id'] == 'exam-007'), isTrue);
        expect(drafts.any((r) => r['id'] == 'exam-008'), isFalse);
      });
    });

    group('Database Operations', () {
      test('should handle multiple transactions', () async {
        final db = await databaseHelper.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        await db.transaction((txn) async {
          await txn.insert('patients', {
            'id': 'txn-patient-001',
            'name': '事务患者',
            'age': 30,
            'gender': '男',
            'created_at': now,
            'updated_at': now,
          });

          await txn.insert('exam_records', {
            'id': 'txn-exam-001',
            'patient_id': 'txn-patient-001',
            'exam_type': 'standardFullSet',
            'exam_date': now,
            'created_at': now,
            'is_draft': 0,
          });
        });

        final patientResult = await db.query(
          'patients',
          where: 'id = ?',
          whereArgs: ['txn-patient-001'],
        );

        final examResult = await db.query(
          'exam_records',
          where: 'id = ?',
          whereArgs: ['txn-exam-001'],
        );

        expect(patientResult, isNotEmpty);
        expect(examResult, isNotEmpty);
      });

      test('should handle batch operations', () async {
        final db = await databaseHelper.database;
        final now = DateTime.now().millisecondsSinceEpoch;

        final batch = db.batch();

        for (int i = 0; i < 5; i++) {
          batch.insert('patients', {
            'id': 'batch-patient-$i',
            'name': '批量患者$i',
            'age': 20 + i,
            'gender': i % 2 == 0 ? '男' : '女',
            'created_at': now,
            'updated_at': now,
          });
        }

        final results = await batch.commit();

        expect(results.length, equals(5));
      });
    });

    group('Database Connection', () {
      test('should close database connection', () async {
        final db = await databaseHelper.database;
        expect(db.isOpen, isTrue);

        await databaseHelper.close();

        expect(db.isOpen, isFalse);
      });
    });
  });
}
