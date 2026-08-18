import 'category_item.dart';

class CategoriesResponse {
  const CategoriesResponse({
    required this.success,
    this.message,
    required this.data,
    this.page,
    this.limit,
    this.total,
  });

  final bool success;
  final String? message;
  final List<CategoryItem> data;
  final int? page;
  final int? limit;
  final int? total;

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'];
    return CategoriesResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: _parseCategories(json['data']),
      page: _readPaginationInt(pagination, 'page'),
      limit: _readPaginationInt(pagination, 'limit'),
      total: _readPaginationInt(pagination, 'total'),
    );
  }

  static List<CategoryItem> _parseCategories(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => CategoryItem.fromJson(Map<String, dynamic>.from(item)))
        .where((category) => category.id.isNotEmpty && category.name.isNotEmpty)
        .toList();
  }

  static int? _readPaginationInt(dynamic pagination, String key) {
    if (pagination is! Map) return null;
    final value = pagination[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
