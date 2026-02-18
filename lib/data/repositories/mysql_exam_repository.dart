import 'dart:convert';
import 'dart:developer' as developer;
import 'package:mysql1/mysql1.dart';
import '../database/mysql_database_helper.dart';
import '../models/patient.dart';
import 'package:uuid/uuid.dart';

/// MySQL检查记录数据仓储类
/// 实现与SQLite版本相同的接口，支持多租户
class MySqlExamRepository {
  static MySqlExamRepository? _instance;
  
  factory MySqlExamRepository() {
    _instance ??= MySqlExamRepository._internal();
    return _instance!;
  }
  
  MySqlExamRepository._internal();

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

  /// 验证检查记录数据
  void _validateExamData({
    required ExamType examType,
    required DateTime examDate,
  }) {
    if (examDate.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      throw ArgumentError('检查日期不能是未来日期');
    }
    if (examDate.isBefore(DateTime(1900))) {
      throw ArgumentError('检查日期无效');
    }
  }

  /// 将MySQL结果行转换为ExamRecord对象
  ExamRecord _rowToExamRecord(Map<String, dynamic> row) {
    Map<String, dynamic>? indicatorValues;
    final indicatorValuesStr = row['indicator_values']?.toString();
    if (indicatorValuesStr != null && indicatorValuesStr.isNotEmpty) {
      try {
        indicatorValues = jsonDecode(indicatorValuesStr) as Map<String, dynamic>;
      } catch (e) {
        indicatorValues = null;
      }
    }

    return ExamRecord(
      id: row['id'].toString(),
      patientId: row['patient_id']?.toString(),
      examType: ExamType.values.firstWhere(
        (e) => e.name == row['exam_type'].toString(),
        orElse: () => ExamType.standardFullSet,
      ),
      examDate: row['exam_date'] is DateTime 
          ? row['exam_date'] as DateTime
          : MySqlDateTimeConverter.fromMySqlDateTime(row['exam_date'].toString()),
      createdAt: row['created_at'] is DateTime 
          ? row['created_at'] as DateTime
          : MySqlDateTimeConverter.fromMySqlDateTime(row['created_at'].toString()),
      isDraft: row['is_draft'] == 1 || row['is_draft'] == true,
      pdfPath: row['pdf_path']?.toString(),
      indicatorValues: indicatorValues,
    );
  }

  /// 创建新检查记录
  Future<ExamRecord> createExam({
    String? patientId,
    required ExamType examType,
    required DateTime examDate,
    Map<String, dynamic>? indicatorValues,
    bool isDraft = false,
  }) async {
    try {
      // 验证输入数据
      _validateExamData(examType: examType, examDate: examDate);

      final now = DateTime.now();
      
      final exam = ExamRecord(
        id: _uuid.v4(),
        patientId: patientId,
        examType: examType,
        examDate: examDate,
        createdAt: now,
        isDraft: isDraft,
        indicatorValues: indicatorValues,
      );

      final sql = '''
        INSERT INTO exam_records 
        (id, patient_id, exam_type, exam_date, created_at, is_draft, pdf_path, indicator_values, tenant_id) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''';

      final params = [
        exam.id,
        exam.patientId,
        exam.examType.name,
        MySqlDateTimeConverter.toMySqlDateTime(exam.examDate),
        MySqlDateTimeConverter.toMySqlDateTime(exam.createdAt),
        exam.isDraft ? 1 : 0,
        exam.pdfPath,
        indicatorValues != null ? jsonEncode(indicatorValues) : null,
        _tenantId,
      ];

      await _dbHelper.insert(sql, params);

      developer.log('创建检查记录成功: ${exam.id}', name: 'MySqlExamRepository');
      return exam;
    } on ArgumentError {
      rethrow;
    } catch (e, stackTrace) {
      developer.log('创建检查记录失败', error: e, stackTrace: stackTrace, name: 'MySqlExamRepository');
      throw Exception('创建检查记录失败: $e');
    }
  }

  /// 根据ID获取检查记录
  Future<ExamRecord?> getExamById(String id) async {
    try {
      var whereClause = 'WHERE id = ?';
      whereClause = _buildTenantWhere(whereClause);
      
      final sql = 'SELECT * FROM exam_records $whereClause LIMIT 1';
      final params = _buildTenantParams([id]);

      final results = await _dbHelper.query(sql, params);

      if (results.isNotEmpty) {
        return _rowToExamRecord(results.first.fields);
      }
      return null;
    } catch (e, stackTrace) {
      developer.log('获取检查记录失败: $id', error: e, stackTrace: stackTrace, name: 'MySqlExamRepository');
      throw Exception('获取检查记录失败: $e');
    }
  }

