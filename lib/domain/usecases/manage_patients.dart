import 'dart:developer' as developer;
import '../../data/models/patient.dart';
import '../../data/repositories/patient_repository.dart';

/// 创建患者用例
class CreatePatientUseCase {
  final PatientRepository _repository;

  CreatePatientUseCase({PatientRepository? repository})
      : _repository = repository ?? PatientRepository();

  Future<Patient> execute({
    required String name,
    required int age,
    required String gender,
    String? phone,
    String? note,
  }) async {
    try {
      developer.log('CreatePatientUseCase: 创建患者 - $name');

      // 验证输入数据
      _validateInput(name, age, gender);

      final patient = await _repository.createPatient(
        name: name,
        age: age,
        gender: gender,
        phone: phone,
        note: note,
      );

      developer.log('CreatePatientUseCase: 患者创建成功 - ${patient.id}');
      return patient;
    } catch (e, stackTrace) {
      developer.log('CreatePatientUseCase: 创建患者失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  void _validateInput(String name, int age, String gender) {
    if (name.trim().isEmpty) {
      throw ArgumentError('患者姓名不能为空');
    }

    if (name.length > 50) {
      throw ArgumentError('患者姓名不能超过50个字符');
    }

    if (age < 0 || age > 150) {
      throw ArgumentError('年龄必须在0-150岁之间');
    }

    final validGenders = ['男', '女', '其他'];
    if (!validGenders.contains(gender)) {
      throw ArgumentError('性别必须是: ${validGenders.join(", ")}');
    }
  }
}

/// 获取患者详情用例
class GetPatientDetailUseCase {
  final PatientRepository _repository;

  GetPatientDetailUseCase({PatientRepository? repository})
      : _repository = repository ?? PatientRepository();

  Future<Patient?> execute(String patientId) async {
    try {
      developer.log('GetPatientDetailUseCase: 获取患者详情 - $patientId');

      if (patientId.isEmpty) {
        throw ArgumentError('患者ID不能为空');
      }

      final patient = await _repository.getPatientById(patientId);
      
      if (patient == null) {
        developer.log('GetPatientDetailUseCase: 患者不存在 - $patientId');
      }

      return patient;
    } catch (e, stackTrace) {
      developer.log('GetPatientDetailUseCase: 获取患者详情失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// 获取患者列表用例
class GetPatientListUseCase {
  final PatientRepository _repository;

  GetPatientListUseCase({PatientRepository? repository})
      : _repository = repository ?? PatientRepository();

  Future<List<Patient>> execute({String? searchQuery}) async {
    try {
      developer.log('GetPatientListUseCase: 获取患者列表');
      
      final patients = await _repository.getAllPatients(searchQuery: searchQuery);
      developer.log('GetPatientListUseCase: 获取到 ${patients.length} 位患者');
      
      return patients;
    } catch (e, stackTrace) {
      developer.log('GetPatientListUseCase: 获取患者列表失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// 更新患者信息用例
class UpdatePatientUseCase {
  final PatientRepository _repository;

  UpdatePatientUseCase({PatientRepository? repository})
      : _repository = repository ?? PatientRepository();

  Future<Patient> execute(
    String patientId, {
    String? name,
    int? age,
    String? gender,
    String? phone,
    String? note,
  }) async {
    try {
      developer.log('UpdatePatientUseCase: 更新患者信息 - $patientId');

      if (patientId.isEmpty) {
        throw ArgumentError('患者ID不能为空');
      }

      // 验证输入数据
      if (name != null) {
        if (name.trim().isEmpty) {
          throw ArgumentError('患者姓名不能为空');
        }
        if (name.length > 50) {
          throw ArgumentError('患者姓名不能超过50个字符');
        }
      }

      if (age != null && (age < 0 || age > 150)) {
        throw ArgumentError('年龄必须在0-150岁之间');
      }

      if (gender != null) {
        final validGenders = ['男', '女', '其他'];
        if (!validGenders.contains(gender)) {
          throw ArgumentError('性别必须是: ${validGenders.join(", ")}');
        }
      }

      final patient = await _repository.updatePatient(
        patientId,
        name: name,
        age: age,
        gender: gender,
        phone: phone,
        note: note,
      );

      developer.log('UpdatePatientUseCase: 患者信息更新成功 - $patientId');
      return patient;
    } catch (e, stackTrace) {
      developer.log('UpdatePatientUseCase: 更新患者信息失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// 删除患者用例
class DeletePatientUseCase {
  final PatientRepository _repository;

  DeletePatientUseCase({PatientRepository? repository})
      : _repository = repository ?? PatientRepository();

  Future<void> execute(String patientId) async {
    try {
      developer.log('DeletePatientUseCase: 删除患者 - $patientId');

      if (patientId.isEmpty) {
        throw ArgumentError('患者ID不能为空');
      }

      await _repository.deletePatient(patientId);
      
      developer.log('DeletePatientUseCase: 患者删除成功 - $patientId');
    } catch (e, stackTrace) {
      developer.log('DeletePatientUseCase: 删除患者失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// 搜索患者用例
class SearchPatientsUseCase {
  final PatientRepository _repository;

  SearchPatientsUseCase({PatientRepository? repository})
      : _repository = repository ?? PatientRepository();

  Future<List<Patient>> execute(String query) async {
    try {
      developer.log('SearchPatientsUseCase: 搜索患者 - "$query"');

      if (query.trim().isEmpty) {
        return await _repository.getAllPatients();
      }

      final patients = await _repository.searchPatients(query.trim());
      developer.log('SearchPatientsUseCase: 搜索到 ${patients.length} 位患者');
      
      return patients;
    } catch (e, stackTrace) {
      developer.log('SearchPatientsUseCase: 搜索患者失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// 患者管理用例组合类
/// 用于统一管理所有患者相关的用例
class PatientUseCases {
  final PatientRepository _repository;

  late final CreatePatientUseCase createPatient;
  late final GetPatientDetailUseCase getPatientDetail;
  late final GetPatientListUseCase getPatientList;
  late final UpdatePatientUseCase updatePatient;
  late final DeletePatientUseCase deletePatient;
  late final SearchPatientsUseCase searchPatients;

  PatientUseCases({PatientRepository? repository})
      : _repository = repository ?? PatientRepository() {
    createPatient = CreatePatientUseCase(repository: _repository);
    getPatientDetail = GetPatientDetailUseCase(repository: _repository);
    getPatientList = GetPatientListUseCase(repository: _repository);
    updatePatient = UpdatePatientUseCase(repository: _repository);
    deletePatient = DeletePatientUseCase(repository: _repository);
    searchPatients = SearchPatientsUseCase(repository: _repository);
  }
}
