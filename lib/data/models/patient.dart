enum ExamType {
  standardFullSet,
  binocularVision,
  amblyopiaScreening,
  asthenopiaAssessment,
  custom,
}

class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String? phone;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.phone,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'phone': phone,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'],
        name: json['name'],
        age: json['age'],
        gender: json['gender'],
        phone: json['phone'],
        note: json['note'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
      );
}

class ExamRecord {
  final String id;
  final String? patientId;
  final ExamType examType;
  final DateTime examDate;
  final DateTime createdAt;
  final bool isDraft;
  final String? pdfPath;
  final Map<String, dynamic>? indicatorValues;

  ExamRecord({
    required this.id,
    this.patientId,
    required this.examType,
    required this.examDate,
    required this.createdAt,
    this.isDraft = false,
    this.pdfPath,
    this.indicatorValues,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'exam_type': examType.name,
        'exam_date': examDate.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'is_draft': isDraft ? 1 : 0,
        'pdf_path': pdfPath,
        'indicator_values': indicatorValues != null ? indicatorValues.toString() : null,
      };

  factory ExamRecord.fromJson(Map<String, dynamic> json) => ExamRecord(
        id: json['id'],
        patientId: json['patient_id'],
        examType: ExamType.values.firstWhere(
          (e) => e.name == json['exam_type'],
          orElse: () => ExamType.standardFullSet,
        ),
        examDate: DateTime.fromMillisecondsSinceEpoch(json['exam_date']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
        isDraft: json['is_draft'] == 1,
        pdfPath: json['pdf_path'],
        indicatorValues: json['indicator_values'] != null
            ? Map<String, dynamic>.from(json['indicator_values'])
            : null,
      );
}
