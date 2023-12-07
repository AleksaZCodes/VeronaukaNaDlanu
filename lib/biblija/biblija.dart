import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:veronauka/biblija/knjiga.dart';
import 'package:veronauka/biblija/verzija.dart';
import 'package:veronauka/latinica_cirilica.dart';

class Biblija extends StatefulWidget {
  const Biblija({super.key});

  @override
  State<Biblija> createState() => _BiblijaState();
}

class _BiblijaState extends State<Biblija> {
  TextEditingController _kontrolerPretrage = TextEditingController();
  List<Verzija> _verzije = [];
  late Verzija _izabranaVerzija;
  List<Knjiga> _knjige = [];
  List<Knjiga> _filtriraneKnjige = [];
  Map<dynamic, dynamic> _zakacenoPoglavlje = {};

  GlobalKey _knjiga1 = GlobalKey();
  GlobalKey _pretraga2 = GlobalKey();

  Map<dynamic, dynamic> _prikaziUputstva = {};

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() async {
    await _ucitajVerzije();
    await _ucitajIzabranuVerziju();
    await _ucitajKnjige();
    await _ucitajStanjeZakacenogPoglavlja();

    await _ucitajStanjePrikazivanjaUputstva();

    setState(() {
      _filtriraneKnjige = _knjige;
    });

    if (_prikaziUputstva["biblija_nov_korisnik_glavno"]) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          ShowCaseWidget.of(context).startShowCase([_knjiga1, _pretraga2]));

      setState(() {
        _prikaziUputstva["biblija_nov_korisnik_glavno"] = false;
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

  Future<void> _ucitajVerzije() async {
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

  Future<void> _ucitajIzabranuVerziju() async {
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

  // Future<void> _sacuvajIzabranuVerziju() async {
  //   Box box = await Hive.box("parametri");
  //   box.put("id_izabrane_verzije_biblije", _izabranaVerzija.id);
  // }

  Future<void> _ucitajKnjige() async {
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

  Future<void> _ucitajStanjeZakacenogPoglavlja() async {
    Box box = await Hive.box("parametri");
    Map<dynamic, dynamic>? zakacenoPoglavlje =
        box.get('indeks_zakacenog_poglavlja', defaultValue: null);

    if (zakacenoPoglavlje != null) {
      // Sacuvaj u stanje
      setState(() {
        _zakacenoPoglavlje = zakacenoPoglavlje;
      });
    }
  }

  void _sacuvajStanjeZakacenogPoglavlja(
      Map<dynamic, dynamic> novoZakacenoPoglavlje) {
    setState(() {
      _zakacenoPoglavlje = novoZakacenoPoglavlje;
    });
  }

  // void _promeniVerziju() async {
  //   await _sacuvajIzabranuVerziju();
  //   await _ucitajKnjige();
  // }

  void _filtrirajKnjige(String unos) {
    setState(() {
      _filtriraneKnjige = _knjige.where((knjiga) {
        String naslov = latinicaCirilica(knjiga.naslov.toLowerCase());
        String kategorija = latinicaCirilica(knjiga.kategorija.toLowerCase());
        String potkategorija =
            latinicaCirilica(knjiga.potkategorija.toLowerCase());
        String unosCirilica = latinicaCirilica(unos.trim().toLowerCase());

        return naslov.contains(unosCirilica) ||
            kategorija.contains(unosCirilica) ||
            potkategorija.contains(unosCirilica);
      }).toList();
    });
  }

  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    // Izvuci zakacenu knjigu
    Knjiga? zakacenaKnjiga = _knjige
        .where((knjiga) => knjiga.id == _zakacenoPoglavlje['id_knjige'])
        .firstOrNull;

    if (zakacenaKnjiga != null) {
      // Stavi je na vrh
      List<Knjiga> knjige = _knjige;
      knjige.remove(zakacenaKnjiga);
      knjige.insert(0, zakacenaKnjiga);
    }

    if (_knjige.isNotEmpty) {
      return Column(
        children: [
          // Lista knjiga
          Expanded(
            child: ListView.builder(
                itemCount: _filtriraneKnjige.length,
                padding: EdgeInsets.symmetric(horizontal: 10),
                physics: AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  Knjiga knjiga = _filtriraneKnjige[index];

                  if (index == 0) {
                    return Showcase(
                      key: _knjiga1,
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
                      title: 'Књига Библије',
                      description:
                          'Ово је једна од књига Библије коју можете прочитати кликом на њу. Оне се деле на Стари и Нови Завет и одређене поткатегорије.',
                      child: KarticaKnjige(
                        knjiga: knjiga,
                        izabranaVerzija: _izabranaVerzija,
                        zakacenoPoglavlje: _zakacenoPoglavlje,
                        sacuvajStanjeZakacenogPoglavlja:
                            _sacuvajStanjeZakacenogPoglavlja,
                      ),
                    );
                  } else {
                    return KarticaKnjige(
                      knjiga: knjiga,
                      izabranaVerzija: _izabranaVerzija,
                      zakacenoPoglavlje: _zakacenoPoglavlje,
                      sacuvajStanjeZakacenogPoglavlja:
                          _sacuvajStanjeZakacenogPoglavlja,
                    );
                  }
                }),
          ),

          // Pretraga knjiga
          Padding(
            padding: EdgeInsets.all(10),
            child: Showcase(
              key: _pretraga2,
              targetBorderRadius: BorderRadius.circular(100),
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
              title: 'Претрага књига',
              description:
                  'Можете да претражујете књиге Библије по наслову, категорији или поткатегорији.',
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.magnifyingGlass,
                          color: colors.primary,
                          size: textTheme.titleLarge?.fontSize,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Flexible(
                          child: Container(
                            child: TextField(
                              maxLines: 1,
                              style: textTheme.titleMedium!.merge(TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              )),
                              decoration: InputDecoration(
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 0),
                                border: InputBorder.none,
                                hintText: "Претражите књиге",
                              ),
                              controller: _kontrolerPretrage,
                              onChanged: (String unos) {
                                _filtrirajKnjige(unos);
                              },
                            ),
                          ),
                        ),
                      ]),
                ),
              ),
            ),
          ),

          // // Odabir verzije
          // DropdownButton(
          //   value: _izabranaVerzija,
          //   onChanged: (novaVerzija) {
          //     setState(() {
          //       if (novaVerzija != null) {
          //         _izabranaVerzija = novaVerzija;
          //         _promeniVerziju();
          //       }
          //     });
          //   },
          //   items: _verzije.map((verzija) {
          //     return DropdownMenuItem(
          //       value: verzija,
          //       child: Text(verzija.naslov),
          //     );
          //   }).toList(),
          // ),
        ],
      );
    } else {
      return Center(
        child: CircularProgressIndicator(), // Show a loading indicator
      );
    }
  }
}

