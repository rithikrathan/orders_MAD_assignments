class SupportTicketModel {
  final int id;
  final int userId;
  final int? orderId;
  final String tokenNumber;
  final String category;
  final String subject;
  final String message;
  final String adminReply;
  final String status; // OPEN, IN_PROGRESS, RESOLVED
  final DateTime createdAt;

  SupportTicketModel({
    required this.id,
    required this.userId,
    this.orderId,
    required this.tokenNumber,
    required this.category,
    required this.subject,
    required this.message,
    required this.adminReply,
    required this.status,
    required this.createdAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      orderId: json['order_id'] as int?,
      tokenNumber: json['token_number'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      adminReply: json['admin_reply'] as String? ?? '',
      status: json['status'] as String? ?? 'OPEN',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
