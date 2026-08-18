class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.count,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int? count;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      count: _parseCount(json['count']),
    );
  }

  static int? _parseCount(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
