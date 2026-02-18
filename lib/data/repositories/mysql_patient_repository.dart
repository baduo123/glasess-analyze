import 'dart:developer' as developer;
import 'package:mysql1/mysql1.dart';
import '../database/mysql_database_helper.dart';
import '../models/patient.dart';
import 'package:uuid/uuid.dart';

/// MySQL患者数据仓储类
/// 实现与SQLite版本相同的接口，支持多租户
class MySqlPatientRepository {
  static MySqlPatientRepository? _instance;
  
  factory MySqlPatientRepository() {
    _instance ??= MySqlPatientRepository._internal();
    return _instance!;
  }
  
  MySqlPatientRepository._internal();

  final MySqlDatabaseHelper _dbHelper = MySqlDatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  /// 获取当前租户ID
  int? get _tenantId => _dbHelper.currentTenantId;

  /// 构建带租户过滤的WHERE子句
  String _buildTenantWhere(String baseWhere) {
    if (_tenantId != null) {
      if (baseWhere.isEmpty) {
        return 'WHERE tenant_id = ?';
      } else {
        return '$baseWhere AND tenant_id = ?';
      }
    }
    return baseWhere.isEmpty ? '' : baseWhere;
  }

  /// 构建查询参数列表
  List<dynamic> _buildTenantParams(List<dynamic> baseParams) {
    if (_tenantId != null) {
      return [...baseParams, _tenantId];
    }
    return baseParams;
  }

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

