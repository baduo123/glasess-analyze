import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/patient.dart';
import '../../data/repositories/exam_repository.dart';

// ============================================
// Repository Provider
// ============================================

/// 检查记录Repository Provider
/// 全局单例，整个应用共享同一个实例
final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository();
});

// ============================================
// State Providers
// ============================================

/// 检查记录列表状态管理器
class ExamListNotifier extends StateNotifier<AsyncValue<List<ExamRecord>>> {
  final ExamRepository _repository;

  ExamListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadExams();
  }

  /// 加载所有检查记录
  Future<void> loadExams({bool? isDraft}) async {
    state = const AsyncValue.loading();
    try {
      final exams = await _repository.getAllExams(isDraft: isDraft);
      state = AsyncValue.data(exams);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 创建检查记录
  Future<ExamRecord?> createExam({
    String? patientId,
    required ExamType examType,
    required DateTime examDate,
    Map<String, dynamic>? indicatorValues,
    bool isDraft = false,
  }) async {
    try {
      final exam = await _repository.createExam(
        patientId: patientId,
        examType: examType,
        examDate: examDate,
        indicatorValues: indicatorValues,
        isDraft: isDraft,
      );
      // 刷新列表
      await loadExams();
      return exam;
    } catch (e) {
      rethrow;
    }
  }

  /// 更新检查记录
  Future<ExamRecord?> updateExam(
    String id, {
    String? patientId,
    ExamType? examType,
    DateTime? examDate,
    Map<String, dynamic>? indicatorValues,
    bool? isDraft,
    String? pdfPath,
  }) async {
    try {
      final exam = await _repository.updateExam(
        id,
        patientId: patientId,
        examType: examType,
        examDate: examDate,
        indicatorValues: indicatorValues,
        isDraft: isDraft,
        pdfPath: pdfPath,
      );
      // 刷新列表
      await loadExams();
      return exam;
    } catch (e) {
      rethrow;
    }
  }

  /// 删除检查记录
  Future<void> deleteExam(String id) async {
    try {
      await _repository.deleteExam(id);
      // 刷新列表
      await loadExams();
    } catch (e) {
      rethrow;
    }
  }

  /// 刷新列表
  Future<void> refresh() async {
    await loadExams();
  }
}

/// 患者检查记录状态管理器
class PatientExamsNotifier extends StateNotifier<AsyncValue<List<ExamRecord>>> {
  final ExamRepository _repository;
  final String patientId;

  PatientExamsNotifier(this._repository, this.patientId) : super(const AsyncValue.loading()) {
    loadPatientExams();
  }

  /// 加载指定患者的检查记录
  Future<void> loadPatientExams() async {
    state = const AsyncValue.loading();
    try {
      final exams = await _repository.getExamsByPatientId(patientId);
      state = AsyncValue.data(exams);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 创建检查记录并关联到当前患者
  Future<ExamRecord?> createExamForPatient({
    required ExamType examType,
    required DateTime examDate,
    Map<String, dynamic>? indicatorValues,
    bool isDraft = false,
  }) async {
    try {
      final exam = await _repository.createExam(
        patientId: patientId,
        examType: examType,
        examDate: examDate,
        indicatorValues: indicatorValues,
        isDraft: isDraft,
      );
      // 刷新列表
      await loadPatientExams();
      return exam;
    } catch (e) {
      rethrow;
    }
  }

  /// 刷新列表
  Future<void> refresh() async {
    await loadPatientExams();
  }
}

// ============================================
// StateNotifier Providers
// ============================================

/// 所有检查记录列表状态Provider
/// 管理所有检查记录的加载、搜索、增删改操作
final examListProvider = StateNotifierProvider<ExamListNotifier, AsyncValue<List<ExamRecord>>>((ref) {
  final repository = ref.watch(examRepositoryProvider);
  return ExamListNotifier(repository);
});

/// 指定患者的检查记录Provider（Family）
/// 根据患者ID动态创建对应的检查记录管理器
final patientExamsProvider = StateNotifierProvider.family<PatientExamsNotifier, AsyncValue<List<ExamRecord>>, String>(
  (ref, patientId) {
    final repository = ref.watch(examRepositoryProvider);
    return PatientExamsNotifier(repository, patientId);
  },
);

// ============================================
// Simple State Providers
// ============================================

/// 当前检查记录Provider
/// 用于在页面间传递当前编辑/查看的检查记录
final currentExamProvider = StateProvider<ExamRecord?>((ref) => null);

/// 草稿检查记录筛选Provider
/// 用于切换是否只显示草稿
final showDraftsOnlyProvider = StateProvider<bool>((ref) => false);

/// 检查类型筛选Provider
/// 用于按检查类型筛选记录
final examTypeFilterProvider = StateProvider<ExamType?>((ref) => null);

// ============================================
// Future Providers
// ============================================

/// 指定患者的检查记录Future Provider
/// 直接返回检查记录列表，适用于只读场景
final patientExamsFutureProvider = FutureProvider.family<List<ExamRecord>, String>((ref, patientId) async {
  final repository = ref.watch(examRepositoryProvider);
  return repository.getExamsByPatientId(patientId);
});

/// 所有检查记录Future Provider
final allExamsFutureProvider = FutureProvider<List<ExamRecord>>((ref) async {
  final repository = ref.watch(examRepositoryProvider);
  return repository.getAllExams();
});

/// 草稿检查记录Future Provider
final draftExamsFutureProvider = FutureProvider<List<ExamRecord>>((ref) async {
  final repository = ref.watch(examRepositoryProvider);
  return repository.getAllExams(isDraft: true);
});

/// 正式检查记录Future Provider
final formalExamsFutureProvider = FutureProvider<List<ExamRecord>>((ref) async {
  final repository = ref.watch(examRepositoryProvider);
  return repository.getAllExams(isDraft: false);
});

/// 按ID获取检查记录Provider
final examByIdFutureProvider = FutureProvider.family<ExamRecord?, String>((ref, examId) async {
  final repository = ref.watch(examRepositoryProvider);
  return repository.getExamById(examId);
});

// ============================================
// Count Providers
// ============================================

/// 草稿数量Provider
/// 用于显示草稿数量徽章
final draftCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(examRepositoryProvider);
  return repository.getDraftCount();
});

/// 检查记录总数Provider
final totalExamCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(examRepositoryProvider);
  return repository.getExamCount();
});

