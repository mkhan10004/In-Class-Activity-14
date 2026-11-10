import 'package:cloud_courier/courier_state.dart';
import 'package:flutter_test/flutter_test.dart';

const validData = {'action': 'update_ui', 'asset': 'promo'};

void main() {
  test('valid data updates the announcement and records each handler', () {
    var state = const CourierState();
    for (final path in MessagePath.values) {
      final messageId = 'delivery-${path.index}';
      state = state.receive(
        data: validData,
        path: path,
        notificationTitle: 'Campus event',
        notificationBody: 'The fair starts at 4 PM.',
        messageId: messageId,
      );
      expect(state.title, 'Campus event');
      expect(state.body, 'The fair starts at 4 PM.');
      expect(state.asset, CourierAsset.promo);
      expect(state.path, path);
      expect(state.count, path.index + 1);
      expect(state.messageId, messageId);
      expect(state.diagnostic, isNull);
    }
  });

  final rejectedPayloads = <String, Map<String, dynamic>>{
    'Missing data key: action.': {'asset': 'promo'},
    'Unsupported action. Expected update_ui.': {
      'action': 'other',
      'asset': 'promo',
    },
    'Missing data key: asset.': {'action': 'update_ui'},
    'Unsupported asset. Use default or promo.': {
      'action': 'update_ui',
      'asset': 'unknown',
    },
  };

  for (final entry in rejectedPayloads.entries) {
    test('preserves the announcement when rejected: ${entry.key}', () {
      final accepted = const CourierState().receive(
        data: validData,
        path: MessagePath.backgroundTap,
        notificationTitle: 'Keep this title',
        notificationBody: 'Keep this body',
        messageId: 'accepted',
      );
      final rejected = accepted.receive(
        data: entry.value,
        path: MessagePath.foreground,
        notificationTitle: 'Reject this title',
        notificationBody: 'Reject this body',
        messageId: 'rejected',
      );

      expect(rejected.title, accepted.title);
      expect(rejected.body, accepted.body);
      expect(rejected.asset, accepted.asset);
      expect(rejected.path, MessagePath.foreground);
      expect(rejected.count, 2);
      expect(rejected.messageId, 'rejected');
      expect(rejected.diagnostic, entry.key);
    });
  }

  test('a valid default asset clears the prior diagnostic', () {
    final rejected = const CourierState().receive(
      data: const {},
      path: MessagePath.foreground,
    );
    final recovered = rejected.receive(
      data: const {'action': 'update_ui', 'asset': 'default'},
      path: MessagePath.foreground,
    );

    expect(recovered.asset, CourierAsset.standard);
    expect(recovered.title, 'Campus update');
    expect(recovered.diagnostic, isNull);
  });
}
