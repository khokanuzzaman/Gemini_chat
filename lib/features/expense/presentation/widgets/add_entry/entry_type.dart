/// খরচ or আয় — the two things the add sheet records.
enum EntryType {
  expense('খরচ'),
  income('আয়');

  const EntryType(this.label);
  final String label;
}
