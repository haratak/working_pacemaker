DateTime beginningDayOfThisMonth(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, 1);

DateTime beginningDayOfNextMonth(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month + 1, 1);

// https://stackoverflow.com/questions/14814941/how-to-find-last-day-of-month
DateTime endingDayOfThisMonth(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month + 1, 0);

DateTime beginningDayOfLastMonth(DateTime dateTime) {
  final b = beginningDayOfThisMonth(dateTime);
  return DateTime(b.year, b.month - 1, 1);
}

DateTime midnightOf(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);

DateTime tomorrowMidnightOf(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day + 1);

DateTime midnightOfSevenDaysAgo(DateTime dateTime) =>
    midnightOf(dateTime.subtract(const Duration(days: 7)));
