/// Ein einzelner Sendungseintrag im Programmfuehrer (EPG) fuer einen Sender.
class EpgProgram {
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;

  EpgProgram({
    required this.title,
    required this.start,
    required this.end,
    this.description,
  });

  bool get isCurrentlyRunning {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }
}
