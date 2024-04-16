import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:veronauka/biblija/biblija.dart';
import 'package:veronauka/clanci/clanci.dart';
import 'package:veronauka/dobra_dela/dobra_dela.dart';

import 'package:veronauka/kalendar/praznik.dart';
import 'package:veronauka/kalendar/dan.dart';
import 'package:veronauka/latinica_cirilica.dart';
import 'package:veronauka/molitve/molitva.dart';
import 'package:veronauka/biblija/knjiga.dart';
import 'package:veronauka/biblija/verzija.dart';
import 'package:veronauka/molitve/molitve.dart';

class Pocetna extends StatefulWidget {
  final Function(int) idiNaIndeks;
  final bool latinica;

  const Pocetna({super.key, required this.idiNaIndeks, required this.latinica});

  @override
  State<Pocetna> createState() => _PocetnaState();
}

class _PocetnaState extends State<Pocetna> {
  Dan? _dan;
  List<Molitva> _molitve = [];

  List<Verzija> _verzije = [];
  late Verzija _izabranaVerzija;
  List<Knjiga> _knjige = [];
  Map<dynamic, dynamic> _zakacenoPoglavlje = {};
  List<dynamic> _sadrzaj = [];
  int _delo = 0;

  bool _ucitano = false;
  bool _latinica = false;

  GlobalKey _kalendar1 = GlobalKey();
  GlobalKey _molitve2 = GlobalKey();
  GlobalKey _biblija3 = GlobalKey();
  GlobalKey _dobra_dela4 = GlobalKey();

  Map<dynamic, dynamic> _prikaziUputstva = {};

  @override
  void initState() {
    super.initState();
    setup();
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    setup();
  }

  void setup() async {
    await _ucitajDanasnjiDan();

    await _ucitajMolitve();
    await _ucitajStanjeZakacenihMolitvi();

    await _ucitajVerzijeBiblije();
    await _ucitajIzabranuVerzijuBiblije();
    await _ucitajKnjigeBiblije();
    await _ucitajStanjeZakacenogPoglavljaBiblije();
    await _ucitajSadrzajKnjige(_knjige[_zakacenoPoglavlje["id_knjige"]]);

    await _ucitajStanjePrikazivanjaUputstva();
    await _ucitajStanjeIstaknutogDela();
    // await _ucitajStanjeLatinice();

    setState(() {
      _latinica = widget.latinica;
      _ucitano = true;
    });

    if (_prikaziUputstva["pocetna_nov_korisnik"]) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          ShowCaseWidget.of(context)
              .startShowCase([_kalendar1, _molitve2, _biblija3, _dobra_dela4]));

      setState(() {
        _prikaziUputstva["pocetna_nov_korisnik"] = false;
      });

