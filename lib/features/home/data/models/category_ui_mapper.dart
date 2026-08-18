import 'category_item.dart';

class CategoryUiMapper {
  CategoryUiMapper._();

  static Map<String, dynamic> categoryToUiMap(CategoryItem category) {
    return {
      'id': category.id,
      'name': category.name,
      'imageUrl': category.imageUrl ?? '',
      'icon': _iconKeyFromName(category.name),
      'count': category.count ?? 0,
    };
  }

  static String _iconKeyFromName(String name) {
    final normalized = name.trim().toLowerCase();
    const iconKeys = {
      'dance': 'dance',
      'singing': 'mic',
      'comedy': 'mask',
      'fitness': 'dumbbell',
      'magic': 'wand',
      'art': 'brush',
      'acting': 'drama',
      'sports': 'trophy',
      'custom': 'sparkle',
    };
    return iconKeys[normalized] ?? 'sparkle';
  }
}
