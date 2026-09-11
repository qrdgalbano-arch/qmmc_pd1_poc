class Prescription {
  const Prescription({
    required this.id,
    required this.exerciseId,
    required this.repetitionsTarget,
    required this.durationLimitSeconds,
    required this.scheduledDays,
    required this.isActive,
  });

  final int id;
  final int exerciseId;
  final int repetitionsTarget;
  final int durationLimitSeconds;
  final String scheduledDays;
  final bool isActive;

  String get formattedDuration {
    if (durationLimitSeconds < 60) {
      return '$durationLimitSeconds seconds';
    }

    final minutes = durationLimitSeconds ~/ 60;
    final seconds = durationLimitSeconds % 60;

    if (seconds == 0) {
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }

    return '$minutes min $seconds sec';
  }

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] as int,
      exerciseId: json['exercise_id'] as int,
      repetitionsTarget: json['repetitions_target'] as int,
      durationLimitSeconds: json['duration_limit_seconds'] as int,
      scheduledDays: json['scheduled_days'] as String,
      isActive: json['is_active'] as bool,
    );
  }
}