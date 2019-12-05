import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
import '../platform.dart' show Sound;

class SoundImpl implements Sound {
  final Soundpool _pool = Soundpool(streamType: StreamType.notification);
  final Uri _soundDataPath;
  int _soundId;

  SoundImpl({@required Uri soundDataPath}) : _soundDataPath = soundDataPath {
    _setUp();
  }

  Future<void> play() async {
    if (_soundHasNotBeenLoaded) return;
    unawaited(_pool.play(_soundId));
  }

  Future<void> dispose() async {
    _pool.dispose();
  }

  Future<void> _setUp() async {
    _soundId =
        await rootBundle.load(_soundDataPath.toString()).then(_pool.load);
    assert(_soundId != null);
  }

  bool get _soundHasNotBeenLoaded => _soundId == null;
}