class KarticaKnjige extends StatelessWidget {
  const KarticaKnjige({
    super.key,
    required this.knjiga,
    required Verzija izabranaVerzija,
    required this.zakacenoPoglavlje,
    required this.sacuvajStanjeZakacenogPoglavlja,
  }) : _izabranaVerzija = izabranaVerzija;

  final Knjiga knjiga;
  final Verzija _izabranaVerzija;
  final Map<dynamic, dynamic> zakacenoPoglavlje;
  final Function(Map<dynamic, dynamic>) sacuvajStanjeZakacenogPoglavlja;

  @override
  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    bool zakacena = knjiga.id == zakacenoPoglavlje['id_knjige'];

    return Card(
      key: ValueKey(knjiga.id),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),

        // Naslov
        title: Text(knjiga.naslov),
        titleTextStyle: textTheme.titleMedium?.merge(
          TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Podnaslov - kategorija i potkategorija
        subtitle: Text("${knjiga.kategorija} / ${knjiga.potkategorija}"),
        subtitleTextStyle: textTheme.bodyMedium?.merge(
          TextStyle(
            fontStyle: FontStyle.italic,
          ),
        ),

        // Ikonica (ako je zakacena)
        trailing: zakacena
            ? FaIcon(
                FontAwesomeIcons.solidBookmark,
                color: colors.primary,
                size: textTheme.titleLarge?.fontSize,
              )
            : null,

        onTap: () async {
          // Ucitaj sadrzaj knjige
          String sadrzajJson = await rootBundle.loadString(
              "podaci/biblija/${_izabranaVerzija.lokacija}/${knjiga.lokacija}");
          List<dynamic> sadrzaj = json.decode(sadrzajJson);

          await showModalBottomSheet(
            context: context,
            builder: (context) => ModalZaCitanje(
              knjiga: knjiga,
              sadrzaj: sadrzaj,
              indeksPoglavlja:
                  zakacena ? zakacenoPoglavlje['indeks_poglavlja'] : 0,
              sacuvajStanjeZakacenogPoglavlja: sacuvajStanjeZakacenogPoglavlja,
            ),
            showDragHandle: true,
            isScrollControlled: true,
            useSafeArea: true,
          );
        },
      ),
    );
  }
}

