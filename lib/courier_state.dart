enum CourierAsset {
  standard('default', 'assets/images/default.png'),
  promo('promo', 'assets/images/promo.png');

  const CourierAsset(this.payloadValue, this.path);

  final String payloadValue;
  final String path;
}

enum MessagePath {
  foreground('onMessage'),
  backgroundTap('onMessageOpenedApp'),
  coldStartTap('getInitialMessage');

  const MessagePath(this.label);

  final String label;
}

class CourierState {
  const CourierState({
    this.title = 'Ready for campus updates',
    this.body = 'New campus announcements will appear here.',
    this.asset = CourierAsset.standard,
    this.path,
    this.count = 0,
    this.messageId,
    this.diagnostic,
  });

  final String title;
  final String body;
  final CourierAsset asset;
  final MessagePath? path;
  final int count;
  final String? messageId;
  final String? diagnostic;

  CourierState receive({
    required Map<String, dynamic> data,
    required MessagePath path,
    String? messageId,
    String? notificationTitle,
    String? notificationBody,
  }) {
    final nextAsset = switch (data['asset']) {
      'default' => CourierAsset.standard,
      'promo' => CourierAsset.promo,
      _ => null,
    };
    final diagnostic = switch (data) {
      _ when !data.containsKey('action') => 'Missing data key: action.',
      _ when data['action'] != 'update_ui' =>
        'Unsupported action. Expected update_ui.',
      _ when !data.containsKey('asset') => 'Missing data key: asset.',
      _ when nextAsset == null => 'Unsupported asset. Use default or promo.',
      _ => null,
    };

    return CourierState(
      title: diagnostic == null ? notificationTitle ?? 'Campus update' : title,
      body: diagnostic == null
          ? notificationBody ?? 'A new campus announcement arrived.'
          : body,
      asset: diagnostic == null ? nextAsset! : asset,
      path: path,
      count: count + 1,
      messageId: messageId,
      diagnostic: diagnostic,
    );
  }
}
