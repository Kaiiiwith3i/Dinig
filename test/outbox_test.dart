import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dinig/data/services/outbox_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('failed sends stay queued with attempts; delivered ones are removed',
      () async {
    await OutboxService.add({'report': {'id': 'A'}});
    await OutboxService.add({'report': {'id': 'B'}});

    // A fails, B succeeds.
    var delivered = await OutboxService.flush(
      (e) async => (e['report'] as Map)['id'] == 'B',
    );
    expect(delivered, 1);
    expect(await OutboxService.pendingCount(), 1);

    // A now succeeds on the next pass.
    delivered = await OutboxService.flush((e) async => true);
    expect(delivered, 1);
    expect(await OutboxService.pendingCount(), 0);
  });

  test('automatic retries stop at the cap; force retries again', () async {
    await OutboxService.add({'report': {'id': 'A'}});

    for (var i = 0; i < OutboxService.maxAttempts; i++) {
      await OutboxService.flush((e) async => false);
    }
    var calls = 0;
    await OutboxService.flush((e) async {
      calls++;
      return false;
    });
    expect(calls, 0, reason: 'capped entries are skipped automatically');
    expect(await OutboxService.pendingCount(), 1, reason: 'never dropped');

    final delivered =
        await OutboxService.flush((e) async => true, force: true);
    expect(delivered, 1);
    expect(await OutboxService.pendingCount(), 0);
  });

  test('a throwing sender counts as a failed attempt, not a crash', () async {
    await OutboxService.add({'report': {'id': 'A'}});
    final delivered =
        await OutboxService.flush((e) async => throw Exception('offline'));
    expect(delivered, 0);
    expect(await OutboxService.pendingCount(), 1);
  });
}
