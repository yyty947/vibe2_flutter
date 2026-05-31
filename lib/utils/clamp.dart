/// Clamp a value to [0, 100] (AGENTS.md §4.1 / TECH_ARCH §2.3).
///
/// All writes to energy / kpi / interview / suspicion MUST pass through this.
int clamp(int val, {int min = 0, int max = 100}) {
  if (val < min) return min;
  if (val > max) return max;
  return val;
}
