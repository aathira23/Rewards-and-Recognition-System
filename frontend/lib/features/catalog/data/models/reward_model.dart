import '../../domain/entities/reward_entity.dart';

class RewardModel extends RewardEntity {
  RewardModel({
    required super.id,
    required super.name,
    required super.description,
    required super.pointsCost,
    required super.category,
    super.imageUrl,
    required super.stockQuantity,
    required super.isActive,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'],
      name: json['name'] ?? '',
      // Backend uses 'reward_type', frontend uses 'category' as alias
      category: json['reward_type'] ?? json['category'] ?? 'General',
      // Backend uses 'points_required', frontend entity calls it pointsCost
      pointsCost: (json['points_required'] ?? json['points_cost'] ?? 0) as int,
      // description / stock_quantity not always returned by backend
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      stockQuantity: (json['stock_quantity'] ?? 0) as int,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points_cost': pointsCost,
      'category': category,
      'image_url': imageUrl,
      'stock_quantity': stockQuantity,
      'is_active': isActive,
    };
  }
}
