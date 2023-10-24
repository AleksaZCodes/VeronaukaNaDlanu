import 'package:flutter/material.dart';

import 'package:veronauka/pocetna/pocetna.dart';
import 'package:veronauka/molitve/molitve.dart';
import 'package:veronauka/biblija/biblija.dart';
import 'package:veronauka/dobra_dela/dobra_dela.dart';
import 'package:veronauka/kalendar/kalendar.dart';

List<Stranica> stranice = [
  Stranica(
    naslov: 'Помаже Бог!',
    stranicaBuilder: (idiNaIndeks) => Pocetna(idiNaIndeks: idiNaIndeks),
  ),
  Stranica(
    naslov: 'Молитве',
    stranicaBuilder: (idiNaIndeks) => Molitve(),
  ),
  Stranica(
    naslov: 'Свето Писмо',
    stranicaBuilder: (idiNaIndeks) => Biblija(),
  ),
  Stranica(
    naslov: 'Календар',
    stranicaBuilder: (idiNaIndeks) => Kalendar(),
  ),
  Stranica(
    naslov: 'Добра дела',
    stranicaBuilder: (idiNaIndeks) => DobraDela(),
  ),
];

class Stranica {
  String naslov;
  Widget Function(Function(int)) stranicaBuilder;

  Stranica({
    required this.naslov,
    required this.stranicaBuilder,
  });
}