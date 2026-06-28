class ProviderModel {
  final String id;
  final String name;
  final String image;
  final String profession;
  final String category;
  final String subcategory;
  final double rating;
  final String status;
  final double lat;
  final double lng;
  final String icon;
  final String createdAt;

  ProviderModel({
    required this.id,
    required this.name,
    required this.image,
    required this.profession,
    required this.category,
    required this.subcategory,
    required this.rating,
    required this.status,
    required this.lat,
    required this.lng,
    required this.icon,
    required this.createdAt,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Prestador General',
      image: json['image'] as String? ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
      profession: json['profession'] as String? ?? 'Prestador General',
      category: json['category'] as String? ?? 'construccion',
      subcategory: json['subcategory'] as String? ?? 'gasfiteria',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      status: json['status'] as String? ?? 'En línea',
      lat: (json['lat'] as num?)?.toDouble() ?? -33.4489,
      lng: (json['lng'] as num?)?.toDouble() ?? -70.6693,
      icon: json['icon'] as String? ?? 'plumbing',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'profession': profession,
      'category': category,
      'subcategory': subcategory,
      'rating': rating,
      'status': status,
      'lat': lat,
      'lng': lng,
      'icon': icon,
    };
  }

  ProviderModel copyWith({
    String? id,
    String? name,
    String? image,
    String? profession,
    String? category,
    String? subcategory,
    double? rating,
    String? status,
    double? lat,
    double? lng,
    String? icon,
    String? createdAt,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      profession: profession ?? this.profession,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
