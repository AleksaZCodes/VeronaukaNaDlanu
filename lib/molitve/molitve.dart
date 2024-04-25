import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:veronauka/oglasi.dart';

import 'package:veronauka/molitve/molitva.dart';
import 'package:veronauka/latinica_cirilica.dart';

class Molitve extends StatefulWidget {
  final bool latinica;

  const Molitve({super.key, required this.latinica});

  @override
  State<Molitve> createState() => _MolitveState();
}

class _MolitveState extends State<Molitve> {
  TextEditingController _kontrolerPretrage = TextEditingController();
  List<Molitva> _molitve = [];
  List<Molitva> _filtriraneMolitve = [];
  bool _latinica = false;

  GlobalKey _molitva1 = GlobalKey();
  GlobalKey _dugme_zakaci2 = GlobalKey();

  Map<dynamic, dynamic> _prikaziUputstva = {};

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() async {
    await _ucitajMolitve();
    await _ucitajStanjeZakacenih();

    await _ucitajStanjePrikazivanjaUputstva();

    setState(() {
      _filtriraneMolitve = _molitve;
      _latinica = widget.latinica;
    });

    if (_prikaziUputstva["molitve_nov_korisnik"]) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          ShowCaseWidget.of(context)
              .startShowCase([_molitva1, _dugme_zakaci2]));

      setState(() {
        _prikaziUputstva["molitve_nov_korisnik"] = false;
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

  Future<void> _ucitajStanjeZakacenih() async {
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
      });
    }
  }

  void _sacuvajStanjeZakacenih() async {
    Box box = await Hive.box("parametri");

    // Napravi listu identifikatora zakacenih i sacuvaj je
    List<int> idZakacenihMolitvi = _molitve
        .where((molitva) => molitva.zakaceno)
        .map((molitva) => molitva.id)
        .toList();
    box.put('zakacene_molitve', idZakacenihMolitvi);
  }

  void _filtrirajMolitve(String unos) {
    setState(() {
      _filtriraneMolitve = _molitve.where((molitva) {
        String naslov = latinicaCirilica(molitva.naslov.toLowerCase());
        String telo = latinicaCirilica(molitva.telo.toLowerCase());
        String unosCirilica = latinicaCirilica(unos.trim().toLowerCase());

        return naslov.contains(unosCirilica) || telo.contains(unosCirilica);
      }).toList();
    });
  }

  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    _filtriraneMolitve.sort((a, b) => a.id - b.id);

    // Podeli molitve na zakacene i klasicne
    List<Molitva> zakaceneMolitve =
        _filtriraneMolitve.where((molitva) => molitva.zakaceno).toList();
    List<Molitva> klasicneMolitve =
        _filtriraneMolitve.where((molitva) => !molitva.zakaceno).toList();

    // Spoji tako da su zakacene prve
    _filtriraneMolitve = [...zakaceneMolitve, ...klasicneMolitve];

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView.builder(
                  itemCount: _filtriraneMolitve.length,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  physics: AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    Molitva molitva = _filtriraneMolitve[index];

                    if (index == 0) {
                      return Showcase(
                        key: _molitva1,
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
                            _latinica ? cirilicaLatinica('Молитва') : 'Молитва',
                        description: _latinica
                            ? cirilicaLatinica(
                                'Ово је једна молитва из листе. Можете да је прочитате кликом на њу.')
                            : 'Ово је једна молитва из листе. Можете да је прочитате кликом на њу.',
                        child: Card(
                          key: ValueKey(molitva.id),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            title: Text(_latinica
                                ? cirilicaLatinica(molitva.naslov)
                                : molitva.naslov),
                            titleTextStyle:
                                textTheme.titleMedium?.merge(TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            )),
                            subtitle: Text(
                              // Zameni \n sa razmakom za vise prikazanog teksta
                              _latinica
                                  ? cirilicaLatinica(molitva.telo
                                      .replaceAll(RegExp(r'\n\s*'), ' '))
                                  : molitva.telo
                                      .replaceAll(RegExp(r'\n\s*'), ' '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitleTextStyle: textTheme.bodyMedium
                                ?.merge(TextStyle(fontStyle: FontStyle.italic)),
                            trailing: Showcase(
                              key: _dugme_zakaci2,
                              targetBorderRadius: BorderRadius.circular(100),
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
                                  ? cirilicaLatinica('Закачите молитву')
                                  : 'Закачите молитву',
                              description: _latinica
                                  ? cirilicaLatinica(
                                      'Можете да закачите молитву на врх листе како би била на дохват руке.')
                                  : 'Можете да закачите молитву на врх листе како би била на дохват руке.',
                              child: IconButton(
                                icon: FaIcon(
                                  molitva.zakaceno
                                      ? FontAwesomeIcons.solidBookmark
                                      : FontAwesomeIcons.bookmark,
                                  color: colors.primary,
                                ),
                                iconSize: textTheme.titleLarge?.fontSize,
                                onPressed: () {
                                  setState(() {
                                    molitva.zakaceno = !molitva.zakaceno;
                                    _sacuvajStanjeZakacenih();
                                  });
                                },
                              ),
                            ),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => ModalZaMolitvu(
                                  molitva: molitva,
                                  latinica: _latinica,
                                ),
                                showDragHandle: true,
                                isScrollControlled: true,
                                useSafeArea: true,
                              );
                            },
                          ),
                        ),
                      );
                    } else {
                      return Card(
                        key: ValueKey(molitva.id),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          title: Text(_latinica
                              ? cirilicaLatinica(molitva.naslov)
                              : molitva.naslov),
                          titleTextStyle:
                              textTheme.titleMedium?.merge(TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          )),
                          subtitle: Text(
                            // Zameni \n sa razmakom za vise prikazanog teksta
                            _latinica
                                ? cirilicaLatinica(molitva.telo
                                    .replaceAll(RegExp(r'\n\s*'), ' '))
                                : molitva.telo
                                    .replaceAll(RegExp(r'\n\s*'), ' '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitleTextStyle: textTheme.bodyMedium
                              ?.merge(TextStyle(fontStyle: FontStyle.italic)),
                          trailing: IconButton(
                            icon: FaIcon(
                              molitva.zakaceno
                                  ? FontAwesomeIcons.solidBookmark
                                  : FontAwesomeIcons.bookmark,
                              color: colors.primary,
                            ),
                            iconSize: textTheme.titleLarge?.fontSize,
                            onPressed: () {
                              setState(() {
                                molitva.zakaceno = !molitva.zakaceno;
                                _sacuvajStanjeZakacenih();
                              });
                            },
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => ModalZaMolitvu(
                                molitva: molitva,
                                latinica: _latinica,
                              ),
                              showDragHandle: true,
                              isScrollControlled: true,
                              useSafeArea: true,
                            );
                          },
                        ),
                      );
                    }
                  }),
            ),
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
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 0),
                                border: InputBorder.none,
                                hintText: _latinica
                                    ? cirilicaLatinica("Претражите молитве")
                                    : "Претражите молитве",
                              ),
                              controller: _kontrolerPretrage,
                              onChanged: (String unos) {
                                _filtrirajMolitve(unos);
                              },
                            ),
                          ),
                        ),
                      ]),
                ),
              ),
            ),
          ],
        ),
        if (_molitve.isEmpty)
          Center(
            child: CircularProgressIndicator(), // Show a loading indicator
          ),
      ],
    );
  }
}

