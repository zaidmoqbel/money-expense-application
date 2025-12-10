class SavingsGoal {
  final String id;
  final String name;
  final double target;
  final double saved;
  final String color;
  final String icon;
  final String createdAt;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.target,
    required this.saved,
    required this.color,
    required this.icon,
    required this.createdAt,
  });

  double get progress => target > 0 ? (saved / target) * 100 : 0;
  double get remaining => target - saved;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target': target,
      'saved': saved,
      'color': color,
      'icon': icon,
      'createdAt': createdAt,
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'],
      name: map['name'],
      target: map['target'],
      saved: map['saved'],
      color: map['color'],
      icon: map['icon'],
      createdAt: map['createdAt'],
    );
  }

  static String generateId() {
    return 'goal-${DateTime.now().millisecondsSinceEpoch}';
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? target,
    double? saved,
    String? color,
    String? icon,
    String? createdAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      target: target ?? this.target,
      saved: saved ?? this.saved,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
