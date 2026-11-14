import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/config/app_config.dart';

void main() {
  test('uses the production API URL by default', () {
    expect(AppConfig.apiBaseUrl, 'https://lexi-backend-z0zy.onrender.com/api');
  });

  test('uses a shorter timeout for standard requests', () {
    expect(AppConfig.requestTimeout, const Duration(seconds: 15));
    expect(AppConfig.aiRequestTimeout, const Duration(seconds: 60));
  });
}
