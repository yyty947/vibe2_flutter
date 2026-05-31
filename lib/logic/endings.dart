import '../models/ending_type.dart';

/// Daily ending check (TECH_ARCH §4.1).
/// Runs every day INCLUDING Day 30 (Patch-010).
/// Priority order is strictly defined and MUST NOT be reordered.
String? checkDailyEnding(int energy, int kpi, int interview, int suspicion) {
  // Check 1: Energy exhausted → instant death
  if (energy <= 0) return EndingType.beDeath.label;
  // Check 2: KPI bottom → instant firing
  if (kpi <= 0) return EndingType.beFired.label;
  // Check 3: Interview ready → early offer (blocked if suspicion >= 85 — Patch-F02)
  if (interview >= 80 && suspicion < 85) return EndingType.geOffer.label;
  return null;
}

/// Final ending check (TECH_ARCH §4.2).
/// ONLY runs on Day 30, and ONLY after [checkDailyEnding] returns null.
/// Priority order is strictly defined and MUST NOT be reordered.
///
/// Patch-011: BE_FIRED is the catch-all "none of the above".
/// The "KPI < 20" in PRD §5.5 is a typical scenario, NOT a hard condition.
String checkFinalEnding(int energy, int kpi, int interview, int suspicion) {
  // Priority 1: Involution King (Best Ending)
  if (kpi >= 80 && suspicion < 30 && energy >= 20) return EndingType.heKing.label;
  // Priority 2: Successful Jump (Good Ending — blocked if company is watching)
  if (interview >= 60 && suspicion < 70) return EndingType.geOffer.label;
  // Priority 3: Peaceful Parting (Normal Ending)
  if (kpi >= 30 && suspicion < 70 && energy > 0) return EndingType.nePeace.label;
  // Priority 4: Fired (Bad Ending catch-all)
  return EndingType.beFired.label;
}