  /// 获取患者的所有检查记录
  Future<List<ExamRecord>> getExamsByPatientId(String patientId) async {
    try {
      var whereClause = 'WHERE patient_id = ?';
      whereClause = _buildTenantWhere(whereClause);
      
      final sql = 'SELECT * FROM exam_records $whereClause ORDER BY exam_date DESC';
      final params = _buildTenantParams([patientId]);

      final results = await _dbHelper.query(sql, params);

      return results.map((row) => _rowToExamRecord(row.fields)).toList();
    } catch (e, stackTrace) {
      developer.log('获取患者检查记录失败: $patientId', error: e, stackTrace: stackTrace, name: 'MySqlExamRepository');
      throw Exception('获取患者检查记录失败: $e');
    }
  }

  /// 获取所有检查记录
  Future<List<ExamRecord>> getAllExams({bool? isDraft}) async {
    try {
      String whereClause = '';
      List<dynamic> params = [];
      
      if (isDraft != null) {
        whereClause = 'WHERE is_draft = ?';
        params = [isDraft ? 1 : 0];
      }

      whereClause = _buildTenantWhere(whereClause);
      params = _buildTenantParams(params);

      final sql = 'SELECT * FROM exam_records $whereClause ORDER BY exam_date DESC';
      final results = await _dbHelper.query(sql, params);

      return results.map((row) => _rowToExamRecord(row.fields)).toList();
    } catch (e, stackTrace) {
      developer.log('获取检查记录列表失败', error: e, stackTrace: stackTrace, name: 'MySqlExamRepository');
      throw Exception('获取检查记录列表失败: $e');
    }
  }

  /// 更新检查记录
  Future<ExamRecord> updateExam(
    String id, {
    String? patientId,
    ExamType? examType,
    DateTime? examDate,
    Map<String, dynamic>? indicatorValues,
    bool? isDraft,
    String? pdfPath,
  }) async {
    try {
      // 验证日期
      if (examDate != null) {
        _validateExamData(examType: examType ?? ExamType.standardFullSet, examDate: examDate);
      }

      final existingExam = await getExamById(id);
      
      if (existingExam == null) {
        throw Exception('检查记录不存在: $id');
      }

      final updatedExam = ExamRecord(
        id: id,
        patientId: patientId ?? existingExam.patientId,
        examType: examType ?? existingExam.examType,
        examDate: examDate ?? existingExam.examDate,
        createdAt: existingExam.createdAt,
        isDraft: isDraft ?? existingExam.isDraft,
        pdfPath: pdfPath ?? existingExam.pdfPath,
        indicatorValues: indicatorValues ?? existingExam.indicatorValues,
      );

      final sql = '''
        UPDATE exam_records 
        SET patient_id = ?, exam_type = ?, exam_date = ?, is_draft = ?, pdf_path = ?, indicator_values = ?
        WHERE id = ?
      ''';

      var params = [
        updatedExam.patientId,
        updatedExam.examType.name,
        MySqlDateTimeConverter.toMySqlDateTime(updatedExam.examDate),
        updatedExam.isDraft ? 1 : 0,
        updatedExam.pdfPath,
        updatedExam.indicatorValues != null ? jsonEncode(updatedExam.indicatorValues) : null,
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
        throw Exception('更新失败，检查记录可能已被删除或无权限');
      }

      developer.log('更新检查记录成功: $id', name: 'MySqlExamRepository');
      return updatedExam;
    } on ArgumentError {
      rethrow;
    } catch (e, stackTrace) {
      developer.log('更新检查记录失败', error: e, stackTrace: stackTrace, name: 'MySqlExamRepository');
      throw Exception('更新检查记录失败: $e');
    }
  }

  /// 删除检查记录
  Future<void> deleteExam(String id) async {
    try {
      await _dbHelper.transaction((conn) async {
        // 先检查记录是否存在且有权限
        var checkWhere = 'WHERE id = ?';
        checkWhere = _buildTenantWhere(checkWhere);
        
        final checkSql = 'SELECT id FROM exam_records $checkWhere LIMIT 1';
        final checkParams = _buildTenantParams([id]);
        
        final checkResult = await conn.query(checkSql, checkParams);
        if (checkResult.isEmpty) {
          throw Exception('检查记录不存在或无权限: $id');
        }

        // 删除检查记录
        var whereClause = 'WHERE id = ?';
        whereClause = _buildTenantWhere(whereClause);
        
        final sql = 'DELETE FROM exam_records $whereClause';
        final params = _buildTenantParams([id]);
        
        final result = await conn.query(sql, params);

        if (result.affectedRows == 0) {
          throw Exception('删除失败，检查记录可能已被删除');
        }
      });

      developer.log('删除检查记录成功: $id', name: 'MySqlExamRepository');
    } catch (e, stackTrace) {
      developer.log('删除检查记录失败', error: e, stackTrace: stackTrace, name: 'MySqlExamRepository');
      throw Exception('删除检查记录失败: $e');
    }
  }

