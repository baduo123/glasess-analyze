import 'package:flutter/material.dart';
import '../../data/models/patient.dart';
import 'data_entry_page.dart';

class ExamTypeSelectionPage extends StatelessWidget {
  const ExamTypeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final examTypes = [
      _ExamTypeInfo(
        type: ExamType.standardFullSet,
        name: '标准眼科全套',
        description: '包含视力、屈光、眼压、调节、集合、融像等全套检查',
        icon: Icons.medical_services,
        color: Colors.blue,
        estimatedTime: '15-20分钟',
        indicatorCount: 25,
      ),
      _ExamTypeInfo(
        type: ExamType.binocularVision,
        name: '视功能专项',
        description: '专注双眼视功能评估，适合视疲劳和双眼视异常检查',
        icon: Icons.remove_red_eye,
        color: Colors.green,
        estimatedTime: '10-15分钟',
        indicatorCount: 15,
      ),
      _ExamTypeInfo(
        type: ExamType.amblyopiaScreening,
        name: '儿童弱视筛查',
        description: '针对儿童特点的检查组合，早期发现弱视',
        icon: Icons.child_care,
        color: Colors.orange,
        estimatedTime: '10分钟',
        indicatorCount: 12,
      ),
      _ExamTypeInfo(
        type: ExamType.asthenopiaAssessment,
        name: '视疲劳评估',
        description: '针对视疲劳相关指标的综合评估',
        icon: Icons.tired,
        color: Colors.purple,
        estimatedTime: '8-12分钟',
        indicatorCount: 10,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择检查类型'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请选择要进行的检查类型：',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: examTypes.length,
                itemBuilder: (context, index) {
                  final type = examTypes[index];
                  return _ExamTypeCard(
                    info: type,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DataEntryPage(examType: type.type),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamTypeInfo {
  final ExamType type;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String estimatedTime;
  final int indicatorCount;

  _ExamTypeInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.estimatedTime,
    required this.indicatorCount,
  });
}

class _ExamTypeCard extends StatelessWidget {
  final _ExamTypeInfo info;
  final VoidCallback onTap;

  const _ExamTypeCard({
    required this.info,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  info.icon,
                  color: info.color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          info.estimatedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.format_list_numbered, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${info.indicatorCount}项指标',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
