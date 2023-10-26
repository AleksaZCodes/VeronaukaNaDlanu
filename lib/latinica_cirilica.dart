List<String> latinica = [
  'nj', 'lj', 'NJ', 'LJ',
  'a', 'b', 'c', 'č', 'ć', 'd', 'đ', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
  'm', 'n', 'o', 'p', 'r', 's', 'š', 't', 'u', 'v', 'z', 'ž',
  'A', 'B', 'C', 'Č', 'Ć', 'D', 'Đ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L',
  'M', 'N', 'O', 'P', 'R', 'S', 'Š', 'T', 'U', 'V', 'Z', 'Ž',
];

List<String> cirilica = [
  'њ', 'љ', 'Њ', 'Љ',
  'а', 'б', 'ц', 'ч', 'ћ', 'д', 'ђ', 'е', 'ф', 'г', 'х', 'и', 'ј', 'к', 'л',
  'м', 'н', 'о', 'п', 'р', 'с', 'ш', 'т', 'у', 'в', 'з', 'ж',
  'А', 'Б', 'Ц', 'Ч', 'Ћ', 'Д', 'Ђ', 'Е', 'Ф', 'Г', 'Х', 'И', 'Ј', 'К', 'Л',
  'М', 'Н', 'О', 'П', 'Р', 'С', 'Ш', 'Т', 'У', 'В', 'З', 'Ж',
];

String latinicaCirilica(String tekst) {
  for (int i = 0; i < latinica.length; i++) {
    tekst = tekst.replaceAll(latinica[i], cirilica[i]);
  }
  return tekst;
}

String cirilicaLatinica(String tekst) {
  for (int i = 0; i < cirilica.length; i++) {
    tekst = tekst.replaceAll(cirilica[i], latinica[i]);
  }
  return tekst;
}
