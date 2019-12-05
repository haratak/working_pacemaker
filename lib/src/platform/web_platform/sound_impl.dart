import 'package:meta/meta.dart';

import '../platform.dart' show Sound;

// As of Flutter 1.9, Sky Engine doesn't expose dart:web_audio.
// Without this package, it cannot load audio resource.
// Therefore, currently this object has no effect.
// TODO: Try implementing with JS Interop.
class SoundImpl implements Sound {
  SoundImpl({@required Uri soundDataPath});
  Future<void> play() async {}
  Future<void> dispose() async {}
}
