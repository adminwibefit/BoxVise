import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/box_model.dart';
import '../lib/models/item_model.dart';
import '../lib/providers/inventory_provider.dart';

void main() {
  test('Check property getters', () {
    final provider = InventoryProvider();
    final box = BoxModel(
      id: '1',
      name: 'Test',
      location: 'Loc',
      colorValue: 123,
      createdDate: DateTime.now(),
      category: 'Cat',
    );
    provider.boxes.add(box);
    
    expect(provider.allLocations, isNotNull);
    expect(provider.allTags, isNotNull);
    expect(provider.totalCategories, isNotNull);
  });
}
