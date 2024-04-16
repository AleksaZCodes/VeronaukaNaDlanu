import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:veronauka/oglasi.dart';

import 'package:veronauka/biblija/knjiga.dart';
import 'package:veronauka/biblija/verzija.dart';
import 'package:veronauka/latinica_cirilica.dart';

class Biblija extends StatefulWidget {
  final bool latinica;

  const Biblija({super.key, required this.latinica});

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
  bool _latinica = false;

  // List<Map<dynamic, dynamic>> _kategorije = [];
  // List<Map<dynamic, dynamic>> _potkategorije = [];

  GlobalKey _knjiga1 = GlobalKey();

  // GlobalKey _pretraga2 = GlobalKey();
  // GlobalKey _filteri3 = GlobalKey();

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
    // await _ucitajKategorijeIPotkategorije();
    await _ucitajStanjeZakacenogPoglavlja();

    await _ucitajStanjePrikazivanjaUputstva();

    setState(() {
      _filtriraneKnjige = _knjige;
      _latinica = widget.latinica;
    });

    if (_prikaziUputstva["biblija_nov_korisnik_glavno"]) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ShowCaseWidget.of(context).startShowCase([_knjiga1]));

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
    });
  }

  void _sortirajKnjige() {
    setState(() {
      _knjige.sort((a, b) => a.id - b.id);
    });
  }

  // Future<void> _ucitajKategorijeIPotkategorije() async {
  //   setState(
  //     () {
  //       for (int i = 0, len = _knjige.length; i < len; i++) {
  //         Map<String, dynamic> kategorija = {
  //           "naslov": _knjige[i].kategorija,
  //           "stanje": true
  //         };
  //         Map<String, dynamic> potkategorija = {
  //           "naslov": _knjige[i].potkategorija,
  //           "stanje": true
  //         };
  //
  //         if (!_kategorije.any(
  //             (element) => element['naslov'] == kategorija['naslov'])) {
  //           _kategorije.add(kategorija);
  //         }
  //         if (!_potkategorije.any((element) =>
  //             element['naslov'] == potkategorija['naslov'])) {
  //           _potkategorije.add(potkategorija);
  //         }
  //       }
  //     },
  //   );
  // }

  Future<void> _ucitajStanjeZakacenogPoglavlja() async {
    Box box = await Hive.box("parametri");
    Map<dynamic, dynamic>? zakacenoPoglavlje =
        box.get('zakaceno_poglavlje', defaultValue: null);

    if (zakacenoPoglavlje != null) {
      // Sacuvaj u stanje
      setState(() {
        _zakacenoPoglavlje = zakacenoPoglavlje;
      });
    }
  }

  Future<void> _sacuvajStanjeZakacenogPoglavlja(
      Map<dynamic, dynamic> novoZakacenoPoglavlje) async {
    Box box = await Hive.box("parametri");
    box.put('zakaceno_poglavlje', novoZakacenoPoglavlje);

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
                      title: _latinica
                          ? cirilicaLatinica('Књига Библије')
                          : 'Књига Библије',
                      description: _latinica
                          ? cirilicaLatinica(
                              'Ово је једна од књига Библије коју можете прочитати кликом на њу. Оне се деле на Стари и Нови Завет и одређене поткатегорије.')
                          : 'Ово је једна од књига Библије коју можете прочитати кликом на њу. Оне се деле на Стари и Нови Завет и одређене поткатегорије.',
                      child: KarticaKnjige(
                        knjiga: knjiga,
                        izabranaVerzija: _izabranaVerzija,
                        zakacenoPoglavlje: _zakacenoPoglavlje,
                        sacuvajStanjeZakacenogPoglavlja:
                            _sacuvajStanjeZakacenogPoglavlja,
                        sortirajKnjige: _sortirajKnjige,
                        latinica: _latinica,
                      ),
                    );
                  } else {
                    return KarticaKnjige(
                      knjiga: knjiga,
                      izabranaVerzija: _izabranaVerzija,
                      zakacenoPoglavlje: _zakacenoPoglavlje,
                      sacuvajStanjeZakacenogPoglavlja:
                          _sacuvajStanjeZakacenogPoglavlja,
                      sortirajKnjige: _sortirajKnjige,
                      latinica: _latinica,
                    );
                  }
                }),
          ),

          // Pretraga knjiga
          Padding(
            padding: EdgeInsets.all(10),
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
                              contentPadding: EdgeInsets.symmetric(vertical: 0),
                              border: InputBorder.none,
                              hintText: _latinica
                                  ? cirilicaLatinica("Претражите књиге")
                                  : "Претражите књиге",
                            ),
                            controller: _kontrolerPretrage,
                            onChanged: (String unos) {
                              _filtrirajKnjige(unos);
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      // Showcase(
                      //   key: _filteri3,
                      //   targetBorderRadius: BorderRadius.circular(100),
                      //   tooltipBorderRadius: BorderRadius.circular(10),
                      //   tooltipPadding: EdgeInsets.all(15),
                      //   // onTargetClick: () {
                      //   //   _skrolujDo(_biblija3);
                      //   // },
                      //   titleTextStyle:
                      //       textTheme.titleMedium?.merge(TextStyle(
                      //     color: colors.primary,
                      //     fontWeight: FontWeight.bold,
                      //   )),
                      //   descTextStyle: textTheme.bodyMedium?.merge(TextStyle(
                      //     fontStyle: FontStyle.italic,
                      //   )),
                      //   title: 'Филтрирање књига',
                      //   description:
                      //       'Можете да филтрирате и претражите књиге по категорији и поткатегорији.',
                      //   child: IconButton(
                      //     onPressed: () async {
                      //       await showModalBottomSheet(
                      //         context: context,
                      //         builder: (context) => Padding(
                      //           padding: EdgeInsets.symmetric(horizontal: 10),
                      //           child: Column(
                      //             mainAxisSize: MainAxisSize.min,
                      //             crossAxisAlignment:
                      //                 CrossAxisAlignment.start,
                      //             children: [
                      //               Text(
                      //                 'Категорија',
                      //                 style: textTheme.titleLarge?.merge(
                      //                   TextStyle(
                      //                     color: colors.primary,
                      //                     fontWeight: FontWeight.bold,
                      //                   ),
                      //                 ),
                      //               ),
                      //               SizedBox(
                      //                 height: 10,
                      //               ),
                      //               Wrap(
                      //                 children: [
                      //                   for (int i = 0,
                      //                           len = _kategorije.length;
                      //                       i < len;
                      //                       i++)
                      //                     Row(
                      //                       mainAxisSize: MainAxisSize.min,
                      //                       children: [
                      //                         FilterChip(
                      //                           label: Text(_kategorije[i]
                      //                               ['naslov']),
                      //                           selected: _kategorije[i]
                      //                               ['stanje'],
                      //                           onSelected: (stanje) {
                      //                             setState(() {
                      //                               _kategorije[i]['stanje'] =
                      //                                   stanje;
                      //                             });
                      //                           },
                      //                         ),
                      //                         if (i < len - 1)
                      //                           SizedBox(
                      //                             width: 10,
                      //                           ),
                      //                       ],
                      //                     )
                      //                 ],
                      //               ),
                      //               SizedBox(height: 10,),
                      //               Text(
                      //                 'Поткатегорија',
                      //                 style: textTheme.titleLarge?.merge(
                      //                   TextStyle(
                      //                     color: colors.primary,
                      //                     fontWeight: FontWeight.bold,
                      //                   ),
                      //                 ),
                      //               ),
                      //               SizedBox(
                      //                 height: 10,
                      //               ),
                      //               Wrap(
                      //                 children: [
                      //                   for (int i = 0,
                      //                       len = _potkategorije.length;
                      //                   i < len;
                      //                   i++)
                      //                     Row(
                      //                       mainAxisSize: MainAxisSize.min,
                      //                       children: [
                      //                         FilterChip(
                      //                           label: Text(_potkategorije[i]
                      //                           ['naslov']),
                      //                           selected: _potkategorije[i]
                      //                           ['stanje'],
                      //                           onSelected: (stanje) {
                      //                             setState(() {
                      //                               _kategorije[i]['stanje'] =
                      //                                   stanje;
                      //                             });
                      //                           },
                      //                         ),
                      //                         if (i < len - 1)
                      //                           SizedBox(
                      //                             width: 10,
                      //                           ),
                      //                       ],
                      //                     )
                      //                 ],
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //         showDragHandle: true,
                      //         isScrollControlled: true,
                      //         useSafeArea: true,
                      //       );
                      //     },
                      //     icon: FaIcon(
                      //       FontAwesomeIcons.filter,
                      //       size: textTheme.titleLarge?.fontSize,
                      //       color: colors.primary,
                      //     ),
                      //     color: colors.surfaceVariant,
                      //   ),
                      // ),
                    ]),
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
    required this.sortirajKnjige,
    required this.latinica,
  }) : _izabranaVerzija = izabranaVerzija;

  final Knjiga knjiga;
  final Verzija _izabranaVerzija;
  final Map<dynamic, dynamic> zakacenoPoglavlje;
  final Function(Map<dynamic, dynamic>) sacuvajStanjeZakacenogPoglavlja;
  final Function() sortirajKnjige;
  final bool latinica;

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
        title: Text(latinica ? cirilicaLatinica(knjiga.naslov) : knjiga.naslov),
        titleTextStyle: textTheme.titleMedium?.merge(
          TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Podnaslov - kategorija i potkategorija
        subtitle: Text(latinica
            ? cirilicaLatinica("${knjiga.kategorija} / ${knjiga.potkategorija}")
            : "${knjiga.kategorija} / ${knjiga.potkategorija}"),
        subtitleTextStyle: textTheme.bodyMedium?.merge(
          TextStyle(
            fontStyle: FontStyle.italic,
          ),
        ),

        // Ikonica (ako je zakacena)
        trailing: zakacena
            ? IconButton(
                icon: FaIcon(
                  FontAwesomeIcons.solidBookmark,
                  color: colors.primary,
                ),
                iconSize: textTheme.titleLarge?.fontSize,
                onPressed: () {
                  sacuvajStanjeZakacenogPoglavlja({});
                  sortirajKnjige();
                  sacuvajStanjeZakacenogPoglavlja(
                      {'id_knjige': 0, 'indeks_poglavlja': 0});
                },
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
              latinica: latinica,
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
  final bool oglasiOmoguceni;
  final bool latinica;

  const ModalZaCitanje({
    super.key,
    required this.knjiga,
    required this.sadrzaj,
    this.indeksPoglavlja = 0,
    required this.sacuvajStanjeZakacenogPoglavlja,
    this.oglasiOmoguceni = true,
    required this.latinica,
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
  late bool _oglasiOmoguceni = true;
  late bool _latinica = false;

  BannerAd? _bannerAd;

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
      _oglasiOmoguceni = widget.oglasiOmoguceni;
      _latinica = widget.latinica;
    });

    if (_oglasiOmoguceni) {
      BannerAd(
        adUnitId: Oglasi.bannerAdUnitId,
        request: AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _bannerAd = ad as BannerAd;
            });
          },
          onAdFailedToLoad: (ad, err) {
            print('Failed to load a banner ad: ${err.message}');
            ad.dispose();
          },
        ),
      ).load();
    }

    await _ucitajStanjeZakacenog();
    await _ucitajStanjePrikazivanjaUputstva();
  }

  void dispose() {
    _skrolKontroler.dispose();
    _bannerAd?.dispose();
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
    box.put('zakaceno_poglavlje',
        {"indeks_poglavlja": _indeks_poglavlja, "id_knjige": _knjiga.id});

    widget.sacuvajStanjeZakacenogPoglavlja({
      "indeks_poglavlja": _indeks_poglavlja,
      "id_knjige": _knjiga.id,
    });
  }

  Future<void> _ucitajStanjeZakacenog() async {
    Box box = await Hive.box("parametri");
    Map<dynamic, dynamic>? zakacenoPoglavlje =
        box.get('zakaceno_poglavlje', defaultValue: null);

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
      disableMovingAnimation: true,
      builder: Builder(builder: (context) {
        if (_prikaziUputstva["biblija_nov_korisnik_citanje"] ?? false) {
          WidgetsBinding.instance.addPostFrameCallback((_) =>
              ShowCaseWidget.of(context).startShowCase(
                  [_naslov1, _podnaslov2, _stih3, _kontrole4, _dugme_zakaci5]));

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
                        title: _latinica
                            ? cirilicaLatinica('Наслов књиге')
                            : 'Наслов књиге',
                        description: _latinica
                            ? cirilicaLatinica(
                                'Овде се налази наслов отворене књиге.')
                            : 'Овде се налази наслов отворене књиге.',
                        child: Text(
                          _latinica
                              ? cirilicaLatinica(_knjiga.naslov)
                              : _knjiga.naslov,
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
                        title: _latinica
                            ? cirilicaLatinica('Наслов поглавља')
                            : 'Наслов поглавља',
                        description: _latinica
                            ? cirilicaLatinica(
                                'Књиге су подељене на поглавља, чије име се налази овде.')
                            : 'Књиге су подељене на поглавља, чије име се налази овде.',
                        child: Text(
                          _latinica
                              ? cirilicaLatinica(
                                  "${_indeks_poglavlja + 1}. ${poglavlje["naslov"]}")
                              : "${_indeks_poglavlja + 1}. ${poglavlje["naslov"]}",
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
                                targetPadding:
                                    EdgeInsets.symmetric(horizontal: 5),
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
                                title: _latinica
                                    ? cirilicaLatinica('Стих')
                                    : 'Стих',
                                description: _latinica
                                    ? cirilicaLatinica(
                                        'Поглавља су подељена на нумерисане стихове, а ово је један од њих.')
                                    : 'Поглавља су подељена на нумерисане стихове, а ово је један од њих.',
                                child: Stih(
                                  tekst: _latinica
                                      ? cirilicaLatinica(
                                          poglavlje["stihovi"][i])
                                      : poglavlje["stihovi"][i],
                                  indeks: i + 1,
                                ),
                              )
                            : Stih(
                                tekst: _latinica
                                    ? cirilicaLatinica(poglavlje["stihovi"][i])
                                    : poglavlje["stihovi"][i],
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: _bannerAd != null
                        ? EdgeInsets.symmetric(horizontal: 20)
                        : EdgeInsets.all(20),
                    child: Showcase(
                      key: _kontrole4,
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
                      title:
                          _latinica ? cirilicaLatinica('Контроле') : 'Контроле',
                      description: _latinica
                          ? cirilicaLatinica(
                              'Овде можете да прелиставате књигу по поглављима и видите на којем сте тренутно.')
                          : 'Овде можете да прелиставате књигу по поглављима и видите на којем сте тренутно.',
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
                                  _latinica
                                      ? cirilicaLatinica(
                                          "${_indeks_poglavlja + 1}. ${poglavlje["naslov"]}")
                                      : "${_indeks_poglavlja + 1}. ${poglavlje["naslov"]}",
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
                            titleTextStyle:
                                textTheme.titleMedium?.merge(TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            )),
                            descTextStyle:
                                textTheme.bodyMedium?.merge(TextStyle(
                              fontStyle: FontStyle.italic,
                            )),
                            title: _latinica
                                ? cirilicaLatinica('Ставите обележивач')
                                : 'Ставите обележивач',
                            description: _latinica
                                ? cirilicaLatinica(
                                    'Када завршите са читањем, оставите обележивач како бисте могли да наставите.')
                                : 'Када завршите са читањем, оставите обележивач како бисте могли да наставите.',
                            child: FloatingActionButton.small(
                              onPressed: () {
                                _sacuvajStanjeZakacenog();
                                Navigator.pop(context);
                              },
                              child: FaIcon(
                                _indeks_poglavlja ==
                                            _indeks_zakacenog_poglavlja &&
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
                                if (_indeks_poglavlja <
                                    widget.sadrzaj.length - 1) {
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
                  if (_bannerAd != null && _oglasiOmoguceni)
                    Container(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                ],
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