/// 指定患者的检查记录数量Provider
final patientExamCountProvider = FutureProvider.family<int, String>((ref, patientId) async {
  final repository = ref.watch(examRepositoryProvider);
  final exams = await repository.getExamsByPatientId(patientId);
  return exams.length;
});

// ============================================
// Computed/Filtered Providers
// ============================================

/// 筛选后的检查记录Provider
/// 根据草稿状态和检查类型筛选
final filteredExamsProvider = Provider<AsyncValue<List<ExamRecord>>>((ref) {
  final showDraftsOnly = ref.watch(showDraftsOnlyProvider);
  final examTypeFilter = ref.watch(examTypeFilterProvider);
  final examsAsync = ref.watch(examListProvider);

  return examsAsync.when(
    data: (exams) {
      var filtered = exams;
      
      // 筛选草稿状态
      if (showDraftsOnly) {
        filtered = filtered.where((e) => e.isDraft).toList();
      }
      
      // 筛选检查类型
      if (examTypeFilter != null) {
        filtered = filtered.where((e) => e.examType == examTypeFilter).toList();
      }
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// ============================================
// UI State Providers
// ============================================

/// 检查记录表单验证状态Provider
final examFormErrorsProvider = StateProvider<Map<String, String?>>((ref) => {});

/// 检查记录操作状态Provider
final examOperationStatusProvider = StateProvider<AsyncValue<void>?>((ref) => null);

/// 检查记录加载状态Provider
final examLoadingProvider = StateProvider<bool>((ref) => false);

// ============================================
// Helper Classes
// ============================================

/// 检查记录操作结果类
class ExamOperationResult {
  final bool success;
  final ExamRecord? exam;
  final String? errorMessage;

  ExamOperationResult._({
    required this.success,
    this.exam,
    this.errorMessage,
  });

  factory ExamOperationResult.success(ExamRecord exam) {
    return ExamOperationResult._(
      success: true,
      exam: exam,
    );
  }

  factory ExamOperationResult.failure(String message) {
    return ExamOperationResult._(
      success: false,
      errorMessage: message,
    );
  }
}

/// 检查记录筛选条件类
class ExamFilter {
  final bool? isDraft;
  final ExamType? examType;
  final DateTime? startDate;
  final DateTime? endDate;

  ExamFilter({
    this.isDraft,
    this.examType,
    this.startDate,
    this.endDate,
  });

  bool get isEmpty => 
    isDraft == null && 
    examType == null && 
    startDate == null && 
    endDate == null;

  ExamFilter copyWith({
    bool? isDraft,
    ExamType? examType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ExamFilter(
      isDraft: isDraft ?? this.isDraft,
      examType: examType ?? this.examType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
