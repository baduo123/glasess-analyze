import 'package:flutter/material.dart';
import '../../data/models/patient.dart';

/// 检查记录卡片组件
class ExamCard extends StatelessWidget {
  final ExamRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExamCard({
    super.key,
    required this.record,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDraft = record.isDraft;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 图标
              _buildStatusIcon(isDraft),
              const SizedBox(width: 16),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getExamTypeName(record.examType.name),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(record.examDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (record.indicatorValues != null &&
                        record.indicatorValues!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildIndicatorSummary(theme),
                    ],
                  ],
                ),
              ),
              // 状态和操作
              _buildTrailingSection(isDraft, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool isDraft) {
    return Container(
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
    );
  }

  Widget _buildIndicatorSummary(ThemeData theme) {
    final count = record.indicatorValues!.length;
    return Row(
      children: [
        Icon(
          Icons.format_list_numbered,
          size: 14,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          '$count 项指标',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailingSection(bool isDraft, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDraft)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
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
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        else
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.outline,
          ),
      ],
    );
  }

  String _getExamTypeName(String type) {
    switch (type) {
      case 'standardFullSet':
        return '全套视功能检查';
      case 'binocularVision':
        return '双眼视功能检查';
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
}

/// 检查记录卡片骨架屏
class ExamCardSkeleton extends StatelessWidget {
  const ExamCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
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
