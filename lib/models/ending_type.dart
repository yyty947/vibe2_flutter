/// Game phase enum (TECH_ARCH §3.1).
enum GamePhase {
  title('TITLE'),
  opening('OPENING'),
  morning('MORNING'),
  afternoon('AFTERNOON'),
  event('EVENT'),
  settlement('SETTLEMENT'),
  ending('ENDING');

  const GamePhase(this.label);
  final String label;
}

/// Ending type enum (TECH_ARCH §4.1).
enum EndingType {
  beDeath('BE_DEATH'),
  beFired('BE_FIRED'),
  geOffer('GE_OFFER'),
  nePeace('NE_PEACE'),
  heKing('HE_KING');

  const EndingType(this.label);
  final String label;
}
