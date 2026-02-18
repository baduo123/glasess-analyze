import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/patient.dart';
import '../../data/repositories/patient_repository.dart';

// ============================================
// Repository Provider
// ============================================

/// 患者Repository Provider
/// 全局单例，整个应用共享同一个实例
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository();
});

// ============================================
// State Providers
// ============================================

/// 患者列表状态管理器
class PatientListNotifier extends StateNotifier<AsyncValue<List<Patient>>> {
  final PatientRepository _repository;

  PatientListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPatients();
  }

  /// 加载所有患者
  Future<void> loadPatients() async {
    state = const AsyncValue.loading();
    try {
      final patients = await _repository.getAllPatients();
      state = AsyncValue.data(patients);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 搜索患者
  Future<void> searchPatients(String query) async {
    state = const AsyncValue.loading();
    try {
      final patients = await _repository.getAllPatients(searchQuery: query);
      state = AsyncValue.data(patients);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 创建患者
  Future<Patient?> createPatient({
    required String name,
    required int age,
    required String gender,
    String? phone,
    String? note,
  }) async {
    try {
      final patient = await _repository.createPatient(
        name: name,
        age: age,
        gender: gender,
        phone: phone,
        note: note,
      );
      // 刷新列表
      await loadPatients();
      return patient;
    } catch (e) {
      rethrow;
    }
  }

  /// 更新患者
  Future<Patient?> updatePatient(
    String id, {
    String? name,
    int? age,
    String? gender,
    String? phone,
    String? note,
  }) async {
    try {
      final patient = await _repository.updatePatient(
        id,
        name: name,
        age: age,
        gender: gender,
        phone: phone,
        note: note,
      );
      // 刷新列表
      await loadPatients();
      return patient;
    } catch (e) {
      rethrow;
    }
  }

  /// 删除患者
  Future<void> deletePatient(String id) async {
    try {
      await _repository.deletePatient(id);
      // 刷新列表
      await loadPatients();
    } catch (e) {
      rethrow;
    }
  }

  /// 刷新列表
  Future<void> refresh() async {
    await loadPatients();
  }
}

// ============================================
// StateNotifier Providers
// ============================================

/// 患者列表状态Provider
/// 管理患者列表的加载、搜索、增删改操作
final patientListProvider = StateNotifierProvider<PatientListNotifier, AsyncValue<List<Patient>>>((ref) {
  final repository = ref.watch(patientRepositoryProvider);
  return PatientListNotifier(repository);
});

// ============================================
// Simple State Providers
// ============================================

/// 当前选中患者Provider
/// 用于在页面间传递选中的患者对象
final selectedPatientProvider = StateProvider<Patient?>((ref) => null);

/// 搜索关键词Provider
/// 用于存储和响应搜索输入
final patientSearchQueryProvider = StateProvider<String>((ref) => '');

/// 患者详情加载状态Provider
/// 用于显示患者详情的加载状态
final patientDetailLoadingProvider = StateProvider<bool>((ref) => false);

// ============================================
// Computed/Filtered Providers
// ============================================

/// 过滤后的患者列表Provider
/// 根据搜索关键词实时过滤患者列表
final filteredPatientsProvider = Provider<AsyncValue<List<Patient>>>((ref) {
  final query = ref.watch(patientSearchQueryProvider).toLowerCase();
  final patientsAsync = ref.watch(patientListProvider);

  return patientsAsync.when(
    data: (patients) {
      if (query.isEmpty) return AsyncValue.data(patients);
      
      final filtered = patients.where((patient) {
        final nameMatch = patient.name.toLowerCase().contains(query);
        final phoneMatch = patient.phone?.toLowerCase().contains(query) ?? false;
        return nameMatch || phoneMatch;
      }).toList();
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// 患者数量Provider
/// 提供患者总数，用于统计和显示
final patientCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.getPatientCount();
});

/// 按ID获取患者Provider
/// 根据患者ID获取详细信息
final patientByIdProvider = FutureProvider.family<Patient?, String>((ref, patientId) async {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.getPatientById(patientId);
});

// ============================================
// UI State Providers
// ============================================

/// 患者表单验证状态Provider
/// 用于管理患者表单的错误状态
final patientFormErrorsProvider = StateProvider<Map<String, String?>>((ref) => {});

/// 患者操作状态Provider
/// 用于显示操作成功/失败的状态
final patientOperationStatusProvider = StateProvider<AsyncValue<void>?>((ref) => null);

// ============================================
// Helper Classes
// ============================================

/// 患者操作结果类
/// 封装患者操作的结果和可能的错误
class PatientOperationResult {
  final bool success;
  final Patient? patient;
  final String? errorMessage;

  PatientOperationResult._({
    required this.success,
    this.patient,
    this.errorMessage,
  });

  factory PatientOperationResult.success(Patient patient) {
    return PatientOperationResult._(
      success: true,
      patient: patient,
    );
  }

  factory PatientOperationResult.failure(String message) {
    return PatientOperationResult._(
      success: false,
      errorMessage: message,
    );
  }
}

/// 患者筛选条件类
/// 用于复杂的患者筛选场景
class PatientFilter {
  final String? searchQuery;
  final String? gender;
  final int? minAge;
  final int? maxAge;

  PatientFilter({
    this.searchQuery,
    this.gender,
    this.minAge,
    this.maxAge,
  });

  bool get isEmpty => 
    searchQuery == null && 
    gender == null && 
    minAge == null && 
    maxAge == null;

  PatientFilter copyWith({
    String? searchQuery,
    String? gender,
    int? minAge,
    int? maxAge,
  }) {
    return PatientFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      gender: gender ?? this.gender,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
    );
  }
}
