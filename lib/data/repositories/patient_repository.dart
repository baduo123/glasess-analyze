import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/patient.dart';
import 'package:uuid/uuid.dart';

class PatientRepository {
  static final PatientRepository _instance = PatientRepository._internal();
  factory PatientRepository() => _instance;
  PatientRepository._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  /// 创建新患者
  Future<Patient> createPatient({
    required String name,
    required int age,
    required String gender,
    String? phone,
    String? note,
  }) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final patient = Patient(
        id: _uuid.v4(),
        name: name,
        age: age,
        gender: gender,
        phone: phone,
        note: note,
        createdAt: now,
        updatedAt: now,
      );

      await db.insert(
        'patients',
        patient.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return patient;
    } catch (e) {
      throw Exception('创建患者失败: $e');
    }
  }

  /// 根据ID获取患者
  Future<Patient?> getPatientById(String id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'patients',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Patient.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('获取患者失败: $e');
    }
  }

  /// 获取所有患者
  Future<List<Patient>> getAllPatients({String? searchQuery}) async {
    try {
      final db = await _dbHelper.database;
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final maps = await db.query(
          'patients',
          where: 'name LIKE ? OR phone LIKE ?',
          whereArgs: ['%$searchQuery%', '%$searchQuery%'],
          orderBy: 'updated_at DESC',
        );
        return maps.map((map) => Patient.fromJson(map)).toList();
      }

      final maps = await db.query(
        'patients',
        orderBy: 'updated_at DESC',
      );
      return maps.map((map) => Patient.fromJson(map)).toList();
    } catch (e) {
      throw Exception('获取患者列表失败: $e');
    }
  }

  /// 更新患者信息
  Future<Patient> updatePatient(
    String id, {
    String? name,
    int? age,
    String? gender,
    String? phone,
    String? note,
  }) async {
    try {
      final db = await _dbHelper.database;
      final existingPatient = await getPatientById(id);
      
      if (existingPatient == null) {
        throw Exception('患者不存在');
      }

      final updatedPatient = Patient(
        id: id,
        name: name ?? existingPatient.name,
        age: age ?? existingPatient.age,
        gender: gender ?? existingPatient.gender,
        phone: phone ?? existingPatient.phone,
        note: note ?? existingPatient.note,
        createdAt: existingPatient.createdAt,
        updatedAt: DateTime.now(),
      );

      await db.update(
        'patients',
        updatedPatient.toJson(),
        where: 'id = ?',
        whereArgs: [id],
      );

      return updatedPatient;
    } catch (e) {
      throw Exception('更新患者失败: $e');
    }
  }

  /// 删除患者
  Future<void> deletePatient(String id) async {
    try {
      final db = await _dbHelper.database;
      
      // 先删除关联的检查记录
      await db.delete(
        'exam_records',
        where: 'patient_id = ?',
        whereArgs: [id],
      );

      // 再删除患者
      final count = await db.delete(
        'patients',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('患者不存在');
      }
    } catch (e) {
      throw Exception('删除患者失败: $e');
    }
  }

  /// 搜索患者
  Future<List<Patient>> searchPatients(String query) async {
    return getAllPatients(searchQuery: query);
  }

  /// 获取患者总数
  Future<int> getPatientCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM patients');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('获取患者数量失败: $e');
    }
  }
}
