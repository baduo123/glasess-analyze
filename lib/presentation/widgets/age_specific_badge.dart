import 'package:flutter/material.dart';
import '../../../core/utils/age_utils.dart';

class AgeSpecificBadge extends StatelessWidget {
  final int age;
  final bool showDescription;
  final bool isCompact;
  final VoidCallback? onTap;

  const AgeSpecificBadge({
    super.key,
    required this.age,
    this.showDescription = false,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ageGroup = AgeUtils.getGroup(age);
    final groupName = AgeUtils.getGroupName(age);
    final groupColor = AgeUtils.getGroupColor(age);
    final backgroundColor = AgeUtils.getGroupBackgroundColor(age);

    if (isCompact) {
      return _buildCompactBadge(groupName, groupColor, backgroundColor);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: groupColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: groupColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForGroup(ageGroup),
                    color: groupColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: groupColor,
                        ),
                      ),
                      Text(
                        '$age岁',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.info_outline,
                    color: groupColor.withOpacity(0.6),
                    size: 20,
                  ),
              ],
            ),
            if (showDescription) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AgeUtils.getAgeGroupDescription(age),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBadge(String groupName, Color groupColor, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: groupColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForGroup(AgeUtils.getGroup(age)),
            color: groupColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            groupName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: groupColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForGroup(AgeGroup group) {
    switch (group) {
      case AgeGroup.child:
        return Icons.child_care;
      case AgeGroup.adult:
        return Icons.person;
      case AgeGroup.elderly:
        return Icons.elderly;
    }
  }
}

class AgeGroupChip extends StatelessWidget {
  final int age;
  final VoidCallback? onDeleted;

  const AgeGroupChip({
    super.key,
    required this.age,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final ageGroup = AgeUtils.getGroup(age);
    final groupName = AgeUtils.getGroupName(age);
    final groupColor = AgeUtils.getGroupColor(age);
    final backgroundColor = AgeUtils.getGroupBackgroundColor(age);

    return Chip(
      avatar: Icon(
        _getIconForGroup(ageGroup),
        color: groupColor,
        size: 18,
      ),
      label: Text(
        '$groupName · $age岁',
        style: TextStyle(
          color: groupColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: backgroundColor,
      side: BorderSide(color: groupColor.withOpacity(0.3)),
      deleteIcon: onDeleted != null
          ? Icon(Icons.close, color: groupColor.withOpacity(0.6), size: 18)
          : null,
      onDeleted: onDeleted,
    );
  }

  IconData _getIconForGroup(AgeGroup group) {
    switch (group) {
      case AgeGroup.child:
        return Icons.child_care;
      case AgeGroup.adult:
        return Icons.person;
      case AgeGroup.elderly:
        return Icons.elderly;
    }
  }
}

class AgeBasedInfoCard extends StatelessWidget {
  final int age;

  const AgeBasedInfoCard({
    super.key,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    final ageGroup = AgeUtils.getGroup(age);
    final groupColor = AgeUtils.getGroupColor(age);
    final backgroundColor = AgeUtils.getGroupBackgroundColor(age);
    final notes = AgeUtils.getAgeSpecificNotes(age);

    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: groupColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: groupColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '年龄相关建议',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: groupColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...notes.map((note) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: groupColor.withOpacity(0.6),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class AgeAnalysisLegend extends StatelessWidget {
  const AgeAnalysisLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '年龄分组说明',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              color: AgeUtils.getGroupColorByGroup(AgeGroup.child),
              label: '儿童(0-18岁)',
              description: '视觉发育期，重点关注近视防控',
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              color: AgeUtils.getGroupColorByGroup(AgeGroup.adult),
              label: '成人(19-64岁)',
              description: '视觉功能稳定期，关注用眼健康',
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              color: AgeUtils.getGroupColorByGroup(AgeGroup.elderly),
              label: '老人(65岁以上)',
              description: '视觉衰退期，关注老年眼病',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