      _sacuvajStanjePrikazivanjaUputstva();
    }
  }

  Future<void> _ucitajStanjePrikazivanjaUputstva() async {
    Box box = await Hive.box("parametri");
    Map<dynamic, dynamic> prikaziUputstva =
        box.get('prikazi_uputstva', defaultValue: null);

    setState(() {
      _prikaziUputstva = prikaziUputstva;
    });
  }

  Future<void> _sacuvajStanjePrikazivanjaUputstva() async {
    Box box = await Hive.box("parametri");
    box.put("prikazi_uputstva", _prikaziUputstva);
  }

  Future<void> _ucitajStanjeIstaknutogDela() async {
    Box box = await Hive.box("parametri");

    setState(() {
      _delo = box.get("istaknuto_delo", defaultValue: 0) % brojDela;
    });

    box.put("istaknuto_delo", _delo + 1);
  }

  // Future<void> _ucitajStanjeLatinice() async {
  //   Box box = await Hive.box("parametri");
  //
  //   setState(() {
  //     _latinica = box.get("latinica", defaultValue: true);
  //   });
  // }
  //
  // Future<void> _sacuvajStanjeLatinice() async {
  //   Box box = await Hive.box("parametri");
  //   box.put("latinica", _latinica);
  // }

  Future<void> _ucitajDanasnjiDan() async {
    DateTime danas = DateTime.now();

    String jsonNiska = await rootBundle
        .loadString("podaci/kalendar/godine/godina-${danas.year}.json");
    List<dynamic> dekodiranKalendar = json.decode(jsonNiska);

    setState(() {
      _dan = Dan(
        dan: danas,
        praznici: [
          // Za svaki praznik
          for (int i = 0,
                  len2 = dekodiranKalendar[danas.month - 1][danas.day - 1]
                          ["praznici"]
                      .length;
              i < len2;
              i++)
            Praznik(
              naslov: dekodiranKalendar[danas.month - 1][danas.day - 1]
                  ["praznici"][i]["naslov"],
            )
        ],
      );
    });
  }

  Future<void> _ucitajMolitve() async {
    // Ucitaj json fajl kao nisku, pa ga dekodiraj
    String jsonNiska =
        await rootBundle.loadString('podaci/molitve/molitve.json');
    List<dynamic> dekodiraneMolitve = json.decode(jsonNiska);

    setState(() {
      // Pretvori svaku mapu u Molitva objekat, pa ga sacuvaj u state
      _molitve = [
        for (int i = 0, len = dekodiraneMolitve.length; i < len; i++)
          Molitva(
            id: i,
            naslov: dekodiraneMolitve[i]['naslov']!,
            telo: dekodiraneMolitve[i]['telo']!,
            izvor: dekodiraneMolitve[i]['izvor']!,
          )
      ];
      _molitve.sort((a, b) => a.id - b.id);
    });
  }

  Future<void> _ucitajStanjeZakacenihMolitvi() async {
    // Ucitaj sacuvane identifikatore zakacenih
    Box box = await Hive.box("parametri");
    List<dynamic>? idZakacenihMolitvi =
        box.get('zakacene_molitve', defaultValue: null);

    if (idZakacenihMolitvi != null) {
      // Sacuvaj ih u stanje
      setState(() {
        for (var molitva in _molitve) {
          molitva.zakaceno = idZakacenihMolitvi.contains(molitva.id);
        }

        // Podeli molitve na zakacene i klasicne
        List<Molitva> zakaceneMolitve =
            _molitve.where((molitva) => molitva.zakaceno).toList();
        List<Molitva> klasicneMolitve =
            _molitve.where((molitva) => !molitva.zakaceno).toList();

        // Spoji tako da su zakacene prve
        _molitve = [...zakaceneMolitve, ...klasicneMolitve];
      });
    }
  }

  Future<void> _ucitajVerzijeBiblije() async {
    String jsonNiska =
        await rootBundle.loadString("podaci/biblija/verzije.json");
    List<dynamic> dekodiraneVerzije = json.decode(jsonNiska);

    setState(() {
      // Pretvori svaku mapu u Knjiga objekat, pa ga sacuvaj u state
      _verzije = [
        for (int i = 0, len = dekodiraneVerzije.length; i < len; i++)
          Verzija(
            id: i,
            naslov: dekodiraneVerzije[i]['naslov']!,
            lokacija: dekodiraneVerzije[i]['lokacija']!,
          )
      ];
      _verzije.sort((a, b) => a.id - b.id);
    });
  }

  Future<void> _ucitajIzabranuVerzijuBiblije() async {
    // Ucitaj id verzije
    Box box = await Hive.box("parametri");
    int idIzabraneVerzije =
        box.get("id_izabrane_verzije_biblije", defaultValue: 0);

    setState(() {
      Verzija? verzija = _verzije
          .where((verzija) => verzija.id == idIzabraneVerzije)
          .firstOrNull;
      if (verzija != null) {
        _izabranaVerzija = verzija;
      } else {
        _izabranaVerzija = _verzije[0];
      }
    });
  }

  Future<void> _ucitajKnjigeBiblije() async {
    String jsonNiska = await rootBundle
        .loadString("podaci/biblija/${_izabranaVerzija.lokacija}/knjige.json");
    List<dynamic> dekodiraneKnjige = json.decode(jsonNiska);

    setState(() {
      // Pretvori svaku mapu u Knjiga objekat, pa ga sacuvaj u state
      _knjige = [
        for (int i = 0, len = dekodiraneKnjige.length; i < len; i++)
          Knjiga(
            id: i,
            naslov: dekodiraneKnjige[i]['naslov']!,
            lokacija: dekodiraneKnjige[i]['lokacija']!,
            kategorija: dekodiraneKnjige[i]['kategorija']!,
            potkategorija: dekodiraneKnjige[i]['potkategorija']!,
          )
      ];
      _knjige.sort((a, b) => a.id - b.id);
    });
  }

  Future<void> _ucitajStanjeZakacenogPoglavljaBiblije() async {
    Box box = await Hive.box("parametri");
    Map<dynamic, dynamic> zakacenoPoglavlje = box.get(
      'zakaceno_poglavlje',
      defaultValue: {'id_knjige': 0, 'indeks_poglavlja': 0},
    );

    // Sacuvaj u stanje
    setState(() {
      _zakacenoPoglavlje = zakacenoPoglavlje;
    });
  }

  Future<void> _ucitajSadrzajKnjige(knjiga) async {
    // Ucitaj sadrzaj knjige
    String sadrzajJson = await rootBundle.loadString(
        "podaci/biblija/${_izabranaVerzija.lokacija}/${knjiga.lokacija}");

    setState(() {
      _sadrzaj = json.decode(sadrzajJson);
    });
  }

  void _sacuvajStanjeZakacenogPoglavlja(
      Map<dynamic, dynamic> novoZakacenoPoglavlje) {
    setState(() {
      _zakacenoPoglavlje = novoZakacenoPoglavlje;
    });
  }

  // void _skrolujDo(GlobalKey key) {
  //   RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
  //   double offset = renderBox.localToGlobal(Offset.zero).dy;
  //   _scrollController.animateTo(
  //     offset,
  //     duration: Duration(milliseconds: 500),
  //     curve: Curves.easeInOut,
  //   );
  // }

  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    if (_ucitano && _dan != null) {
      Praznik praznik = _dan!.praznici[0];

      Map<String, dynamic> poglavlje =
          _sadrzaj[_zakacenoPoglavlje["indeks_poglavlja"]];

      List<Delo> _dela = _latinica
          ? delaLatinica(context, textTheme, colors)
          : dela(context, textTheme, colors);
      Delo _istaknuto_delo = _dela[_delo];

      return ListView(
        // controller: _scrollController,
        children: [
          // Kalendar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Showcase(
              key: _kalendar1,
              targetBorderRadius: BorderRadius.circular(13),
              tooltipBorderRadius: BorderRadius.circular(10),
              tooltipPadding: EdgeInsets.all(15),
              // onTargetClick: () {
              //   _skrolujDo(_kalendar1);
              // },
              titleTextStyle: textTheme.titleMedium?.merge(TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              )),
              descTextStyle: textTheme.bodyMedium?.merge(TextStyle(
                fontStyle: FontStyle.italic,
              )),
              title: _latinica
                  ? cirilicaLatinica('Данашњи празник')
                  : 'Данашњи празник',
              description: _latinica
                  ? cirilicaLatinica(
                      'Сазнајте који се празник прославља данас, као и осталих датума.')
                  : 'Сазнајте који се празник прославља данас, као и осталих датума.',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.calendar,
                            size: textTheme.titleMedium?.fontSize,
                            color: colors.primary,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text(
                            _latinica
                                ? cirilicaLatinica('Данас се прославља:')
                                : 'Данас се прославља:',
                            style: textTheme.bodyMedium?.merge(TextStyle(
                              fontStyle: FontStyle.italic,
                            )),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        child: Text(
                          _latinica
                              ? cirilicaLatinica(_dan!.praznici[0].naslov)
                              : _dan!.praznici[0].naslov,
                          style: textTheme.titleMedium?.merge(TextStyle(
                            color: praznik.crnoSlovo
                                ? null
                                : praznik.crvenoSlovo
                                    ? HSLColor.fromColor(colors.primary)
                                        .withHue(0)
                                        .toColor()
                                    : colors.primary,
                            fontWeight: FontWeight.bold,
                          )),
                        ),
                        onTap: () {
                          widget.idiNaIndeks(3);
                        },
                      ),
                      SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            if (_dan!.praznici.length - 1 > 0)
                              TextSpan(
                                text: _latinica
                                    ? cirilicaLatinica(
                                        'и још ${_dan!.praznici.length - 1}, ')
                                    : 'и још ${_dan!.praznici.length - 1}, ',
                                style: textTheme.bodyMedium?.merge(TextStyle(
                                  fontStyle: FontStyle.italic,
                                )),
                              ),
                            TextSpan(
                              text: _latinica
                                  ? cirilicaLatinica('детаљније...')
                                  : 'детаљније...',
                              style: textTheme.bodyMedium?.merge(TextStyle(
                                color: colors.primary,
                                fontStyle: FontStyle.italic,
                                decoration: TextDecoration.underline,
                                decorationColor: colors.primary,
                              )),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  widget.idiNaIndeks(3);
                                },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          Row(
            children: [
              // Molitve
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Showcase(
                    key: _molitve2,
                    targetBorderRadius: BorderRadius.circular(13),
                    tooltipBorderRadius: BorderRadius.circular(10),
                    tooltipPadding: EdgeInsets.all(15),
                    // onTargetClick: () {
                    //   _skrolujDo(_molitve2);
                    // },
                    titleTextStyle: textTheme.titleMedium?.merge(TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    )),
                    descTextStyle: textTheme.bodyMedium?.merge(TextStyle(
                      fontStyle: FontStyle.italic,
                    )),
                    title: _latinica
                        ? cirilicaLatinica('Закачене молитве')
                        : 'Закачене молитве',
                    description: _latinica
                        ? cirilicaLatinica(
                            'Читајте молитве и закачите их овде да Вам буду на дохват руке.')
                        : 'Читајте молитве и закачите их овде да Вам буду на дохват руке.',
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.personPraying,
                                  size: textTheme.titleMedium?.fontSize,
                                  color: colors.primary,
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  _latinica
                                      ? cirilicaLatinica('Молитве:')
                                      : 'Молитве:',
                                  style: textTheme.bodyMedium?.merge(TextStyle(
                                    fontStyle: FontStyle.italic,
                                  )),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            for (int i = 0; i < 3; i++) ...[
                              GestureDetector(
                                child: Text(
                                  _latinica
                                      ? cirilicaLatinica(_molitve[i].naslov)
                                      : _molitve[i].naslov,
                                  style: textTheme.titleMedium?.merge(TextStyle(
                                    color: colors.primary,
                                    fontWeight: FontWeight.bold,
                                  )),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => ModalZaMolitvu(
                                      molitva: _molitve[i],
                                      latinica: _latinica,
                                    ),
                                    showDragHandle: true,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                  );
                                },
                              ),
                            ],
                            SizedBox(height: 8),
                            GestureDetector(
                              child: Text(
                                _latinica
                                    ? cirilicaLatinica('види још...')
                                    : 'види још...',
                                style: textTheme.bodyMedium?.merge(TextStyle(
                                  color: colors.primary,
                                  fontStyle: FontStyle.italic,
                                  decoration: TextDecoration.underline,
                                  decorationColor: colors.primary,
                                )),
                              ),
                              onTap: () {
                                widget.idiNaIndeks(1);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Biblija
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Showcase(
                    key: _biblija3,
                    targetBorderRadius: BorderRadius.circular(13),
                    tooltipBorderRadius: BorderRadius.circular(10),
                    tooltipPadding: EdgeInsets.all(15),
                    // onTargetClick: () {
                    //   _skrolujDo(_biblija3);
                    // },
                    titleTextStyle: textTheme.titleMedium?.merge(TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    )),
                    descTextStyle: textTheme.bodyMedium?.merge(TextStyle(
                      fontStyle: FontStyle.italic,
                    )),
                    title: _latinica
                        ? cirilicaLatinica('Закачено поглавље Библије')
                        : 'Закачено поглавље Библије',
                    description: _latinica
                        ? cirilicaLatinica(
                            'Ваше дневно поглавље Библије се појављује овде сваки дан.')
                        : 'Ваше дневно поглавље Библије се појављује овде сваки дан.',
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.bookBible,
                                  size: textTheme.titleMedium?.fontSize,
                                  color: colors.primary,
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  _latinica
                                      ? cirilicaLatinica('Библија:')
                                      : 'Библија:',
                                  style: textTheme.bodyMedium?.merge(TextStyle(
                                    fontStyle: FontStyle.italic,
                                  )),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            GestureDetector(
                              child: Text(
                                _latinica
                                    ? cirilicaLatinica(poglavlje["naslov"])
                                    : poglavlje["naslov"],
                                style: textTheme.titleMedium?.merge(TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                )),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                await showModalBottomSheet(
                                  context: context,
                                  builder: (context) => ModalZaCitanje(
                                    knjiga: _knjige[
                                        _zakacenoPoglavlje['id_knjige']],
                                    sadrzaj: _sadrzaj,
                                    indeksPoglavlja:
                                        _zakacenoPoglavlje['indeks_poglavlja'],
                                    sacuvajStanjeZakacenogPoglavlja:
                                        _sacuvajStanjeZakacenogPoglavlja,
                                    latinica: _latinica,
                                  ),
                                  showDragHandle: true,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                );
                              },
                            ),
                            SizedBox(height: 8),
                            GestureDetector(
                              child: Text(
                                _latinica
                                    ? cirilicaLatinica('види још...')
                                    : 'види још...',
                                style: textTheme.bodyMedium?.merge(TextStyle(
                                  color: colors.primary,
                                  fontStyle: FontStyle.italic,
                                  decoration: TextDecoration.underline,
                                  decorationColor: colors.primary,
                                )),
                              ),
                              onTap: () {
                                widget.idiNaIndeks(2);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // // Clanci
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 10),
          //   child: Card(
          //     child: Padding(
          //       padding: const EdgeInsets.all(15),
          //       child: Stack(
          //         children: [
          //           Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               Row(
          //                 children: [
          //                   FaIcon(
          //                     FontAwesomeIcons.book,
          //                     size: textTheme.titleMedium?.fontSize,
          //                     color: colors.primary,
          //                   ),
          //                   SizedBox(
          //                     width: 8,
          //                   ),
          //                   Text(
          //                     'Истакнути чланак:',
          //                     style: textTheme.bodyMedium?.merge(TextStyle(
          //                       fontStyle: FontStyle.italic,
          //                     )),
          //                   ),
          //                 ],
          //               ),
          //               SizedBox(height: 8),
          //               GestureDetector(
          //                 child: Clanak(
          //                   colors: colors,
          //                   textTheme: textTheme,
          //                   naslov:
          //                       "Значај крсне славе код Срба",
          //                   tekst:
          //                       "Господе Исусе Христе, сине Божији, помилуј нас грешне. Амин. Господе Исусе Христе, сине Божији, помилуј нас грешне. Амин. Господе Исусе Христе, сине Божији, помилуј нас грешне. Амин. Господе Исусе Христе, сине Божији, помилуј нас грешне. Амин. Господе Исусе Христе, сине Божији, помилуј нас грешне. Амин. Господе Исусе Христе, сине Божији, помилуј нас грешне. Амин. Господе Исусе Христе, сине Божији, помилуј нас грешне. Амин. Господе Исусе Христе, сине Божији, помилуј нас грешне. Амин. Господе Исусе Христе, сине Божији, помилуј нас грешне. Амин. Господе Исусе Христе, сине Божији, помилуј нас грешне. Амин.",
          //                 ),
          //               ),
          //             ],
          //           ),
          //
          //           Positioned(
          //             bottom: 0,
          //             right: 0 ,
          //             child: GestureDetector(
          //               child: Text(
          //                 'види још...',
          //                 style: textTheme.bodyMedium?.merge(TextStyle(
          //                   color: colors.primary,
          //                   fontStyle: FontStyle.italic,
          //                   decoration: TextDecoration.underline,
          //                   decorationColor: colors.primary,
          //                 )),
          //               ),
          //               onTap: () {
          //                 widget.idiNaIndeks(4);
          //               },
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),

          // Dobra dela
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Showcase(
              key: _dobra_dela4,
              targetBorderRadius: BorderRadius.circular(13),
              tooltipBorderRadius: BorderRadius.circular(10),
              tooltipPadding: EdgeInsets.all(15),
              // onTargetClick: () {
              //   _skrolujDo(_dobra_dela4);
              // },
              titleTextStyle: textTheme.titleMedium?.merge(TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              )),
              descTextStyle: textTheme.bodyMedium?.merge(TextStyle(
                fontStyle: FontStyle.italic,
              )),
              title: _latinica
                  ? cirilicaLatinica('Истакнуто добро дело')
                  : 'Истакнуто добро дело',
              description: _latinica
                  ? cirilicaLatinica(
                      'Дајте свој допринос, ваше мало је некоме пуно.')
                  : 'Дајте свој допринос, ваше мало је некоме пуно.',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.handHoldingHeart,
                                size: textTheme.titleMedium?.fontSize,
                                color: colors.primary,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                _latinica
                                    ? cirilicaLatinica('Истакнуто добро дело:')
                                    : 'Истакнуто добро дело:',
                                style: textTheme.bodyMedium?.merge(TextStyle(
                                  fontStyle: FontStyle.italic,
                                )),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          _istaknuto_delo,
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: GestureDetector(
                          child: Text(
                            _latinica
                                ? cirilicaLatinica(
                                    'види још...',
                                  )
                                : 'види још...',
                            style: textTheme.bodyMedium?.merge(TextStyle(
                              color: colors.primary,
                              fontStyle: FontStyle.italic,
                              decoration: TextDecoration.underline,
                              decorationColor: colors.primary,
                            )),
                          ),
                          onTap: () {
                            widget.idiNaIndeks(4);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: CircularProgressIndicator(), // Show a loading indicator
      );
    }
  }
}