class ModalZaCitanje extends StatefulWidget {
  final Knjiga knjiga;
  final List<dynamic> sadrzaj;
  final int indeksPoglavlja;
  final Function(Map<dynamic, dynamic>) sacuvajStanjeZakacenogPoglavlja;

  const ModalZaCitanje({
    super.key,
    required this.knjiga,
    required this.sadrzaj,
    this.indeksPoglavlja = 0,
    required this.sacuvajStanjeZakacenogPoglavlja,
  });

  @override
  State<ModalZaCitanje> createState() => _ModalZaCitanjeState();
}

class _ModalZaCitanjeState extends State<ModalZaCitanje> {
  late Knjiga _knjiga;
  late int _indeks_poglavlja;
  int _indeks_zakacenog_poglavlja = -1;
  int _id_zakacene_knjige = -1;
  late ScrollController _skrolKontroler;

  GlobalKey _naslov1 = GlobalKey();
  GlobalKey _podnaslov2 = GlobalKey();
  GlobalKey _stih3 = GlobalKey();
  GlobalKey _kontrole4 = GlobalKey();
  GlobalKey _dugme_zakaci5 = GlobalKey();

  Map<dynamic, dynamic> _prikaziUputstva = {};

  @override
  void initState() {
    super.initState();
    setup();
  }

  void setup() async {
    setState(() {
      _knjiga = widget.knjiga;
      _indeks_poglavlja = widget.indeksPoglavlja;
      _skrolKontroler = ScrollController();
    });

    await _ucitajStanjeZakacenog();
    await _ucitajStanjePrikazivanjaUputstva();
  }

