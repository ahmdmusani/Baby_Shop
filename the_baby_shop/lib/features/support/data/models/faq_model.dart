class FaqItemModel {
  final String id;
  final String question;
  final String answer;
  final int order;

  FaqItemModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.order,
  });

  factory FaqItemModel.fromMap(Map<String, dynamic> map, String docId) {
    return FaqItemModel(
      id: docId,
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'order': order,
    };
  }
}
