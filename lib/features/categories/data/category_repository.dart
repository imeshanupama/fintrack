import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/box_names.dart';
import '../domain/category.dart';
import 'package:uuid/uuid.dart';

class CategoryRepository {
  late Box<Category> _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(BoxNames.categoriesBox)) {
      _box = await Hive.openBox<Category>(BoxNames.categoriesBox);
    } else {
      _box = Hive.box<Category>(BoxNames.categoriesBox);
    }
  }

  // Ensure box is initialized before use
  Box<Category> get box {
    if (!Hive.isBoxOpen(BoxNames.categoriesBox)) {
      throw Exception('Category Box not open');
    }
    return Hive.box<Category>(BoxNames.categoriesBox);
  }

  List<Category> getAll() {
    return box.values.toList();
  }

  Future<void> add(Category category) async {
    await box.put(category.id, category);
  }

  Future<void> update(Category category) async {
    await box.put(category.id, category);
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }

  // Populate default categories if empty
  Future<void> generateDefaultsIfEmpty() async {
    if (box.isNotEmpty) return;

    final defaults = [
      Category(id: const Uuid().v4(), name: 'Food', iconCode: Icons.fastfood.codePoint, colorValue: Colors.orange.value, type: 'expense', isDefault: true),
      Category(id: const Uuid().v4(), name: 'Transport', iconCode: Icons.directions_bus.codePoint, colorValue: Colors.blue.value, type: 'expense', isDefault: true),
      Category(id: const Uuid().v4(), name: 'Shopping', iconCode: Icons.shopping_bag.codePoint, colorValue: Colors.pink.value, type: 'expense', isDefault: true),
      Category(id: const Uuid().v4(), name: 'Bills', iconCode: Icons.receipt_long.codePoint, colorValue: Colors.red.value, type: 'expense', isDefault: true),
      Category(id: const Uuid().v4(), name: 'Entertainment', iconCode: Icons.movie.codePoint, colorValue: Colors.purple.value, type: 'expense', isDefault: true),
      Category(id: const Uuid().v4(), name: 'Health', iconCode: Icons.medical_services.codePoint, colorValue: Colors.teal.value, type: 'expense', isDefault: true),
      Category(id: const Uuid().v4(), name: 'Salary', iconCode: Icons.attach_money.codePoint, colorValue: Colors.green.value, type: 'income', isDefault: true),
      Category(id: const Uuid().v4(), name: 'Others', iconCode: Icons.more_horiz.codePoint, colorValue: Colors.grey.value, type: 'expense', isDefault: true),
    ];

    for (var cat in defaults) {
      await add(cat);
    }
  }
}
