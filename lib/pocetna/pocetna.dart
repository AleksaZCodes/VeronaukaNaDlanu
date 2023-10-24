import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:veronauka/biblija/verzija.dart';

import 'package:veronauka/kalendar/praznik.dart';
import 'package:veronauka/kalendar/dan.dart';
import 'package:veronauka/molitve/molitva.dart';
import 'package:veronauka/biblija/knjiga.dart';
import 'package:veronauka/molitve/molitve.dart';

class Pocetna extends StatefulWidget {
  final Function(int) idiNaIndeks;

  const Pocetna({super.key, required this.idiNaIndeks});

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

  bool _ucitano = false;

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

    setState(() {
      _ucitano = true;
    });
  }

  Future<void> _ucitajDanasnjiDan() async {
    DateTime danas = DateTime.now();

    String jsonNiska = await rootBundle
        .loadString("podaci/kalendar/godine/godina-${danas.year}.json");
    List<dynamic> dekodiranKalendar = json.decode(jsonNiska);

    setState(() {
      _dan = Dan(
        objasnjenje: dekodiranKalendar[danas.month - 1][danas.day - 1]
            ["objasnjenje"],
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
      Verzija? verzija = _verzije.where((verzija) => verzija.id == idIzabraneVerzije).firstOrNull;
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
      'indeks_zakacenog_poglavlja',
      defaultValue: {'id_knjige': 0, 'indeks_poglavlja': 0},
    );

    // Sacuvaj u stanje
    setState(() {
      _zakacenoPoglavlje = zakacenoPoglavlje;
    });
  }

  Future<void> _ucitajSadrzajKnjige(knjiga) async {
    // Ucitaj sadrzaj knjige
    String sadrzajJson = await rootBundle
        .loadString("podaci/biblija/${_izabranaVerzija.lokacija}/${knjiga.lokacija}");

    setState(() {
      _sadrzaj = json.decode(sadrzajJson);
    });
  }

  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    if (_ucitano && _dan != null) {
      Praznik praznik = _dan!.praznici[0];

      Map<String, dynamic> poglavlje =
          _sadrzaj[_zakacenoPoglavlje["indeks_poglavlja"]];

      return Container(
        child: ListView(
          children: [
            // Kalendar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            'Данас се прославља:',
                            style: textTheme.bodyMedium?.merge(TextStyle(
                              fontStyle: FontStyle.italic,
                            )),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _dan!.objasnjenje != ""
                            ? _dan!.objasnjenje
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
                      SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            if (_dan!.praznici.length - 1 > 0)
                              TextSpan(
                                text: 'и још ${_dan!.praznici.length - 1}, ',
                                style: textTheme.bodyMedium?.merge(TextStyle(
                                  fontStyle: FontStyle.italic,
                                )),
                              ),
                            TextSpan(
                              text: 'детаљније...',
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

            // Molitve
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
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
                            'Истакнуте молитве:',
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
                            _molitve[i].naslov,
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
                              builder: (context) =>
                                  ModalZaMolitvu(molitva: _molitve[i]),
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
                          'види још...',
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

            // Biblija
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
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
                            'Закачено поглавље Библије:',
                            style: textTheme.bodyMedium?.merge(TextStyle(
                              fontStyle: FontStyle.italic,
                            )),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        poglavlje["naslov"],
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
                      SizedBox(height: 8),
                      GestureDetector(
                        child: Text(
                          'види још...',
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

            // Dobra dela
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
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
                            'Учините добро дело:',
                            style: textTheme.bodyMedium?.merge(TextStyle(
                              fontStyle: FontStyle.italic,
                            )),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Издвојите минут да помогнете да други сазнају за апликацију",
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
                      SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: () async {},
                            child: Text(
                              "Оцени",
                              style: textTheme.bodyMedium?.merge(TextStyle(
                                color: colors.primary,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                              )),
                            ),
                          ),
                          SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              ShareResult rezultat = await Share.shareWithResult("");
                              if (rezultat.status == ShareResultStatus.success) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Хвала на дељењу! Учинили сте добро дело.")));
                              }
                            },
                            child: Text(
                              "Подели",
                              style: textTheme.bodyMedium?.merge(TextStyle(
                                color: colors.primary,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                              )),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        child: Text(
                          'види још...',
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: CircularProgressIndicator(), // Show a loading indicator
      );
    }
  }
}
