class StudioFiltersResponse {
  const StudioFiltersResponse({
    required this.success,
    this.message,
    required this.data,
  });

  final bool success;
  final String? message;
  final StudioFiltersConfig data;

  factory StudioFiltersResponse.fromJson(Map<String, dynamic> json) {
    return StudioFiltersResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] is Map
          ? StudioFiltersConfig.fromJson(Map<String, dynamic>.from(json['data'] as Map))
          : const StudioFiltersConfig.empty(),
    );
  }
}

class StudioFiltersConfig {
  const StudioFiltersConfig({
    required this.filters,
    required this.speeds,
    required this.beautyFilterAvailable,
  });

  const StudioFiltersConfig.empty()
      : filters = const [
          StudioFilterItem(key: 'natural', name: 'Natural'),
          StudioFilterItem(key: 'glow', name: 'Glow'),
          StudioFilterItem(key: 'warm', name: 'Warm'),
          StudioFilterItem(key: 'studio', name: 'Studio'),
          StudioFilterItem(key: 'beauty', name: 'Beauty'),
        ],
        speeds = const [0.5, 1.0, 1.5, 2.0],
        beautyFilterAvailable = true;

  final List<StudioFilterItem> filters;
  final List<double> speeds;
  final bool beautyFilterAvailable;

  factory StudioFiltersConfig.fromJson(Map<String, dynamic> json) {
    final filtersRaw = json['filters'];
    final filtersList = <StudioFilterItem>[];
    if (filtersRaw is List) {
      for (final item in filtersRaw) {
        if (item is Map<String, dynamic>) {
          filtersList.add(StudioFilterItem.fromJson(item));
        } else if (item is Map) {
          filtersList.add(StudioFilterItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final speedsRaw = json['speeds'];
    final speedsList = <double>[];
    if (speedsRaw is List) {
      for (final item in speedsRaw) {
        if (item is num) {
          speedsList.add(item.toDouble());
        } else if (item != null) {
          final parsed = double.tryParse(item.toString());
          if (parsed != null) speedsList.add(parsed);
        }
      }
    }

    return StudioFiltersConfig(
      filters: filtersList.isNotEmpty
          ? filtersList
          : const [
              StudioFilterItem(key: 'natural', name: 'Natural'),
              StudioFilterItem(key: 'glow', name: 'Glow'),
              StudioFilterItem(key: 'warm', name: 'Warm'),
              StudioFilterItem(key: 'studio', name: 'Studio'),
              StudioFilterItem(key: 'beauty', name: 'Beauty'),
            ],
      speeds: speedsList.isNotEmpty ? speedsList : const [0.5, 1.0, 1.5, 2.0],
      beautyFilterAvailable: json['beautyFilterAvailable'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'filters': filters.map((f) => f.toJson()).toList(),
        'speeds': speeds,
        'beautyFilterAvailable': beautyFilterAvailable,
      };
}

class StudioFilterItem {
  const StudioFilterItem({
    required this.key,
    required this.name,
  });

  final String key;
  final String name;

  factory StudioFilterItem.fromJson(Map<String, dynamic> json) {
    return StudioFilterItem(
      key: json['key']?.toString() ?? 'natural',
      name: json['name']?.toString() ?? 'Natural',
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
      };
}
