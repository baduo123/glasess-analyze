import 'package:flutter/material.dart';

enum AgeGroup {
  child,
  adult,
  elderly,
}

class AgeUtils {
  static const Map<AgeGroup, String> _groupNames = {
    AgeGroup.child: '儿童(0-18岁)',
    AgeGroup.adult: '成人(19-64岁)',
    AgeGroup.elderly: '老人(65岁以上)',
  };

  static const Map<AgeGroup, int> _groupIds = {
    AgeGroup.child: 1,
    AgeGroup.adult: 2,
    AgeGroup.elderly: 3,
  };

  static const Map<AgeGroup, int> _groupMinAges = {
    AgeGroup.child: 0,
    AgeGroup.adult: 19,
    AgeGroup.elderly: 65,
  };

  static const Map<AgeGroup, int> _groupMaxAges = {
    AgeGroup.child: 18,
    AgeGroup.adult: 64,
    AgeGroup.elderly: 150,
  };

  static const Map<AgeGroup, Color> _groupColors = {
    AgeGroup.child: Color(0xFF4CAF50),
    AgeGroup.adult: Color(0xFF2196F3),
    AgeGroup.elderly: Color(0xFFFF9800),
  };

  static const Map<AgeGroup, Color> _groupBackgroundColors = {
    AgeGroup.child: Color(0xFFE8F5E9),
    AgeGroup.adult: Color(0xFFE3F2FD),
    AgeGroup.elderly: Color(0xFFFFF3E0),
  };

  static AgeGroup getGroup(int age) {
    if (age < 0) {
      throw ArgumentError('年龄不能为负数');
    }
    if (age <= 18) {
      return AgeGroup.child;
    } else if (age <= 64) {
      return AgeGroup.adult;
    } else {
      return AgeGroup.elderly;
    }
  }

  static String getGroupName(int age) {
    final group = getGroup(age);
    return _groupNames[group]!;
  }

  static int getAgeGroupId(int age) {
    final group = getGroup(age);
    return _groupIds[group]!;
  }

  static AgeGroup getGroupById(int groupId) {
    for (final entry in _groupIds.entries) {
      if (entry.value == groupId) {
        return entry.key;
      }
    }
    throw ArgumentError('无效的年龄组ID: $groupId');
  }

  static String getGroupNameById(int groupId) {
    final group = getGroupById(groupId);
    return _groupNames[group]!;
  }

  static String getGroupNameByGroup(AgeGroup group) {
    return _groupNames[group]!;
  }

  static int getMinAge(AgeGroup group) {
    return _groupMinAges[group]!;
  }

  static int getMaxAge(AgeGroup group) {
    return _groupMaxAges[group]!;
  }

  static Color getGroupColor(int age) {
    final group = getGroup(age);
    return _groupColors[group]!;
  }

  static Color getGroupColorByGroup(AgeGroup group) {
    return _groupColors[group]!;
  }

  static Color getGroupBackgroundColor(int age) {
    final group = getGroup(age);
    return _groupBackgroundColors[group]!;
  }

  static Color getGroupBackgroundColorByGroup(AgeGroup group) {
    return _groupBackgroundColors[group]!;
  }

  static bool isChild(int age) {
    return getGroup(age) == AgeGroup.child;
  }

  static bool isAdult(int age) {
    return getGroup(age) == AgeGroup.adult;
  }

  static bool isElderly(int age) {
    return getGroup(age) == AgeGroup.elderly;
  }

  static double calculateAMPAgeBased(int age) {
    final calculatedAmp = 18.5 - 0.3 * age;
    return calculatedAmp.clamp(0.0, 20.0);
  }

  static double getExpectedVA(int age) {
    final group = getGroup(age);
    switch (group) {
      case AgeGroup.child:
        return 1.0;
      case AgeGroup.adult:
        return 1.0;
      case AgeGroup.elderly:
        return 0.8;
    }
  }

  static String getAgeGroupDescription(int age) {
    final group = getGroup(age);
    switch (group) {
      case AgeGroup.child:
        return '处于视觉发育期，重点关注近视防控和弱视筛查';
      case AgeGroup.adult:
        return '视觉功能稳定期，关注用眼健康和定期复查';
      case AgeGroup.elderly:
        return '视觉功能衰退期，需关注白内障、青光眼等老年眼病';
    }
  }

  static List<String> getAgeSpecificNotes(int age) {
    final group = getGroup(age);
    switch (group) {
      case AgeGroup.child:
        return [
          '建议每6个月进行一次视力检查',
          '注意用眼卫生，控制电子产品使用时间',
          '户外活动有助于预防近视',
        ];
      case AgeGroup.adult:
        return [
          '建议每年进行一次全面的眼科检查',
          '注意用眼卫生，避免长时间近距离用眼',
          '40岁以上建议关注老花眼的发生',
        ];
      case AgeGroup.elderly:
        return [
          '建议每半年进行一次全面的眼科检查',
          '重点关注白内障、青光眼、黄斑变性等眼病',
          '出现视力突然下降需立即就医',
        ];
    }
  }
}
