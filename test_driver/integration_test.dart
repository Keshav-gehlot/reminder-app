import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
      timeout: const Duration(minutes: 10),
      responseDataCallback: (Map<String, dynamic>? data) async {
        final shots = (data?['screenshots'] as Map?) ?? const {};
        await Directory('screenshots').create(recursive: true);
        for (final e in shots.entries) {
          await File('screenshots/${e.key}.png').writeAsBytes(base64Decode(e.value as String));
        }
        stdout.writeln('Saved ${shots.length} screenshots');
      },
    );
