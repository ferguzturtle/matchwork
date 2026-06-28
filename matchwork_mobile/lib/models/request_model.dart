class ServiceRequestModel {
  final String id;
  final String providerId;
  final String customerId;
  final String message;
  final String status;
  final String createdAt;
  final String? userName; // Nombre del cliente (se resuelve dinámicamente)

  ServiceRequestModel({
    required this.id,
    required this.providerId,
    required this.customerId,
    required this.message,
    required this.status,
    required this.createdAt,
    this.userName,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id']?.toString() ?? '',
      providerId: json['provider_id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'pendiente',
      createdAt: json['created_at'] as String? ?? '',
      userName: json['user_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'customer_id': customerId,
      'message': message,
      'status': status,
    };
  }

  ServiceRequestModel copyWith({
    String? id,
    String? providerId,
    String? customerId,
    String? message,
    String? status,
    String? createdAt,
    String? userName,
  }) {
    return ServiceRequestModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      customerId: customerId ?? this.customerId,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
    );
  }
}
