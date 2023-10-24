import 'package:veronauka/kalendar/praznik.dart';

class Dan {
  String objasnjenje;
  DateTime dan;
  List<Praznik> praznici;

  Dan({
    required this.objasnjenje,
    required this.dan,
    required this.praznici,
  });
}
