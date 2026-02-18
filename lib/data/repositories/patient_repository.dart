import 'package:sqflite/sqflite.dart';
import 'dart:developer' as developer;
import '../database/database_helper.dart';
import '../models/patient.dart';
import 'package:uuid/uuid.dart';

class PatientRepository {
  static final PatientRepository _instance = PatientRepository._internal();
  factory PatientRepository() => _instance;
  PatientRepository._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  /// 验证患者数据
  void _validatePatientData({
    required String name,
    required int age,
    required String gender,
    String? phone,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('患者姓名不能为空');
    }
    if (name.trim().length > 50) {
      throw ArgumentError('患者姓名不能超过50个字符');
    }
    if (age < 0 || age > 150) {
      throw ArgumentError('年龄必须在0-150之间');
    }
    if (!['男', '女', '其他'].contains(gender)) {
      throw ArgumentError('性别必须是"男"、"女"或"其他"');
    }
    if (phone != null && phone.isNotEmpty) {
      final phoneRegExp = RegExp(r'^1[3-9]\d{9}$');
      if (!phoneRegExp.hasMatch(phone)) {
        throw ArgumentError('手机号格式不正确');
      }
    }
  }

  /// 创建新患者
  Future<Patient> createPatient({
    required String name,
    required int age,
    required String gender,
    String? phone,
    String? note,
  }) async {
    try {
      // 验证输入数据
      _validatePatientData(
        name: name,
        age: age,
        gender: gender,
        phone: phone,
      );

      final db = await _dbHelper.database;
      final now = DateTime.now();
      final patient = Patient(
        id: _uuid.v4(),
        name: name.trim(),
        age: age,
        gender: gender,
        phone: phone?.trim(),
        note: note?.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await db.insert(
        'patients',
        patient.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      developer.log('创建患者成功: ${patient.id}', name: 'PatientRepository');
      return patient;
    } on ArgumentError {
      rethrow;
    } catch (e, stackTrace) {
      developer.log('创建患者失败', error: e, stackTrace: stackTrace, name: 'PatientRepository');
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
      // 验证输入数据
      if (name != null) {
        if (name.trim().isEmpty) {
          throw ArgumentError('患者姓名不能为空');
        }
        if (name.trim().length > 50) {
          throw ArgumentError('患者姓名不能超过50个字符');
        }
      }
      if (age != null && (age < 0 || age > 150)) {
        throw ArgumentError('年龄必须在0-150之间');
      }
      if (gender != null && !['男', '女', '其他'].contains(gender)) {
        throw ArgumentError('性别必须是"男"、"女"或"其他"');
      }
      if (phone != null && phone.isNotEmpty) {
        final phoneRegExp = RegExp(r'^1[3-9]\d{9}$');
        if (!phoneRegExp.hasMatch(phone)) {
          throw ArgumentError('手机号格式不正确');
        }
      }

      final db = await _dbHelper.database;
      final existingPatient = await getPatientById(id);
      
      if (existingPatient == null) {
        throw Exception('患者不存在: $id');
      }

      final updatedPatient = Patient(
        id: id,
        name: name?.trim() ?? existingPatient.name,
        age: age ?? existingPatient.age,
        gender: gender ?? existingPatient.gender,
        phone: phone?.trim() ?? existingPatient.phone,
        note: note?.trim() ?? existingPatient.note,
        createdAt: existingPatient.createdAt,
        updatedAt: DateTime.now(),
      );

      final count = await db.update(
        'patients',
        updatedPatient.toJson(),
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('更新失败，患者可能已被删除');
      }

      developer.log('更新患者成功: $id', name: 'PatientRepository');
      return updatedPatient;
    } on ArgumentError {
      rethrow;
    } catch (e, stackTrace) {
      developer.log('更新患者失败', error: e, stackTrace: stackTrace, name: 'PatientRepository');
      throw Exception('更新患者失败: $e');
    }
  }

  /// 删除患者
  Future<void> deletePatient(String id) async {
    try {
      final db = await _dbHelper.database;
      
      // 使用事务确保数据一致性
      await db.transaction((txn) async {
        // 先删除关联的检查记录
        await txn.delete(
          'exam_records',
          where: 'patient_id = ?',
          whereArgs: [id],
        );

        // 再删除患者
        final count = await txn.delete(
          'patients',
          where: 'id = ?',
          whereArgs: [id],
        );

        if (count == 0) {
          throw Exception('患者不存在: $id');
        }
      });

      developer.log('删除患者成功: $id', name: 'PatientRepository');
    } catch (e, stackTrace) {
      developer.log('删除患者失败', error: e, stackTrace: stackTrace, name: 'PatientRepository');
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
