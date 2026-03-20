import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'high_contrast_provider.g.dart';

@riverpod
class HighContrast extends _$HighContrast {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void set(bool value) {
    state = value;
  }
}
