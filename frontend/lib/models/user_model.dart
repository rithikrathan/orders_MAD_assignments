class UserModel {
  final int id;
  final String studentId;
  final String name;
  final String email;
  final double walletBalance;

  UserModel({
    required this.id,
    required this.studentId,
    required this.name,
    required this.email,
    required this.walletBalance,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      studentId: json['student_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'name': name,
      'email': email,
      'wallet_balance': walletBalance,
    };
  }
}
