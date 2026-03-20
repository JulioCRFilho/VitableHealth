// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatNotifier)
final chatProvider = ChatNotifierProvider._();

final class ChatNotifierProvider
    extends
        $NotifierProvider<
          ChatNotifier,
          ({bool isTyping, List<ChatMessage> messages})
        > {
  ChatNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatNotifierHash();

  @$internal
  @override
  ChatNotifier create() => ChatNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    ({bool isTyping, List<ChatMessage> messages}) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<({bool isTyping, List<ChatMessage> messages})>(
            value,
          ),
    );
  }
}

String _$chatNotifierHash() => r'aefaa1d78e4b60f61e96ffdcd71161b760e36f19';

abstract class _$ChatNotifier
    extends $Notifier<({bool isTyping, List<ChatMessage> messages})> {
  ({bool isTyping, List<ChatMessage> messages}) build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({bool isTyping, List<ChatMessage> messages}),
              ({bool isTyping, List<ChatMessage> messages})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({bool isTyping, List<ChatMessage> messages}),
                ({bool isTyping, List<ChatMessage> messages})
              >,
              ({bool isTyping, List<ChatMessage> messages}),
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