  /// 获取草稿数量
  Future<int> getDraftCount() async {
    try {
      var whereClause = 'WHERE is_draft = 1';
      whereClause = _buildTenantWhere(whereClause);
      
      final sql = 'SELECT COUNT(*) as count FROM exam_records $whereClause';
      final params = _buildTenantParams([]);

      final results = await _dbHelper.query(sql, params);
      
      if (results.isNotEmpty) {
        final count = results.first.fields['count'];
        return count is int ? count : int.parse(count.toString());
      }
      return 0;
    } catch (e, stackTrace) {
      developer.log('获取草稿数量失败', error: e, stackTrace: stackTrace, name: 'MySqlExamRepository');
      throw Exception('获取草稿数量失败: $e');
    }
  }

  /// 获取检查记录总数
  Future<int> getExamCount() async {
    try {
      var whereClause = '';
      whereClause = _buildTenantWhere(whereClause);
      
      final sql = 'SELECT COUNT(*) as count FROM exam_records $whereClause';
      final params = _buildTenantParams([]);

      final results = await _dbHelper.query(sql, params);
      
      if (results.isNotEmpty) {
        final count = results.first.fields['count'];
        return count is int ? count : int.parse(count.toString());
      }
      return 0;
    } catch (e, stackTrace) {
      developer.log('获取检查记录数量失败', error: e, stackTrace: stackTrace, name: 'MySqlExamRepository');
      throw Exception('获取检查记录数量失败: $e');
    }
  }

  /// 获取患者的最新检查记录
  Future<ExamRecord?> getLatestExamByPatientId(String patientId) async {
    try {
      var whereClause = 'WHERE patient_id = ?';
      whereClause = _buildTenantWhere(whereClause);
      
      final sql = 'SELECT * FROM exam_records $whereClause ORDER BY exam_date DESC LIMIT 1';
      final params = _buildTenantParams([patientId]);

      final results = await _dbHelper.query(sql, params);

      if (results.isNotEmpty) {
        return _rowToExamRecord(results.first.fields);
      }
      return null;
    } catch (e, stackTrace) {
      developer.log('获取患者最新检查记录失败: $patientId', error: e, stackTrace: stackTrace, name: 'MySqlExamRepository');
      throw Exception('获取患者最新检查记录失败: $e');
    }
  }

  /// 批量插入检查记录（用于数据迁移）
  Future<List<ExamRecord>> batchInsertExams(List<ExamRecord> exams) async {
    try {
      return await _dbHelper.transaction((conn) async {
        final insertedExams = <ExamRecord>[];
        
        for (final exam in exams) {
          final sql = '''
            INSERT INTO exam_records 
            (id, patient_id, exam_type, exam_date, created_at, is_draft, pdf_path, indicator_values, tenant_id) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''';

          final params = [
            exam.id,
            exam.patientId,
            exam.examType.name,
            MySqlDateTimeConverter.toMySqlDateTime(exam.examDate),
            MySqlDateTimeConverter.toMySqlDateTime(exam.createdAt),
            exam.isDraft ? 1 : 0,
            exam.pdfPath,
            exam.indicatorValues != null ? jsonEncode(exam.indicatorValues) : null,
            _tenantId,
          ];

          await conn.query(sql, params);
          insertedExams.add(exam);
        }
        
        developer.log('批量插入检查记录成功: ${insertedExams.length}条', name: 'MySqlExamRepository');
        return insertedExams;
      });
    } catch (e, stackTrace) {
      developer.log('批量插入检查记录失败', error: e, stackTrace: stackTrace, name: 'MySqlExamRepository');
      throw Exception('批量插入检查记录失败: $e');
    }
  }

  /// 获取检查记录统计（按类型分组）
  Future<Map<ExamType, int>> getExamCountByType() async {
    try {
      var whereClause = '';
      whereClause = _buildTenantWhere(whereClause);
      
      final sql = '''
        SELECT exam_type, COUNT(*) as count 
        FROM exam_records 
        $whereClause
        GROUP BY exam_type
      ''';
      final params = _buildTenantParams([]);

      final results = await _dbHelper.query(sql, params);
      
      final Map<ExamType, int> countByType = {};
      for (final row in results) {
        final typeStr = row.fields['exam_type'].toString();
        final count = row.fields['count'];
        final examType = ExamType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => ExamType.custom,
        );
        countByType[examType] = count is int ? count : int.parse(count.toString());
      }
      
      return countByType;
    } catch (e, stackTrace) {
      developer.log('获取检查记录统计失败', error: e, stackTrace: stackTrace, name: 'MySqlExamRepository');
      throw Exception('获取检查记录统计失败: $e');
    }
  }
}