class ModalZaMolitvu extends StatefulWidget {
  final Molitva molitva;
  final bool latinica;

  const ModalZaMolitvu(
      {super.key, required this.molitva, required this.latinica});

  @override
  State<ModalZaMolitvu> createState() => _ModalZaMolitvuState();
}

class _ModalZaMolitvuState extends State<ModalZaMolitvu> {
  bool _oglasiOmoguceni = true;
  BannerAd? _bannerAd;
  bool _latinica = false;

  @override
  void initState() {
    super.initState();
    setup();
  }

  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void setup() async {
    await _ucitajStanjeOmogucenostiOglasa();

    setState(() {
      _latinica = widget.latinica;
    });

    if (_oglasiOmoguceni) {
      BannerAd(
        adUnitId: Oglasi.bannerMolitveAdUnitId,
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
  }

  Future<void> _ucitajStanjeOmogucenostiOglasa() async {
    // Ucitaj box parametara
    Box box = await Hive.box("parametri");

    setState(() {
      _oglasiOmoguceni = box.get('oglasi_omoguceni', defaultValue: true);
    });
  }

  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    return Stack(children: [
      ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _latinica
                      ? cirilicaLatinica(widget.molitva.naslov)
                      : widget.molitva.naslov,
                  style: textTheme.titleLarge?.merge(TextStyle(
                      fontWeight: FontWeight.bold, color: colors.primary)),
                ),
                SizedBox(height: 20),
                Text(
                  _latinica
                      ? cirilicaLatinica(widget.molitva.telo)
                      : widget.molitva.telo,
                  style: textTheme.bodyLarge,
                ),
                SizedBox(height: 20),
                Text(
                  _latinica
                      ? cirilicaLatinica('Извор: ${widget.molitva.izvor}')
                      : 'Извор: ${widget.molitva.izvor}',
                  style: textTheme.labelLarge
                      ?.merge(TextStyle(color: colors.primary)),
                ),
                SizedBox(
                  height: 50,
                )
              ],
            ),
          )
        ],
      ),
      if (_bannerAd != null && _oglasiOmoguceni)
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        )
    ]);
  }
}
