class FaqItem {
  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    this.category = 'General',
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String question;
  final String answer;
  final String category;
  final int sortOrder;
  final bool isActive;

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString().trim() ?? '',
      answer: json['answer']?.toString().trim() ?? '',
      category: json['category']?.toString().trim() ?? 'General',
      sortOrder: (json['sortOrder'] is num)
          ? (json['sortOrder'] as num).toInt()
          : (int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0),
      isActive: json['isActive'] == true || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'category': category,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };
}
