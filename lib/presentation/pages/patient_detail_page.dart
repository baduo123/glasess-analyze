import 'package:flutter/material.dart';
import '../../data/models/patient.dart';
import '../../data/repositories/exam_repository.dart';
import '../../domain/usecases/manage_patients.dart';
import 'exam_type_selection_page.dart';

class PatientDetailPage extends StatefulWidget {
  final Patient patient;

  const PatientDetailPage({
    super.key,
    required this.patient,
  });

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  final ExamRepository _examRepository = ExamRepository();
  final PatientUseCases _patientUseCases = PatientUseCases();
  List<ExamRecord> _examRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamRecords();
  }

  Future<void> _loadExamRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await _examRepository.getExamsByPatientId(widget.patient.id);
      setState(() {
        _examRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('加载检查记录失败: $e');
    }
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
        title: const Text('患者详情'),
        actions: [
          IconButton(
            onPressed: _showEditDialog,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: _showDeleteConfirm,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientInfoCard(),
            const SizedBox(height: 24),
            _buildExamRecordsSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToNewExam(),
        icon: const Icon(Icons.add),
        label: const Text('新建检查'),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    final isChild = widget.patient.age < 18;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: isChild ? Colors.orange[100] : Colors.blue[100],
                  child: Icon(
                    isChild ? Icons.child_care : Icons.person,
                    size: 36,
                    color: isChild ? Colors.orange : Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.patient.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.patient.gender == '男'
                                  ? Colors.blue[50]
                                  : Colors.pink[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.patient.gender,
                              style: TextStyle(
                                fontSize: 13,
                                color: widget.patient.gender == '男'
                                    ? Colors.blue
                                    : Colors.pink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.patient.age}岁 · ${isChild ? "儿童" : "成人"}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            if (widget.patient.phone != null) ...[
              _buildInfoRow(Icons.phone_outlined, '手机号', widget.patient.phone!),
              const SizedBox(height: 12),
            ],
            _buildInfoRow(
              Icons.calendar_today_outlined,
              '创建时间',
              _formatDate(widget.patient.createdAt),
            ),
            if (widget.patient.note != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.note_outlined, '备注', widget.patient.note!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExamRecordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '检查记录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_examRecords.isNotEmpty)
              Text(
                '共 ${_examRecords.length} 次',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_examRecords.isEmpty)
          _buildEmptyExamState()
        else
          ..._examRecords.map((record) => _buildExamRecordCard(record)),
      ],
    );
  }

  Widget _buildEmptyExamState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            '暂无检查记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '点击下方按钮添加新的检查',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamRecordCard(ExamRecord record) {
    final isDraft = record.isDraft;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDraft ? Colors.orange[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDraft ? Icons.edit_note : Icons.assignment_turned_in,
            color: isDraft ? Colors.orange : Colors.green,
          ),
        ),
        title: Text(
          _getExamTypeName(record.examType.name),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatDate(record.examDate),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDraft)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '草稿',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          // TODO: 查看检查详情
        },
      ),
    );
  }

  String _getExamTypeName(String type) {
    switch (type) {
      case 'standardFullSet':
        return '全套视功能检查';
      case 'binocularVision':
        return '双眼视功能';
      case 'amblyopiaScreening':
        return '弱视筛查';
      case 'asthenopiaAssessment':
        return '视疲劳评估';
      default:
        return '自定义检查';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _navigateToNewExam() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamTypeSelectionPage(
          patientId: widget.patient.id,
        ),
      ),
    ).then((_) => _loadExamRecords());
  }

  void _showEditDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditPatientBottomSheet(
        patient: widget.patient,
        onUpdated: () {
          Navigator.pop(context);
          _loadExamRecords();
        },
        patientUseCases: _patientUseCases,
      ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除患者 "${widget.patient.name}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePatient();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePatient() async {
    try {
      await _patientUseCases.deletePatient.execute(widget.patient.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('患者已删除')),
        );
      }
    } catch (e) {
      _showError('删除失败: $e');
    }
  }
}

class _EditPatientBottomSheet extends StatefulWidget {
  final Patient patient;
  final VoidCallback onUpdated;
  final PatientUseCases patientUseCases;

  const _EditPatientBottomSheet({
    required this.patient,
    required this.onUpdated,
    required this.patientUseCases,
  });

  @override
  State<_EditPatientBottomSheet> createState() => _EditPatientBottomSheetState();
}

class _EditPatientBottomSheetState extends State<_EditPatientBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.patient.name);
  late final _ageController = TextEditingController(text: widget.patient.age.toString());
  late final _phoneController = TextEditingController(text: widget.patient.phone ?? '');
  late final _noteController = TextEditingController(text: widget.patient.note ?? '');
  late String _gender = widget.patient.gender;
  bool _isSaving = false;

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
                    '编辑患者信息',
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
                onPressed: _isSaving ? null : _updatePatient,
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
                    : const Text('保存修改', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updatePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await widget.patientUseCases.updatePatient.execute(
        widget.patient.id,
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
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('患者信息已更新')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败: $e')),
      );
    }
  }
}
