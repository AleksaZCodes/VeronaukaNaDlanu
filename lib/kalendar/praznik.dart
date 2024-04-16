class Praznik {
  String naslov;
  bool crvenoSlovo;
  bool crnoSlovo;
  String opis;
  String izvorOpisa;

  Praznik({
    required this.naslov,
    this.crvenoSlovo = false,
    this.crnoSlovo = false,
    this.opis = '',
    this.izvorOpisa = '',
  });
}
