import 'home_dashboard_data.dart';

class HomeDashboardResponse {
  const HomeDashboardResponse({
    required this.success,
    this.message,
    required this.data,
  });

  final bool success;
  final String? message;
  final HomeDashboardData data;

  factory HomeDashboardResponse.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    return HomeDashboardResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: dataRaw is Map<String, dynamic>
          ? HomeDashboardData.fromJson(dataRaw)
          : dataRaw is Map
              ? HomeDashboardData.fromJson(Map<String, dynamic>.from(dataRaw))
              : HomeDashboardData.empty(),
    );
  }
}
