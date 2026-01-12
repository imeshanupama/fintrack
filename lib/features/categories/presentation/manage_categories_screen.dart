import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../domain/category.dart';
import 'category_provider.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Categories', style: GoogleFonts.outfit()),
      ),
      body: categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: category.color.withOpacity(0.2),
                      child: Icon(category.icon, color: category.color),
                    ),
                    title: Text(category.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: Text(category.type.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                         if (value == 'edit') {
                           _showCategoryDialog(context, ref, category: category);
                         } else if (value == 'delete') {
                           if (category.isDefault) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete default categories')));
                             return;
                           }
                           _deleteCategory(context, ref, category.id);
                         }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'delete', 
                          enabled: !category.isDefault,
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deleteCategory(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(categoryProvider.notifier).deleteCategory(id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, {Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    String type = category?.type ?? 'expense';
    IconData selectedIcon = category?.icon ?? Icons.category;
    Color selectedColor = category?.color ?? Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(category == null ? 'New Category' : 'Edit Category'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'expense', child: Text('Expense')),
                      DropdownMenuItem(value: 'income', child: Text('Income')),
                    ],
                    onChanged: (val) => setState(() => type = val!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Color: '),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Pick a color'),
                              content: SingleChildScrollView(
                                child: BlockPicker(
                                  pickerColor: selectedColor,
                                  onColorChanged: (color) {
                                    setState(() => selectedColor = color);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(backgroundColor: selectedColor, radius: 16),
                      ),
                      const SizedBox(width: 20),
                      const Text('Icon: '),
                      IconButton(
                        icon: Icon(selectedIcon),
                        onPressed: () {
                           // Simple icon picker (could be expanded)
                           _showIconPicker(context, (icon) {
                             setState(() => selectedIcon = icon);
                           });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (nameController.text.isEmpty) return;
                  
                  final newCategory = Category(
                    id: category?.id ?? const Uuid().v4(),
                    name: nameController.text,
                    iconCode: selectedIcon.codePoint,
                    colorValue: selectedColor.value,
                    type: type,
                    isDefault: category?.isDefault ?? false,
                  );

                  if (category == null) {
                    ref.read(categoryProvider.notifier).addCategory(newCategory);
                  } else {
                    ref.read(categoryProvider.notifier).updateCategory(newCategory);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showIconPicker(BuildContext context, Function(IconData) onIconPicked) {
    final icons = [
      Icons.fastfood, Icons.directions_bus, Icons.shopping_bag, Icons.receipt_long,
      Icons.movie, Icons.medical_services, Icons.attach_money, Icons.more_horiz,
      Icons.home, Icons.pets, Icons.school, Icons.fitness_center, Icons.flight,
      Icons.restaurant, Icons.coffee, Icons.local_gas_station, Icons.work,
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              return IconButton(
                icon: Icon(icons[index]),
                onPressed: () {
                  onIconPicked(icons[index]);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
