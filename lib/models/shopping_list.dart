import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class ShoppingList {
  final String id;
  final String name;
  final String? userId; // the user who created this list

  ShoppingList({required this.id, required this.name, this.userId});

  factory ShoppingList.fromParse(ParseObject obj) {
    return ShoppingList(
      id: obj.objectId!,
      name: obj.get<String>('name') ?? '',
      userId: obj.get<ParseUser>('user')?.objectId,
    );
  }
}
