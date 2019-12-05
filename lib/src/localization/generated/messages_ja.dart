// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ja locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ja';

  static m0(minutes) => "${minutes}分";

  static m1(durationMessage) => "${durationMessage}を選択";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function>{
        "Breaking": MessageLookupByLibrary.simpleMessage("休憩中"),
        "Breaking Duration": MessageLookupByLibrary.simpleMessage("休憩時間"),
        "Logs will be kept for a period of one year.":
            MessageLookupByLibrary.simpleMessage("記録は一年間保存されます。"),
        "Reset": MessageLookupByLibrary.simpleMessage("リセット"),
        "Settings": MessageLookupByLibrary.simpleMessage("設定"),
        "Seven Days": MessageLookupByLibrary.simpleMessage("７日間"),
        "Show All Logs": MessageLookupByLibrary.simpleMessage("すべての記録を見る"),
        "This Month": MessageLookupByLibrary.simpleMessage("今月"),
        "Today": MessageLookupByLibrary.simpleMessage("今日"),
        "Working": MessageLookupByLibrary.simpleMessage("作業中"),
        "Working Duration": MessageLookupByLibrary.simpleMessage("作業時間"),
        "Your Performance": MessageLookupByLibrary.simpleMessage("あなたの作業時間"),
        "minutes": m0,
        "selectDurationOf": m1
      };
}
