import 'package:hive_flutter/hive_flutter.dart';

abstract class HiveRepository<T extends HiveObject> {
  final Box<T> box;

  HiveRepository(this.box);

  List<T> getAll() {
    return box.values.toList();
  }

  T? get(String id) {
    // Hive keys are usually dynamic, but structured as String id in our models.
    // However, Hive stores objects knowing their key if put with key.
    // We will assume we store objects with their 'id' as the key.
    return box.get(id);
  }

  Future<void> add(String id, T item) async {
    await box.put(id, item);
  }

  Future<void> update(String id, T item) async {
    await box.put(id, item);
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }
}
