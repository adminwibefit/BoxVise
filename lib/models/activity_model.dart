class ActivityModel {
  final String id;
  final String type; // action/type: box_created, item_added
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String? relatedId; // item_id / box_id

  ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.relatedId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'timestamp': timestamp.toIso8601String(),
      'relatedId': relatedId,
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'],
      type: map['type'],
      title: map['title'],
      subtitle: map['subtitle'],
      timestamp: DateTime.tryParse(map['timestamp']) ?? DateTime.now(),
      relatedId: map['relatedId'],
    );
  }
}
