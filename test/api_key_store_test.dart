import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarim_hayvancilik_app/services/api_key_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('there is no bundled default credential', () async {
    expect(await ApiKeyStore.read(), isNull);
  });

  test(
    'legacy personal key migrates and the plaintext copy is removed',
    () async {
      SharedPreferences.setMockInitialValues({
        'openai_api_key': ' personal-test-key ',
      });
      expect(await ApiKeyStore.read(), 'personal-test-key');
      expect(
        (await SharedPreferences.getInstance()).containsKey('openai_api_key'),
        isFalse,
      );
      expect(
        await const FlutterSecureStorage().read(key: 'openai_api_key'),
        'personal-test-key',
      );
    },
  );

  test('updated and removed keys take effect on the next read', () async {
    await ApiKeyStore.write('first-test-key');
    await ApiKeyStore.write('new-test-key');
    expect(await ApiKeyStore.read(), 'new-test-key');
    await ApiKeyStore.clear();
    expect(await ApiKeyStore.read(), isNull);
  });
}
