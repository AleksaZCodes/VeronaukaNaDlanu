import 'package:flutter/material.dart';

import 'package:veronauka/pocetna/pocetna.dart';
import 'package:veronauka/molitve/molitve.dart';
import 'package:veronauka/biblija/biblija.dart';
import 'package:veronauka/dobra_dela/dobra_dela.dart';
import 'package:veronauka/kalendar/kalendar.dart';

List<Stranica> stranice = [
  Stranica(
    naslov: 'Помаже Бог!',
    stranicaBuilder: (idiNaIndeks, latinica) => PopScope(
      canPop: false,
      child: Pocetna(idiNaIndeks: idiNaIndeks, latinica: latinica),
    ),
  ),
  Stranica(
    naslov: 'Молитве',
    stranicaBuilder: (idiNaIndeks, latinica) => PopScope(
      canPop: false,
      child: Molitve(latinica: latinica),
      onPopInvoked: (_) {
        idiNaIndeks(0);
      },
    ),
  ),
  Stranica(
    naslov: 'Свето Писмо',
    stranicaBuilder: (idiNaIndeks, latinica) => PopScope(
      canPop: false,
      child: Biblija(latinica: latinica),
      onPopInvoked: (_) {
        idiNaIndeks(0);
      },
    ),
  ),
  Stranica(
    naslov: 'Календар',
    stranicaBuilder: (idiNaIndeks, latinica) => PopScope(
      canPop: false,
      child: Kalendar(latinica: latinica),
      onPopInvoked: (_) {
        idiNaIndeks(0);
      },
    ),
  ),
  Stranica(
    naslov: 'Добра дела',
    stranicaBuilder: (idiNaIndeks, latinica) => PopScope(
      canPop: false,
      child: DobraDela(latinica: latinica),
      onPopInvoked: (_) {
        idiNaIndeks(0);
      },
    ),
  ),
];

class Stranica {
  String naslov;
  Widget Function(Function(int), bool) stranicaBuilder;

  Stranica({
    required this.naslov,
    required this.stranicaBuilder,
  });
}
