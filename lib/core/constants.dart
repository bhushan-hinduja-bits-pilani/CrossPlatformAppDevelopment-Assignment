import 'package:flutter_dotenv/flutter_dotenv.dart';

final String keyApplicationId = dotenv.env['PARSE_APP_ID'] ?? '';
final String keyClientKey = dotenv.env['PARSE_CLIENT_KEY'] ?? '';
final String keyParseServerUrl = dotenv.env['PARSE_SERVER_URL'] ?? '';
