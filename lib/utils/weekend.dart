/// Days 6,7, 13,14, 20,21, 27,28 are weekends (TECH_ARCH §2.2 note).
const Set<int> weekendDays = {6, 7, 13, 14, 20, 21, 27, 28};

/// Returns true if [day] falls on a weekend.
bool isWeekend(int day) => weekendDays.contains(day);
