import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/category.dart';
import '../data/category_repository.dart';

final categoryRepositoryProvider = Provider((ref) => CategoryRepository());

final categoryProvider = NotifierProvider<CategoryNotifier, List<Category>>(() {
  return CategoryNotifier();
});

class CategoryNotifier extends Notifier<List<Category>> {
  late CategoryRepository _repository;

  @override
  List<Category> build() {
    _repository = ref.watch(categoryRepositoryProvider);
    // Determine if we need defaults here or if repository handles it.
    // Since main.dart opens the box, accessing it is safe.
    // However, generating defaults might need to happen once.
    // We can do it here synchronously if the box is open.
    _checkDefaults();
    return _repository.getAll();
  }

  Future<void> _checkDefaults() async {
    // This is async, so we can't await it in build().
    // Ideally defaults are generated in a bootstrapper.
    // But for now, let's just trigger it side-effect style or assume main.dart did it?
    // main.dart didn't call generateDefaults.
    // We can just fire and forget, or better, make this AsyncNotifier?
    // If we make it AsyncNotifier, the UI has to handle loading state.
    // To keep UI simple (List<Category>), let's assume valid state.
    await _repository.generateDefaultsIfEmpty(); 
    state = _repository.getAll();
  }

  Future<void> addCategory(Category category) async {
    await _repository.add(category);
    state = _repository.getAll();
  }

  Future<void> updateCategory(Category category) async {
    await _repository.update(category);
    state = _repository.getAll();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.delete(id);
    state = _repository.getAll();
  }
}
