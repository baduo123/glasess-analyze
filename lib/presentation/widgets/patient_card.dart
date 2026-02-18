import 'package:flutter/material.dart';
import '../../data/models/patient.dart';

/// 患者卡片组件
/// 用于在列表中显示患者信息
class PatientCard extends StatelessWidget {
  final Patient patient;
  final int examCount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PatientCard({
    super.key,
    required this.patient,
    this.examCount = 0,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isChild = patient.age < 18;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 头像
              _buildAvatar(isChild),
              const SizedBox(width: 16),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameRow(theme),
                    const SizedBox(height: 8),
                    _buildInfoRow(theme),
                    if (patient.phone != null) ...[
                      const SizedBox(height: 4),
                      _buildPhoneRow(theme),
                    ],
                  ],
                ),
              ),
              // 箭头
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isChild) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: isChild ? Colors.orange[100] : Colors.blue[100],
      child: Icon(
        isChild ? Icons.child_care : Icons.person,
        color: isChild ? Colors.orange : Colors.blue,
        size: 28,
      ),
    );
  }

  Widget _buildNameRow(ThemeData theme) {
    return Row(
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
    );
  }

  Widget _buildInfoRow(ThemeData theme) {
    return Row(
      children: [
        Text(
          '${patient.age}岁',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.medical_services_outlined,
          size: 14,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          '$examCount 次检查',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneRow(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.phone_outlined,
          size: 14,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          patient.phone!,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 患者卡片骨架屏
class PatientCardSkeleton extends StatelessWidget {
  const PatientCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
