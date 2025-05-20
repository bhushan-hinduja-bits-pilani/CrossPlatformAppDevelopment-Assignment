import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import './constants.dart';

Future<void> initializeParse() async {
  await Parse().initialize(
    keyApplicationId,
    keyParseServerUrl,
    clientKey: keyClientKey,
    autoSendSessionId: true,
  );
}
