class Molitva {
  final int id;
  final String naslov;
  final String telo;
  final String izvor;
  bool zakaceno;

  Molitva({
    required this.id,
    required this.naslov,
    required this.telo,
    required this.izvor,
    this.zakaceno = false,
});
}