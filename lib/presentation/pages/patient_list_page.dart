import 'package:flutter/material.dart';
import '../../data/models/patient.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/exam_repository.dart';
import '../../domain/usecases/manage_patients.dart';
import 'patient_detail_page.dart';
import 'camera_scan_page.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  final PatientUseCases _patientUseCases = PatientUseCases();
  final ExamRepository _examRepository = ExamRepository();
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  Map<String, int> _patientExamCounts = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final patients = await _patientUseCases.getPatientList.execute();
      
      // 获取每个患者的检查次数
      final examCounts = <String, int>{};
      for (final patient in patients) {
        final exams = await _examRepository.getExamsByPatientId(patient.id);
        examCounts[patient.id] = exams.length;
      }
      
      setState(() {
        _patients = patients;
        _patientExamCounts = examCounts;
        _filterPatients();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('加载患者列表失败: $e');
    }
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _patients.where((patient) {
        final matchesSearch = patient.name.toLowerCase().contains(query) ||
            (patient.phone?.contains(query) ?? false);
        
        if (_selectedFilter == 'all') return matchesSearch;
        if (_selectedFilter == 'children') {
          return matchesSearch && patient.age < 18;
        }
        if (_selectedFilter == 'adults') {
          return matchesSearch && patient.age >= 18;
        }
        return matchesSearch;
      }).toList();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('患者管理'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showAddPatientDialog(),
            icon: const Icon(Icons.person_add),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPatients.isEmpty
                    ? _buildEmptyState()
                    : _buildPatientList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCameraScan(),
        icon: const Icon(Icons.camera_alt),
        label: const Text('拍照录入'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索患者姓名或手机号',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterPatients();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (_) => _filterPatients(),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildFilterChip('全部', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('儿童', 'children'),
          const SizedBox(width: 8),
          _buildFilterChip('成人', 'adults'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _filterPatients();
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无患者记录',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加患者',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = _filteredPatients[index];
        return _buildPatientCard(patient);
      },
    );
  }

  Widget _buildPatientCard(Patient patient) {
    final isChild = patient.age < 18;
    final examCount = _patientExamCounts[patient.id] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: isChild ? Colors.orange[100] : Colors.blue[100],
          child: Icon(
            isChild ? Icons.child_care : Icons.person,
            color: isChild ? Colors.orange : Colors.blue,
          ),
        ),
        title: Row(
          children: [
            Text(
              patient.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: patient.gender == '男' ? Colors.blue[50] : Colors.pink[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                patient.gender,
                style: TextStyle(
                  fontSize: 12,
                  color: patient.gender == '男' ? Colors.blue : Colors.pink,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${patient.age}岁'),
                const SizedBox(width: 16),
                Icon(Icons.medical_services_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '$examCount 次检查',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (patient.phone != null) ...[
              const SizedBox(height: 4),
              Text(
                patient.phone!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToPatientDetail(patient),
      ),
    );
  }

  void _navigateToPatientDetail(Patient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailPage(patient: patient),
      ),
    ).then((_) => _loadPatients());
  }

  void _navigateToCameraScan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScanPage(),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        _showAddPatientDialog(prefilledData: result);
      }
    });
  }

  void _showAddPatientDialog({Map<String, dynamic>? prefilledData}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddPatientBottomSheet(
        prefilledData: prefilledData,
        onPatientAdded: _loadPatients,
        patientUseCases: _patientUseCases,
      ),
    );
  }
}

class _AddPatientBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? prefilledData;
  final VoidCallback onPatientAdded;
  final PatientUseCases patientUseCases;

  const _AddPatientBottomSheet({
    this.prefilledData,
    required this.onPatientAdded,
    required this.patientUseCases,
  });

  @override
  State<_AddPatientBottomSheet> createState() => _AddPatientBottomSheetState();
}

class _AddPatientBottomSheetState extends State<_AddPatientBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  String _gender = '男';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledData != null) {
      _nameController.text = widget.prefilledData!['name'] ?? '';
      _ageController.text = widget.prefilledData!['age']?.toString() ?? '';
      _gender = widget.prefilledData!['gender'] ?? '男';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '添加患者',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '姓名 *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入患者姓名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '年龄 *',
                        prefixIcon: Icon(Icons.cake_outlined),
                        border: OutlineInputBorder(),
                        suffixText: '岁',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入年龄';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 0 || age > 150) {
                          return '请输入有效年龄';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(
                        labelText: '性别 *',
                        prefixIcon: Icon(Icons.wc_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: ['男', '女'].map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _gender = value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '备注',
                  prefixIcon: Icon(Icons.note_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _savePatient,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await widget.patientUseCases.createPatient.execute(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onPatientAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('患者添加成功')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }
}
