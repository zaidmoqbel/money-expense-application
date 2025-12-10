class Installment {
  final String id;
  final String bankName;
  final double totalAmount;
  final double monthlyInstallment;
  final int paidInstallments;
  final int totalInstallments;
  final String dueDate;
  final String status; // 'upcoming' or 'paid'
  final String color;
  final String logo;
  final String createdAt;

  Installment({
    required this.id,
    required this.bankName,
    required this.totalAmount,
    required this.monthlyInstallment,
    required this.paidInstallments,
    required this.totalInstallments,
    required this.dueDate,
    required this.status,
    required this.color,
    required this.logo,
    required this.createdAt,
  });

  double get progress => totalInstallments > 0 
      ? (paidInstallments / totalInstallments) * 100 
      : 0;

  int get remainingInstallments => totalInstallments - paidInstallments;
  double get remainingAmount => monthlyInstallment * remainingInstallments;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankName': bankName,
      'totalAmount': totalAmount,
      'monthlyInstallment': monthlyInstallment,
      'paidInstallments': paidInstallments,
      'totalInstallments': totalInstallments,
      'dueDate': dueDate,
      'status': status,
      'color': color,
      'logo': logo,
      'createdAt': createdAt,
    };
  }

  factory Installment.fromMap(Map<String, dynamic> map) {
    return Installment(
      id: map['id'],
      bankName: map['bankName'],
      totalAmount: map['totalAmount'],
      monthlyInstallment: map['monthlyInstallment'],
      paidInstallments: map['paidInstallments'],
      totalInstallments: map['totalInstallments'],
      dueDate: map['dueDate'],
      status: map['status'],
      color: map['color'],
      logo: map['logo'],
      createdAt: map['createdAt'],
    );
  }

  static String generateId() {
    return 'inst-${DateTime.now().millisecondsSinceEpoch}';
  }

  Installment copyWith({
    String? id,
    String? bankName,
    double? totalAmount,
    double? monthlyInstallment,
    int? paidInstallments,
    int? totalInstallments,
    String? dueDate,
    String? status,
    String? color,
    String? logo,
    String? createdAt,
  }) {
    return Installment(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      totalAmount: totalAmount ?? this.totalAmount,
      monthlyInstallment: monthlyInstallment ?? this.monthlyInstallment,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      color: color ?? this.color,
      logo: logo ?? this.logo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}