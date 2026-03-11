import 'item_model.dart';
import '../services/database_service.dart';

class BoxModel {
  final String id;
  String? uuid;
  String? name;
  String? location;
  int? colorValue;
  final DateTime createdDate;
  List<ItemModel> items;
  DateTime? lastAccessedDate;
  int? capacity;
  int? orderIndex;
  String? category;
  String? imagePath;
  bool isFavorite;

  BoxModel({
    required this.id,
    this.uuid,
    this.name,
    this.location,
    this.colorValue,
    required this.createdDate,
    this.category = 'Other',
    this.imagePath,
    this.isFavorite = false,
    List<ItemModel>? items,
    DateTime? lastAccessedDate,
    this.capacity,
    this.orderIndex,
  })  : items = items ?? [],
        lastAccessedDate = lastAccessedDate ?? DateTime.now();

  int get itemCount => items.length;

  int get totalQuantity =>
      items.where((i) => i != null).fold(0, (sum, item) => sum + (item.quantity ?? 0));

  Future<void> updateAccess() async {
    lastAccessedDate = DateTime.now();
    await save();
  }

  Future<void> save() async {
    await DatabaseService.updateBox(this);
  }

  Future<void> delete() async {
    await DatabaseService.deleteBox(id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'location': location,
      'colorValue': colorValue,
      'createdDate': createdDate.toIso8601String(),
      'lastAccessedDate': lastAccessedDate?.toIso8601String(),
      'capacity': capacity,
      'orderIndex': orderIndex,
      'category': category,
      'imagePath': imagePath,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory BoxModel.fromMap(Map<String, dynamic> map, {List<ItemModel>? items}) {
    return BoxModel(
      id: map['id'],
      uuid: map['uuid'],
      name: map['name'],
      location: map['location'],
      colorValue: map['colorValue'],
      createdDate: DateTime.tryParse(map['createdDate']) ?? DateTime.now(),
      lastAccessedDate: map['lastAccessedDate'] != null ? DateTime.tryParse(map['lastAccessedDate']) : null,
      capacity: map['capacity'],
      orderIndex: map['orderIndex'],
      category: map['category'],
      imagePath: map['imagePath'],
      isFavorite: map['isFavorite'] == 1,
      items: items ?? [],
    );
  }
}
