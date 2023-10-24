import 'package:permission_handler/permission_handler.dart';

class CheckPermission{
Future<bool> permission() async{
  var isStorage = await Permission.storage.status;

  if (!isStorage.isGranted) {
    await Permission.storage.request();
    if (!isStorage.isGranted) {
      return true;
    } else {
      return false;
    }
  } else {
    return true;
  }
}
}