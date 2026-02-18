class RewardEntity {
  final int id;
  final String name;
  final String description;
  final int pointsCost;
  final String category;
  final String? imageUrl;
  final int stockQuantity;
  final bool isActive;

  RewardEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.category,
    this.imageUrl,
    required this.stockQuantity,
    required this.isActive,
  });
}