  /// 将MySQL结果行转换为Patient对象
  Patient _rowToPatient(Map<String, dynamic> row) {
    return Patient(
      id: row['id'].toString(),
      name: row['name'].toString(),
      age: row['age'] as int,
      gender: row['gender'].toString(),
      phone: row['phone']?.toString(),
      note: row['note']?.toString(),
      createdAt: row['created_at'] is DateTime 
          ? row['created_at'] as DateTime
          : MySqlDateTimeConverter.fromMySqlDateTime(row['created_at'].toString()),
      updatedAt: row['updated_at'] is DateTime 
          ? row['updated_at'] as DateTime
          : MySqlDateTimeConverter.fromMySqlDateTime(row['updated_at'].toString()),
    );
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

      final sql = '''
        INSERT INTO patients 
        (id, name, age, gender, phone, note, created_at, updated_at, tenant_id) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''';

      final params = [
        patient.id,
        patient.name,
        patient.age,
        patient.gender,
        patient.phone,
        patient.note,
        MySqlDateTimeConverter.toMySqlDateTime(patient.createdAt),
        MySqlDateTimeConverter.toMySqlDateTime(patient.updatedAt),
        _tenantId,
      ];

      await _dbHelper.insert(sql, params);

      developer.log('创建患者成功: ${patient.id}', name: 'MySqlPatientRepository');
      return patient;
    } on ArgumentError {
      rethrow;
    } catch (e, stackTrace) {
      developer.log('创建患者失败', error: e, stackTrace: stackTrace, name: 'MySqlPatientRepository');
      throw Exception('创建患者失败: $e');
    }
  }

  /// 根据ID获取患者
  Future<Patient?> getPatientById(String id) async {
    try {
      var whereClause = 'WHERE id = ?';
      whereClause = _buildTenantWhere(whereClause);
      
      final sql = 'SELECT * FROM patients $whereClause LIMIT 1';
      final params = _buildTenantParams([id]);

      final results = await _dbHelper.query(sql, params);

      if (results.isNotEmpty) {
        final row = results.first.fields;
        return _rowToPatient(row);
      }
      return null;
    } catch (e, stackTrace) {
      developer.log('获取患者失败: $id', error: e, stackTrace: stackTrace, name: 'MySqlPatientRepository');
      throw Exception('获取患者失败: $e');
    }
  }

  /// 获取所有患者
  Future<List<Patient>> getAllPatients({String? searchQuery}) async {
    try {
      String whereClause = '';
      List<dynamic> params = [];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereClause = 'WHERE (name LIKE ? OR phone LIKE ?)';
        params = ['%$searchQuery%', '%$searchQuery%'];
      }

      whereClause = _buildTenantWhere(whereClause);
      params = _buildTenantParams(params);

      final sql = 'SELECT * FROM patients $whereClause ORDER BY updated_at DESC';
      final results = await _dbHelper.query(sql, params);

      return results.map((row) => _rowToPatient(row.fields)).toList();
    } catch (e, stackTrace) {
      developer.log('获取患者列表失败', error: e, stackTrace: stackTrace, name: 'MySqlPatientRepository');
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

      final sql = '''
        UPDATE patients 
        SET name = ?, age = ?, gender = ?, phone = ?, note = ?, updated_at = ?
        WHERE id = ?
      ''';

      var params = [
        updatedPatient.name,
        updatedPatient.age,
        updatedPatient.gender,
        updatedPatient.phone,
        updatedPatient.note,
        MySqlDateTimeConverter.toMySqlDateTime(updatedPatient.updatedAt),
        id,
      ];

      // 如果有租户ID，添加租户过滤
      if (_tenantId != null) {
        params.add(_tenantId);
      }

      final whereClause = _tenantId != null ? ' AND tenant_id = ?' : '';
      final finalSql = sql + whereClause;

      final affectedRows = await _dbHelper.execute(finalSql, params);

      if (affectedRows == 0) {
        throw Exception('更新失败，患者可能已被删除或无权限');
      }

      developer.log('更新患者成功: $id', name: 'MySqlPatientRepository');
      return updatedPatient;
    } on ArgumentError {
      rethrow;
    } catch (e, stackTrace) {
      developer.log('更新患者失败', error: e, stackTrace: stackTrace, name: 'MySqlPatientRepository');
      throw Exception('更新患者失败: $e');
    }
  }

  /// 删除患者（使用事务）
  Future<void> deletePatient(String id) async {
    try {
      await _dbHelper.transaction((conn) async {
        // 先检查患者是否存在且有权限
        var checkWhere = 'WHERE id = ?';
        checkWhere = _buildTenantWhere(checkWhere);
        
        final checkSql = 'SELECT id FROM patients $checkWhere LIMIT 1';
        final checkParams = _buildTenantParams([id]);
        
        final checkResult = await conn.query(checkSql, checkParams);
        if (checkResult.isEmpty) {
          throw Exception('患者不存在或无权限: $id');
        }

        // 删除关联的检查记录
        var examWhere = 'WHERE patient_id = ?';
        examWhere = _buildTenantWhere(examWhere);
        
        final deleteExamsSql = 'DELETE FROM exam_records $examWhere';
        final deleteExamsParams = _buildTenantParams([id]);
        await conn.query(deleteExamsSql, deleteExamsParams);

        // 删除患者
        var patientWhere = 'WHERE id = ?';
        patientWhere = _buildTenantWhere(patientWhere);
        
        final deletePatientSql = 'DELETE FROM patients $patientWhere';
        final deletePatientParams = _buildTenantParams([id]);
        final result = await conn.query(deletePatientSql, deletePatientParams);

        if (result.affectedRows == 0) {
          throw Exception('删除患者失败: $id');
        }
      });

      developer.log('删除患者成功: $id', name: 'MySqlPatientRepository');
    } catch (e, stackTrace) {
      developer.log('删除患者失败', error: e, stackTrace: stackTrace, name: 'MySqlPatientRepository');
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
      var whereClause = '';
      whereClause = _buildTenantWhere(whereClause);
      
      final sql = 'SELECT COUNT(*) as count FROM patients $whereClause';
      final params = _buildTenantParams([]);

      final results = await _dbHelper.query(sql, params);
      
      if (results.isNotEmpty) {
        final count = results.first.fields['count'];
        return count is int ? count : int.parse(count.toString());
      }
      return 0;
    } catch (e, stackTrace) {
      developer.log('获取患者数量失败', error: e, stackTrace: stackTrace, name: 'MySqlPatientRepository');
      throw Exception('获取患者数量失败: $e');
    }
  }

  /// 批量插入患者（用于数据迁移）
  Future<List<Patient>> batchInsertPatients(List<Patient> patients) async {
    try {
      return await _dbHelper.transaction((conn) async {
        final insertedPatients = <Patient>[];
        
        for (final patient in patients) {
          final sql = '''
            INSERT INTO patients 
            (id, name, age, gender, phone, note, created_at, updated_at, tenant_id) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''';

          final params = [
            patient.id,
            patient.name,
            patient.age,
            patient.gender,
            patient.phone,
            patient.note,
            MySqlDateTimeConverter.toMySqlDateTime(patient.createdAt),
            MySqlDateTimeConverter.toMySqlDateTime(patient.updatedAt),
            _tenantId,
          ];

          await conn.query(sql, params);
          insertedPatients.add(patient);
        }
        
        developer.log('批量插入患者成功: ${insertedPatients.length}条', name: 'MySqlPatientRepository');
        return insertedPatients;
      });
    } catch (e, stackTrace) {
      developer.log('批量插入患者失败', error: e, stackTrace: stackTrace, name: 'MySqlPatientRepository');
      throw Exception('批量插入患者失败: $e');
    }
  }
}
