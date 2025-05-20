import '../models/shopping_list.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final bool purchased;
  final String? listId; // the user who created this list

  ShoppingItem({required this.id, required this.name, required this.quantity, required this.purchased, this.listId});

  factory ShoppingItem.fromParse(ParseObject obj) {
    return ShoppingItem(
      id: obj.objectId!,
      name: obj.get<String>('name') ?? '',
      quantity: obj.get<int>('quantity') ?? 1,
      purchased: obj.get<bool>('purchased') ?? false,
      listId: obj.get<ShoppingList>('listId')?.id,
    );
  }
}