  void dispose() {
    _skrolKontroler.dispose();
    super.dispose();
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

  Future<void> _sacuvajStanjeZakacenog() async {
    Box box = await Hive.box("parametri");
    box.put('indeks_zakacenog_poglavlja',
        {"indeks_poglavlja": _indeks_poglavlja, "id_knjige": _knjiga.id});

    widget.sacuvajStanjeZakacenogPoglavlja({
      "indeks_poglavlja": _indeks_poglavlja,
      "id_knjige": _knjiga.id,
    });
  }

  Future<void> _ucitajStanjeZakacenog() async {
    Box box = await Hive.box("parametri");
    Map<dynamic, dynamic>? zakacenoPoglavlje =
        box.get('indeks_zakacenog_poglavlja', defaultValue: null);

    if (zakacenoPoglavlje != null) {
      // Sacuvaj u stanje
      setState(() {
        _id_zakacene_knjige = zakacenoPoglavlje["id_knjige"];
        _indeks_zakacenog_poglavlja = zakacenoPoglavlje["indeks_poglavlja"];
      });
    }
  }

  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    Map<String, dynamic> poglavlje = widget.sadrzaj[_indeks_poglavlja];

    return ShowCaseWidget(
      builder: Builder(builder: (context) {
        if (_prikaziUputstva["biblija_nov_korisnik_citanje"] ?? false) {
          WidgetsBinding.instance.addPostFrameCallback((_) =>
              ShowCaseWidget.of(context)
                  .startShowCase([_naslov1, _podnaslov2, _stih3, _kontrole4, _dugme_zakaci5]));

          _prikaziUputstva["biblija_nov_korisnik_citanje"] = false;

          _sacuvajStanjePrikazivanjaUputstva();
        }

        return Stack(
          children: [
            // Prozor za citanje
            ListView(
              controller: _skrolKontroler,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Showcase(
                        key: _naslov1,
                        targetBorderRadius: BorderRadius.circular(13),
                        targetPadding: EdgeInsets.all(5),
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
                        title: 'Наслов књиге',
                        description:
                            'Овде се налази наслов отворене књиге.',
                        child: Text(
                          _knjiga.naslov,
                          style: textTheme.titleLarge?.merge(
                            TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Showcase(
                        key: _podnaslov2,
                        targetBorderRadius: BorderRadius.circular(13),
                        targetPadding: EdgeInsets.all(5),
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
                        title: 'Наслов поглавља',
                        description:
                            'Књиге су подељене на поглавља, чије име се налази овде.',
                        child: Text(
                          "${_indeks_poglavlja + 1}. ${poglavlje["naslov"]}",
                          style: textTheme.titleMedium?.merge(
                            TextStyle(
                                color: colors.primary,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                      for (int i = 0, len = poglavlje["stihovi"].length;
                          i < len;
                          i++)
                        i == 0
                            ? Showcase(
                                key: _stih3,
                                targetBorderRadius: BorderRadius.circular(13),
                                targetPadding: EdgeInsets.symmetric(horizontal: 5),
                                tooltipBorderRadius: BorderRadius.circular(10),
                                tooltipPadding: EdgeInsets.all(15),
                                // onTargetClick: () {
                                //   _skrolujDo(_biblija3);
                                // },
                                titleTextStyle:
                                    textTheme.titleMedium?.merge(TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                )),
                                descTextStyle:
                                    textTheme.bodyMedium?.merge(TextStyle(
                                  fontStyle: FontStyle.italic,
                                )),
                                title: 'Стих',
                                description:
                                    'Поглавља су подељена на нумерисане стихове, а ово је један од њих.',
                                child: Stih(
                                  tekst: poglavlje["stihovi"][i],
                                  indeks: i + 1,
                                ),
                              )
                            : Stih(
                                tekst: poglavlje["stihovi"][i],
                                indeks: i + 1,
                              ),
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),

            // Kontrole na dnu
            Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Showcase(
                    key: _kontrole4,
                    targetBorderRadius: BorderRadius.circular(13),
                    tooltipBorderRadius: BorderRadius.circular(10),
                    tooltipPadding: EdgeInsets.all(15),
                    // onTargetClick: () {
                    //   _skrolujDo(_biblija3);
                    // },
                    titleTextStyle:
                    textTheme.titleMedium?.merge(TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    )),
                    descTextStyle:
                    textTheme.bodyMedium?.merge(TextStyle(
                      fontStyle: FontStyle.italic,
                    )),
                    title: 'Контроле',
                    description:
                    'Овде можете да прелиставате књигу по поглављима и видите на којем сте тренутно.',
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dugme prethodno
                      FloatingActionButton.small(
                        onPressed: () {
                          setState(() {
                            if (_indeks_poglavlja > 0) {
                              _indeks_poglavlja--;
                              _skrolKontroler.jumpTo(0);
                            }
                          });
                        },
                        child: FaIcon(
                          FontAwesomeIcons.caretLeft,
                          size: textTheme.displaySmall?.fontSize,
                          color: colors.primary,
                        ),
                        backgroundColor: colors.surfaceVariant,
                      ),

                      // Naslov poglavlja
                      Flexible(
                        child: Card(
                          elevation: 5,
                          child: Container(
                            padding: EdgeInsets.all(11),
                            child: Text(
                              "${_indeks_poglavlja + 1}. ${poglavlje["naslov"]}",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Dugme zakaci
                      Showcase(
                        key: _dugme_zakaci5,
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
                        title: 'Ставите обележивач',
                        description:
                        'Када завршите са читањем, оставите обележивач како бисте могли да наставите.',
                        child: FloatingActionButton.small(
                          onPressed: () {
                            _sacuvajStanjeZakacenog();
                            Navigator.pop(context);
                          },
                          child: FaIcon(
                            _indeks_poglavlja == _indeks_zakacenog_poglavlja &&
                                    _knjiga.id == _id_zakacene_knjige
                                ? FontAwesomeIcons.solidBookmark
                                : FontAwesomeIcons.bookmark,
                            size: textTheme.titleLarge?.fontSize,
                            color: colors.primary,
                          ),
                          backgroundColor: colors.surfaceVariant,
                        ),
                      ),

                      // Dugme sledece
                      FloatingActionButton.small(
                        onPressed: () {
                          setState(() {
                            if (_indeks_poglavlja < widget.sadrzaj.length - 1) {
                              _indeks_poglavlja++;
                              _skrolKontroler.jumpTo(0);
                            }
                          });
                        },
                        child: FaIcon(
                          FontAwesomeIcons.caretRight,
                          size: textTheme.displaySmall?.fontSize,
                          color: colors.primary,
                        ),
                        backgroundColor: colors.surfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class Stih extends StatelessWidget {
  final int indeks;
  final String tekst;

  const Stih({
    super.key,
    required this.indeks,
    required this.tekst,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            "$indeks",
            style: textTheme.bodySmall?.merge(TextStyle(color: colors.outline)),
          ),
          SizedBox(
            width: 10,
          ),
          Flexible(
            child: Text(
              tekst,
              style: textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
