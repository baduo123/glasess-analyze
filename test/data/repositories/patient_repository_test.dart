import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vision_analyzer/data/database/database_helper.dart';
import 'package:vision_analyzer/data/models/patient.dart';
import 'package:vision_analyzer/data/repositories/patient_repository.dart';

void main() {
  group('PatientRepository', () {
    late PatientRepository patientRepository;
    late DatabaseHelper databaseHelper;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      patientRepository = PatientRepository();
      databaseHelper = DatabaseHelper.instance;
      
      // 清理数据库
      final db = await databaseHelper.database;
      await db.delete('patients');
      await db.delete('exam_records');
    });

    tearDown(() async {
      try {
        final db = await databaseHelper.database;
        await db.close();
      } catch (e) {
        // 忽略关闭错误
      }
    });

    group('createPatient', () {
      test('should create patient with valid data', () async {
        final patient = await patientRepository.createPatient(
          name: '张三',
          age: 25,
          gender: '男',
          phone: '13800138000',
          note: '测试患者',
        );

        expect(patient, isNotNull);
        expect(patient.name, equals('张三'));
        expect(patient.age, equals(25));
        expect(patient.gender, equals('男'));
        expect(patient.phone, equals('13800138000'));
        expect(patient.note, equals('测试患者'));
        expect(patient.id, isNotEmpty);
        expect(patient.createdAt, isNotNull);
        expect(patient.updatedAt, isNotNull);
      });

      test('should create patient without optional fields', () async {
        final patient = await patientRepository.createPatient(
          name: '李四',
          age: 30,
          gender: '女',
        );

        expect(patient.name, equals('李四'));
        expect(patient.phone, isNull);
        expect(patient.note, isNull);
      });

      test('should create patient with different age groups', () async {
        final child = await patientRepository.createPatient(
          name: '儿童',
          age: 5,
          gender: '男',
        );

        final adult = await patientRepository.createPatient(
          name: '成人',
          age: 35,
          gender: '女',
        );

        final elderly = await patientRepository.createPatient(
          name: '老人',
          age: 80,
          gender: '男',
        );

        expect(child.age, equals(5));
        expect(adult.age, equals(35));
        expect(elderly.age, equals(80));
      });

      test('should assign unique IDs to different patients', () async {
        final patient1 = await patientRepository.createPatient(
          name: '患者1',
          age: 20,
          gender: '男',
        );

        final patient2 = await patientRepository.createPatient(
          name: '患者2',
          age: 25,
          gender: '女',
        );

        expect(patient1.id, isNot(equals(patient2.id)));
      });

      test('should set createdAt and updatedAt to current time', () async {
        final beforeCreate = DateTime.now();
        
        final patient = await patientRepository.createPatient(
          name: '时间测试',
          age: 30,
          gender: '男',
        );
        
        final afterCreate = DateTime.now();

        expect(patient.createdAt.isAfter(beforeCreate) || patient.createdAt.isAtSameMomentAs(beforeCreate), isTrue);
        expect(patient.createdAt.isBefore(afterCreate) || patient.createdAt.isAtSameMomentAs(afterCreate), isTrue);
        expect(patient.updatedAt, equals(patient.createdAt));
      });
    });

    group('getAllPatients', () {
      test('should return empty list when no patients exist', () async {
        final patients = await patientRepository.getAllPatients();

        expect(patients, isEmpty);
      });

      test('should return all patients ordered by updated_at DESC', () async {
        await patientRepository.createPatient(
          name: '患者A',
          age: 20,
          gender: '男',
        );

        await Future.delayed(const Duration(milliseconds: 100));

        await patientRepository.createPatient(
          name: '患者B',
          age: 25,
          gender: '女',
        );

        await Future.delayed(const Duration(milliseconds: 100));

        await patientRepository.createPatient(
          name: '患者C',
          age: 30,
          gender: '男',
        );

        final patients = await patientRepository.getAllPatients();

        expect(patients.length, equals(3));
        expect(patients[0].name, equals('患者C'));
        expect(patients[1].name, equals('患者B'));
        expect(patients[2].name, equals('患者A'));
      });

      test('should search patients by name', () async {
        await patientRepository.createPatient(
          name: '张三',
          age: 25,
          gender: '男',
          phone: '13800138000',
        );

        await patientRepository.createPatient(
          name: '张三丰',
          age: 60,
          gender: '男',
          phone: '13900139000',
        );

        await patientRepository.createPatient(
          name: '李四',
          age: 30,
          gender: '女',
          phone: '13700137000',
        );

        final results = await patientRepository.getAllPatients(searchQuery: '张三');

        expect(results.length, equals(2));
        expect(results.any((p) => p.name == '张三'), isTrue);
        expect(results.any((p) => p.name == '张三丰'), isTrue);
        expect(results.any((p) => p.name == '李四'), isFalse);
      });

      test('should search patients by phone', () async {
        await patientRepository.createPatient(
          name: '张三',
          age: 25,
          gender: '男',
          phone: '13800138000',
        );

        await patientRepository.createPatient(
          name: '李四',
          age: 30,
          gender: '女',
          phone: '13900139000',
        );

        final results = await patientRepository.getAllPatients(searchQuery: '13800');

        expect(results.length, equals(1));
        expect(results.first.name, equals('张三'));
      });

      test('should return empty list when search query matches nothing', () async {
        await patientRepository.createPatient(
          name: '张三',
          age: 25,
          gender: '男',
        );

        final results = await patientRepository.getAllPatients(searchQuery: '王五');

        expect(results, isEmpty);
      });

      test('should handle case insensitive search', () async {
        await patientRepository.createPatient(
          name: 'ABC患者',
          age: 25,
          gender: '男',
        );

        final results = await patientRepository.getAllPatients(searchQuery: 'abc');

        expect(results.length, equals(1));
      });

      test('should handle empty search query', () async {
        await patientRepository.createPatient(
          name: '张三',
          age: 25,
          gender: '男',
        );

        final results = await patientRepository.getAllPatients(searchQuery: '');

        expect(results.length, equals(1));
      });
    });

    group('getPatientById', () {
      test('should return patient by id', () async {
        final created = await patientRepository.createPatient(
          name: '张三',
          age: 25,
          gender: '男',
          phone: '13800138000',
        );

        final patient = await patientRepository.getPatientById(created.id);

        expect(patient, isNotNull);
        expect(patient!.name, equals('张三'));
        expect(patient.age, equals(25));
      });

      test('should return null for non-existent id', () async {
        final patient = await patientRepository.getPatientById('non-existent-id');

        expect(patient, isNull);
      });
    });

    group('updatePatient', () {
      test('should update patient name', () async {
        final created = await patientRepository.createPatient(
          name: '张三',
          age: 25,
          gender: '男',
        );

        final updated = await patientRepository.updatePatient(
          created.id,
          name: '张三(已更新)',
        );

        expect(updated.name, equals('张三(已更新)'));
        expect(updated.age, equals(25));
        expect(updated.updatedAt.isAfter(created.updatedAt), isTrue);
      });

      test('should update patient age', () async {
        final created = await patientRepository.createPatient(
          name: '张三',
          age: 25,
          gender: '男',
        );

        final updated = await patientRepository.updatePatient(
          created.id,
          age: 30,
        );

        expect(updated.age, equals(30));
        expect(updated.name, equals('张三'));
      });

      test('should update multiple fields', () async {
        final created = await patientRepository.createPatient(
          name: '张三',
          age: 25,
          gender: '男',
          phone: '13800138000',
        );

        final updated = await patientRepository.updatePatient(
          created.id,
          name: '张三丰',
          age: 60,
          phone: '13900139000',
        );

        expect(updated.name, equals('张三丰'));
        expect(updated.age, equals(60));
        expect(updated.phone, equals('13900139000'));
        expect(updated.gender, equals('男'));
      });

      test('should throw exception when patient does not exist', () async {
        expect(
          () => patientRepository.updatePatient(
            'non-existent-id',
            name: '新名字',
          ),
          throwsException,
        );
      });

      test('should preserve unchanged fields', () async {
        final created = await patientRepository.createPatient(
          name: '张三',
          age: 25,
          gender: '男',
          note: '测试备注',
        );

        final updated = await patientRepository.updatePatient(
          created.id,
          age: 30,
        );

        expect(updated.name, equals('张三'));
        expect(updated.gender, equals('男'));
        expect(updated.note, equals('测试备注'));
      });
    });

    group('deletePatient', () {
      test('should delete patient by id', () async {
        final created = await patientRepository.createPatient(
          name: '张三',
          age: 25,
          gender: '男',
        );

        await patientRepository.deletePatient(created.id);

        final patient = await patientRepository.getPatientById(created.id);
        expect(patient, isNull);
      });

      test('should throw exception when patient does not exist', () async {
        expect(
          () => patientRepository.deletePatient('non-existent-id'),
          throwsException,
        );
      });

      test('should delete associated exam records', () async {
        // 创建患者
        final patient = await patientRepository.createPatient(
          name: '张三',
          age: 25,
          gender: '男',
        );

        // 创建关联的检查记录
        final db = await databaseHelper.database;
        await db.insert('exam_records', {
          'id': 'exam-001',
          'patient_id': patient.id,
          'exam_type': 'standardFullSet',
          'exam_date': DateTime.now().millisecondsSinceEpoch,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'is_draft': 0,
        });

        // 删除患者
        await patientRepository.deletePatient(patient.id);

        // 验证检查记录也被删除
        final exams = await db.query(
          'exam_records',
          where: 'patient_id = ?',
          whereArgs: [patient.id],
        );
        expect(exams, isEmpty);
      });

      test('should decrease patient count after deletion', () async {
        final patient1 = await patientRepository.createPatient(
          name: '患者1',
          age: 20,
          gender: '男',
        );

        await patientRepository.createPatient(
          name: '患者2',
          age: 25,
          gender: '女',
        );

        final countBefore = await patientRepository.getPatientCount();
        expect(countBefore, equals(2));

        await patientRepository.deletePatient(patient1.id);

        final countAfter = await patientRepository.getPatientCount();
        expect(countAfter, equals(1));
      });
    });

    group('searchPatients', () {
      test('should search by name using alias method', () async {
        await patientRepository.createPatient(
          name: '张三',
          age: 25,
          gender: '男',
        );

        await patientRepository.createPatient(
          name: '李四',
          age: 30,
          gender: '女',
        );

        final results = await patientRepository.searchPatients('张三');

        expect(results.length, equals(1));
        expect(results.first.name, equals('张三'));
      });
    });

    group('getPatientCount', () {
      test('should return 0 when no patients', () async {
        final count = await patientRepository.getPatientCount();
        expect(count, equals(0));
      });

      test('should return correct count', () async {
        await patientRepository.createPatient(
          name: '患者1',
          age: 20,
          gender: '男',
        );

        await patientRepository.createPatient(
          name: '患者2',
          age: 25,
          gender: '女',
        );

        await patientRepository.createPatient(
          name: '患者3',
          age: 30,
          gender: '男',
        );

        final count = await patientRepository.getPatientCount();
        expect(count, equals(3));
      });
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = PatientRepository();
        final instance2 = PatientRepository();

        expect(identical(instance1, instance2), isTrue);
      });
    });
  });
}
