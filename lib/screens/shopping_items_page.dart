import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class ShoppingItemsPage extends StatefulWidget {
  final String listId;
  final String listName;
  const ShoppingItemsPage({super.key, required this.listId, required this.listName});
  @override
  State<ShoppingItemsPage> createState() => _ShoppingItemsPageState();
}

class _ShoppingItemsPageState extends State<ShoppingItemsPage> {
  List<ParseObject> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  // get all items of a list
  Future<void> fetchItems() async {
    setState(() => isLoading = true);
    final listPointer = ParseObject('ShoppingList')..objectId = widget.listId;
    final listQuery = QueryBuilder<ParseObject>(ParseObject('ShoppingItem'))
      ..whereEqualTo('listId', listPointer);
    final ParseResponse result = await listQuery.query();
    if (result.success && result.results != null) {
      setState(() {
        items = result.results as List<ParseObject>;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }


  // add an item to list
  Future<void> addItem() async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 20),
            TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => isLoading = true);
              final item = ParseObject('ShoppingItem')
                ..set('name', nameController.text)
                ..set('quantity', int.tryParse(qtyController.text) ?? 1)
                ..set('purchased', false)
                ..set('listId', ParseObject('ShoppingList')..objectId = widget.listId);

              final response = await item.save();
              if (response.success) {
                await fetchItems();
              } else {
                debugPrint('Failed to save list: ${response.error?.message}');
              }
              setState(() => isLoading = false);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  // enable or disable purchased checkbox
  Future<void> togglePurchased(ParseObject item) async {
    // Optimistically update UI
    final currentState = item.get<bool>('purchased') ?? false;
    setState(() {
      item.set('purchased', !currentState);
    });

    // Save to backend
    final response = await item.save();

    // If save fails, revert and show message
    if (!response.success) {
      setState(() {
        item.set('purchased', currentState); // revert
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update item: ${response.error?.message}')),
      );
    }
  }

  // edit name,quantity of an item
  void _editItem(BuildContext context, ParseObject item) async {
    final TextEditingController nameController =
    TextEditingController(text: item.get<String>('name') ?? '');
    final TextEditingController quantityController =
    TextEditingController(text: item.get<int>('quantity')?.toString() ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'quantity': quantityController.text.trim()
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result['name']!.isNotEmpty) {
      item.set<String>('name', result['name']!);
      item.set<int>('quantity', int.tryParse(result['quantity'] ?? '') ?? 1); // default 1 if invalid
      final response = await item.save();

      if (response.success) {
        setState(() {}); // Refresh UI
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update item: ${response.error?.message}')),
        );
      }
    }
  }

  // delete an item from list
  void _confirmDeleteItem(BuildContext context, ParseObject item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final response = await item.delete();

              if (response.success) {
                setState(() => items.remove(item));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete item: ${response.error?.message}')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.listName), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: addItem)
      ]),
      body: Stack(
        children: [

          Visibility(
              visible: isLoading,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ),
          Visibility(
            visible: (!isLoading && items.isNotEmpty),
            child : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Checkbox(
                      value: item.get<bool>('purchased') ?? false,
                      onChanged: (_) => togglePurchased(item),
                      activeColor: Colors.indigo,
                    ),
                    title: Text(
                      item.get<String>('name') ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        decoration: (item.get<bool>('purchased') ?? false)
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text('Qty: ${item.get<int>('quantity') ?? 1}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editItem(context, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteItem(context, item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Visibility(
            visible: (!isLoading && items.isEmpty),
            child: Center(
              // text message for empty list
              child: Text(
                'No shopping items found.\nTap the + button to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ),
          ),

        ],
      )
    );
  }
}