class AppSettings {
  final int id;
  final String currency;
  final bool darkMode;
  final bool notifications;
  final String reminderDays;
  final double yearlyExpenseGoal;

  AppSettings({
    this.id = 1,
    required this.currency,
    required this.darkMode,
    required this.notifications,
    required this.reminderDays,
    required this.yearlyExpenseGoal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'currency': currency,
      'darkMode': darkMode ? 1 : 0,
      'notifications': notifications ? 1 : 0,
      'reminderDays': reminderDays,
      'yearlyExpenseGoal': yearlyExpenseGoal,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'],
      currency: map['currency'],
      darkMode: map['darkMode'] == 1,
      notifications: map['notifications'] == 1,
      reminderDays: map['reminderDays'],
      yearlyExpenseGoal: map['yearlyExpenseGoal'],
    );
  }

  AppSettings copyWith({
    int? id,
    String? currency,
    bool? darkMode,
    bool? notifications,
    String? reminderDays,
    double? yearlyExpenseGoal,
  }) {
    return AppSettings(
      id: id ?? this.id,
      currency: currency ?? this.currency,
      darkMode: darkMode ?? this.darkMode,
      notifications: notifications ?? this.notifications,
      reminderDays: reminderDays ?? this.reminderDays,
      yearlyExpenseGoal: yearlyExpenseGoal ?? this.yearlyExpenseGoal,
    );
  }
}
