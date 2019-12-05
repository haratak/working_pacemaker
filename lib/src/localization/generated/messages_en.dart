// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static m0(minutes) => "${minutes} minutes";

  static m1(durationMessage) => "Select ${durationMessage}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function>{
        "Breaking": MessageLookupByLibrary.simpleMessage("Breaking"),
        "Breaking Duration":
            MessageLookupByLibrary.simpleMessage("Breaking Duration"),
        "Logs will be kept for a period of one year.":
            MessageLookupByLibrary.simpleMessage(
                "Logs will be kept for a period of one year."),
        "Reset": MessageLookupByLibrary.simpleMessage("Reset"),
        "Settings": MessageLookupByLibrary.simpleMessage("Settings"),
        "Seven Days": MessageLookupByLibrary.simpleMessage("Seven Days"),
        "Show All Logs": MessageLookupByLibrary.simpleMessage("Show All Logs"),
        "This Month": MessageLookupByLibrary.simpleMessage("This Month"),
        "Today": MessageLookupByLibrary.simpleMessage("Today"),
        "Working": MessageLookupByLibrary.simpleMessage("Working"),
        "Working Duration":
            MessageLookupByLibrary.simpleMessage("Working Duration"),
        "Your Performance":
            MessageLookupByLibrary.simpleMessage("Your Performance"),
        "minutes": m0,
        "selectDurationOf": m1
      };
}
