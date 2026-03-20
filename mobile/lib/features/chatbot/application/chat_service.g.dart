// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatService)
final chatServiceProvider = ChatServiceProvider._();

final class ChatServiceProvider
    extends $FunctionalProvider<ChatService, ChatService, ChatService>
    with $Provider<ChatService> {
  ChatServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatServiceHash();

  @$internal
  @override
  $ProviderElement<ChatService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatService create(Ref ref) {
    return chatService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatService>(value),
    );
  }
}

String _$chatServiceHash() => r'b9998fa2d42956e2e80a1f29370868db8f5e1c22';
