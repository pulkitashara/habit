import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TestUtils {
  static void setupMockPathProvider() {
    const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

    pathProviderChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getApplicationDocumentsDirectory':
          return '/mocked/app/documents';
        case 'getTemporaryDirectory':
          return '/mocked/temp';
        case 'getExternalStorageDirectory':
          return '/mocked/external';
        default:
          return null;
      }
    });
  }

  static Future<void> setupHive() async {
    await Hive.initFlutter();

    // Open all required boxes
    final boxes = ['habits', 'habitProgress', 'users'];
    for (final boxName in boxes) {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
    }
  }

  static Future<void> cleanupHive() async {
    await Hive.deleteFromDisk();
  }

  static void cleanupPathProvider() {
    const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    pathProviderChannel.setMockMethodCallHandler(null);
  }
}
