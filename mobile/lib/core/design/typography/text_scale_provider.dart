import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'text_scale_provider.g.dart';

@riverpod
class TextScale extends _$TextScale {
  @override
  double build() => 1.0;

  void setScale(double scale) {
    state = scale;
  }

  void reset() {
    state = 1.0;
  }
}
