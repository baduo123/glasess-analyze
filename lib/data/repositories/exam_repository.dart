import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/patient.dart';
import 'package:uuid/uuid.dart';

class ExamRepository {
  static final ExamRepository _instance = ExamRepository._internal();
  factory ExamRepository() => _instance;
  ExamRepository._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  /// 创建新检查记录
  Future<ExamRecord> createExam({
    String? patientId,
    required ExamType examType,
    required DateTime examDate,
    Map<String, dynamic>? indicatorValues,
    bool isDraft = false,
  }) async {
    try {
      final db = await _dbHelper.database;
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

      final json = exam.toJson();
      // 转换indicatorValues为JSON字符串
      if (indicatorValues != null) {
        json['indicator_values'] = jsonEncode(indicatorValues);
      }

      await db.insert(
        'exam_records',
        json,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return exam;
    } catch (e) {
      throw Exception('创建检查记录失败: $e');
    }
  }

  /// 根据ID获取检查记录
  Future<ExamRecord?> getExamById(String id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'exam_records',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return _parseExamRecord(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('获取检查记录失败: $e');
    }
  }

  /// 获取患者的所有检查记录
  Future<List<ExamRecord>> getExamsByPatientId(String patientId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'exam_records',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'exam_date DESC',
      );
      return maps.map((map) => _parseExamRecord(map)).toList();
    } catch (e) {
      throw Exception('获取患者检查记录失败: $e');
    }
  }

  /// 获取所有检查记录
  Future<List<ExamRecord>> getAllExams({bool? isDraft}) async {
    try {
      final db = await _dbHelper.database;
      
      String? whereClause;
      List<dynamic>? whereArgs;
      
      if (isDraft != null) {
        whereClause = 'is_draft = ?';
        whereArgs = [isDraft ? 1 : 0];
      }

      final maps = await db.query(
        'exam_records',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'exam_date DESC',
      );
      return maps.map((map) => _parseExamRecord(map)).toList();
    } catch (e) {
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
      final db = await _dbHelper.database;
      final existingExam = await getExamById(id);
      
      if (existingExam == null) {
        throw Exception('检查记录不存在');
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

      final json = updatedExam.toJson();
      // 转换indicatorValues为JSON字符串
      if (indicatorValues != null) {
        json['indicator_values'] = jsonEncode(indicatorValues);
      }

      await db.update(
        'exam_records',
        json,
        where: 'id = ?',
        whereArgs: [id],
      );

      return updatedExam;
    } catch (e) {
      throw Exception('更新检查记录失败: $e');
    }
  }

  /// 删除检查记录
  Future<void> deleteExam(String id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        'exam_records',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('检查记录不存在');
      }
    } catch (e) {
      throw Exception('删除检查记录失败: $e');
    }
  }

  /// 获取草稿数量
  Future<int> getDraftCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM exam_records WHERE is_draft = 1'
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('获取草稿数量失败: $e');
    }
  }

  /// 获取检查记录总数
  Future<int> getExamCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM exam_records');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('获取检查记录数量失败: $e');
    }
  }

  /// 解析检查记录（处理JSON字符串转换）
  ExamRecord _parseExamRecord(Map<String, dynamic> map) {
    final json = Map<String, dynamic>.from(map);
    
    // 解析indicator_values JSON字符串
    if (json['indicator_values'] != null && json['indicator_values'] is String) {
      try {
        json['indicator_values'] = jsonDecode(json['indicator_values']);
      } catch (e) {
        json['indicator_values'] = null;
      }
    }
    
    return ExamRecord.fromJson(json);
  }
}
