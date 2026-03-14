import 'dart:convert';

enum TravelStatus { pending, loaded, unloaded, missing }

class TravelItemStatus {
  final String boxId;
  final String boxName;
  final String location;
  TravelStatus status;

  TravelItemStatus({
    required this.boxId,
    required this.boxName,
    required this.location,
    this.status = TravelStatus.pending,
  });

  Map<String, dynamic> toMap() => {
    'boxId': boxId,
    'boxName': boxName,
    'location': location,
    'status': status.index,
  };

  factory TravelItemStatus.fromMap(Map<String, dynamic> map) => TravelItemStatus(
    boxId: map['boxId'] ?? '',
    boxName: map['boxName'] ?? '',
    location: map['location'] ?? '',
    status: TravelStatus.values[map['status'] ?? 0],
  );
}

class TravelModel {
  final String id;
  final String name;
  final String fromLocation;
  final String toLocation;
  final DateTime timestamp;
  final List<TravelItemStatus> itemStatuses;
  bool isCompleted;

  TravelModel({
    required this.id,
    required this.name,
    required this.fromLocation,
    required this.toLocation,
    required this.timestamp,
    required this.itemStatuses,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'timestamp': timestamp.toIso8601String(),
      'itemStatuses': jsonEncode(itemStatuses.map((x) => x.toMap()).toList()),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory TravelModel.fromMap(Map<String, dynamic> map) {
    var itemStatusesList = <TravelItemStatus>[];
    if (map['itemStatuses'] != null) {
      if (map['itemStatuses'] is String) {
        var decoded = jsonDecode(map['itemStatuses']);
        itemStatusesList = List<TravelItemStatus>.from(decoded.map((x) => TravelItemStatus.fromMap(x)));
      } else {
        itemStatusesList = List<TravelItemStatus>.from(map['itemStatuses'].map((x) => TravelItemStatus.fromMap(x)));
      }
    }

    return TravelModel(
      id: map['id'],
      name: map['name'] ?? '',
      fromLocation: map['fromLocation'] ?? '',
      toLocation: map['toLocation'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      itemStatuses: itemStatusesList,
      isCompleted: (map['isCompleted'] == 1 || map['isCompleted'] == true),
    );
  }
}
