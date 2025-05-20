import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import './shopping_items_page.dart';
import './login_page.dart';

class ShoppingListsPage extends StatefulWidget {
  const ShoppingListsPage({super.key});
  @override
  State<ShoppingListsPage> createState() => _ShoppingListsPageState();
}

class _ShoppingListsPageState extends State<ShoppingListsPage> {
  List<ParseObject> lists = [];
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    fetchLists();
  }

  // fetch all lists of current user
  Future<void> fetchLists() async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;

    if (currentUser == null) {
      debugPrint('No user logged in');
      setState(() => lists = []);
      return;
    }
    debugPrint('user : $currentUser');

    final listQuery = QueryBuilder<ParseObject>(ParseObject('ShoppingList'))
      ..whereEqualTo('userId', currentUser); // Filter by user
    final ParseResponse result = await listQuery.query();
    if (result.success && result.results!=null) {
      setState(() => lists = result.results as List<ParseObject>);
    }
    else {
      debugPrint('Error fetching lists: ${result.error?.message}');
      setState(() => lists = []); // Optional: clear the list if fetch fails
    }
  }

  // add a list for the current user
  Future<void> addList() async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New List'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => isLoading = true);
              final currentUser = await ParseUser.currentUser() as ParseUser?;
              if (currentUser == null) {
                debugPrint('User not logged in');
                return;
              }
              final obj = ParseObject('ShoppingList')
                ..set('name', nameController.text)
                ..set('userId',currentUser);
              final response = await obj.save();


              if (response.success) {
                await fetchLists();
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

  // confirmation dialog box to delete a list for the user
  void _confirmDelete(ParseObject item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete List'),
        content: const Text('Are you sure you want to delete this list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteList(item);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // delete a list for the user
  Future<void> _deleteList(ParseObject item) async {
    final response = await item.delete();
    if (response.success) {
      setState(() {
        lists.remove(item);
      });
    } else {
      debugPrint('Delete failed: ${response.error?.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: ${response.error?.message ?? 'Unknown error'}')),
      );
    }
  }

  // edit a list for the user
  void _showEditDialog(ParseObject item) {
    final TextEditingController editController = TextEditingController(
      text: item.get<String>('name') ?? '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit List Name'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: 'List Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              item.set('name', editController.text.trim());
              final response = await item.save();
              if (response.success) {
                setState(() {}); // Refresh UI
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit failed: ${response.error?.message ?? 'Unknown error'}')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyShopList'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: addList)
      ],
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () async {
            await ParseUser.currentUser() // get current user
                .then((user) => user?.logout());
            // Navigate back to login page (replace with your actual LoginPage)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginPage()),
            );
          },
        ),
      ),

      body: Stack(
        children: [
          Visibility(
              visible: isLoading,
              child: const Center(child: CircularProgressIndicator()),
          ),
          Visibility(
            visible: (!isLoading && lists.isNotEmpty),
            child: ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final item = lists[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    item.get<String>('name') ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(item);
                      } else if (value == 'delete') {
                        _confirmDelete(item);
                      }
                    },
                    offset: const Offset(-20, 40),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShoppingItemsPage(
                        listId: item.objectId!,
                        listName: item.get<String>('name') ?? '',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          ),

          Visibility(
            visible: (!isLoading && lists.isEmpty),
            child: Center(
              child: Text(
                // text message for no lists
                'No shopping lists found.\nTap the + button to add one!',
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