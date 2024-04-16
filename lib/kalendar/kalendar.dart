import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:table_calendar/table_calendar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:veronauka/kalendar/praznik.dart';
import 'package:veronauka/kalendar/dan.dart';
import 'package:veronauka/latinica_cirilica.dart';
import 'package:veronauka/oglasi.dart';

class Kalendar extends StatefulWidget {
  final bool latinica;

  const Kalendar({super.key, required this.latinica});

  @override
  State<Kalendar> createState() => _KalendarState();
}

class _KalendarState extends State<Kalendar> {
  DateTime _izabranDan = DateTime.now();
  DateTime _fokusiranDan = DateTime.now();

  List<int> _godine = [];
  List<List<List<Dan>>> _kalendar = [];

  GlobalKey _kalendar1 = GlobalKey();
  GlobalKey _praznici2 = GlobalKey();

  Map<dynamic, dynamic> _prikaziUputstva = {};
  bool _latinica = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() async {
    await _ucitajGodine();
    await _ucitajKalendar();

    await _ucitajStanjePrikazivanjaUputstva();

    setState(() {
      _latinica = widget.latinica;
    });

    if (_prikaziUputstva["kalendar_nov_korisnik"]) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          ShowCaseWidget.of(context).startShowCase([_kalendar1, _praznici2]));

      setState(() {
        _prikaziUputstva["kalendar_nov_korisnik"] = false;
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

  Future<void> _ucitajGodine() async {
    String jsonNiska =
        await rootBundle.loadString("podaci/kalendar/godine.json");

    setState(() {
      _godine = (json.decode(jsonNiska) as List<dynamic>).cast<int>();
    });
  }

  Future<void> _ucitajKalendar() async {
    List<List<List<Dan>>> kalendar = [];

    for (int i = 0, len = _godine.length; i < len; i++) {
      String jsonNiska = await rootBundle
          .loadString("podaci/kalendar/godine/godina-${_godine[i]}.json");
      List<dynamic> dekodiranaGodina = json.decode(jsonNiska);

      List<List<Dan>> godina = [
        // Za svaki mesec
        for (int j = 0, len = dekodiranaGodina.length; j < len; j++)
          [
            // Za svaki dan
            for (int k = 0, len1 = dekodiranaGodina[j].length; k < len1; k++)
              Dan(
                dan: DateTime.utc(_godine[i], j + 1, k + 1),
                praznici: [
                  // Za svaki praznik
                  for (int l = 0,
                          len2 = dekodiranaGodina[j][k]["praznici"].length;
                      l < len2;
                      l++)
                    Praznik(
                      naslov: dekodiranaGodina[j][k]["praznici"][l]["naslov"],
                      crnoSlovo: dekodiranaGodina[j][k]["praznici"][l]
                              ["crnoSlovo"] ??
                          false,
                      crvenoSlovo: dekodiranaGodina[j][k]["praznici"][l]
                              ["crvenoSlovo"] ??
                          false,
                      opis: dekodiranaGodina[j][k]["praznici"][l]["opis"] ??
                          'О данашњем празнику, ускоро...',
                      izvorOpisa: dekodiranaGodina[j][k]["praznici"][l]
                              ["izvorOpisa"] ??
                          'Охридски пролог',
                    )
                ],
              )
          ]
      ];

      setState(() {
        _kalendar.add(godina);
      });
    }
  }

  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    if (_kalendar.isNotEmpty) {
      Dan dan = _kalendar[_fokusiranDan.year - _godine[0]]
          [_fokusiranDan.month - 1][_fokusiranDan.day - 1];

      return Container(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Showcase(
                key: _kalendar1,
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
                    ? cirilicaLatinica('Црквени календар')
                    : 'Црквени календар',
                description: _latinica
                    ? cirilicaLatinica(
                        'Одабери датум о чијим празницима желиш да сазнаш. Подебљани, црни датуми представљају црна, а црвени црвена слова.')
                    : 'Одабери датум о чијим празницима желиш да сазнаш. Подебљани, црни датуми представљају црна, а црвени црвена слова.',
                child: Card(
                  child: TableCalendar(
                    firstDay: DateTime.utc(_godine.first, 1, 1),
                    lastDay: DateTime.utc(_godine.last, 12, 31),
                    focusedDay: _fokusiranDan,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                    ),
                    calendarStyle: CalendarStyle(
                      rangeHighlightColor: colors.primary,
                      weekendTextStyle: textTheme.bodyLarge!.merge(TextStyle(
                        color: colors.outline,
                      )),
                      cellAlignment: Alignment.center,
                      outsideDaysVisible: false,
                    ),
                    rowHeight: 45,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    locale: "sr-RS",
                    selectedDayPredicate: (day) {
                      return isSameDay(_izabranDan, day);
                    },
                    onDaySelected: (izabran, fokusiran) {
                      setState(() {
                        _izabranDan = izabran;
                        _fokusiranDan = fokusiran;
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, events) {
                        Dan dan = _kalendar[date.year - _godine[0]]
                            [date.month - 1][date.day - 1];

                        TextStyle stilTeksta = TextStyle();
                        if (dan.praznici.isNotEmpty) {
                          if (dan.praznici
                                  .any((praznik) => praznik.crvenoSlovo) ||
                              date.weekday == 7) {
                            stilTeksta = TextStyle(
                              // Primarna boja u crvenoj nijansi
                              color: colors.error,
                              fontWeight: FontWeight.bold,
                            );
                          } else if (dan.praznici
                              .any((praznik) => praznik.crnoSlovo)) {
                            stilTeksta = TextStyle(fontWeight: FontWeight.bold);
                          }
                        }

                        return Center(
                          child: Text(
                            '${date.day}',
                            style: textTheme.bodyLarge?.merge(stilTeksta),
                          ),
                        );
                      },
                      selectedBuilder: (context, date, events) {
                        Dan dan = _kalendar[date.year - _godine[0]]
                            [date.month - 1][date.day - 1];

                        TextStyle stilTeksta = TextStyle();
                        if (dan.praznici.isNotEmpty) {
                          if (dan.praznici.any((praznik) =>
                              praznik.crvenoSlovo || date.weekday == 7)) {
                            stilTeksta = TextStyle(
                              // Primarna boja u crvenoj nijansi
                              color: colors.error,
                              fontWeight: FontWeight.bold,
                            );
                          } else if (dan.praznici
                              .any((praznik) => praznik.crnoSlovo)) {
                            stilTeksta = TextStyle(fontWeight: FontWeight.bold);
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.all(6),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: textTheme.bodyLarge?.merge(stilTeksta),
                              ),
                            ),
                          ),
                        );
                      },
                      todayBuilder: (context, date, events) {
                        Dan dan = _kalendar[date.year - _godine[0]]
                            [date.month - 1][date.day - 1];

                        TextStyle stilTeksta = TextStyle();
                        if (dan.praznici.isNotEmpty) {
                          if (dan.praznici
                              .any((praznik) => praznik.crvenoSlovo)) {
                            stilTeksta = TextStyle(
                              // Primarna boja u crvenoj nijansi
                              color: HSLColor.fromColor(colors.primary)
                                  .withHue(0)
                                  .toColor(),
                              fontWeight: FontWeight.bold,
                            );
                          } else if (dan.praznici
                              .any((praznik) => praznik.crnoSlovo)) {
                            stilTeksta = TextStyle(fontWeight: FontWeight.bold);
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.all(6),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: textTheme.bodyLarge?.merge(stilTeksta),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Showcase(
                key: _praznici2,
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
                    ? cirilicaLatinica('Листа празника')
                    : 'Листа празника',
                description: _latinica
                    ? cirilicaLatinica(
                        'Овде се појављују празници за тражени датум. Црвена и црна слова су обележена одговарајућим стилом.')
                    : 'Овде се појављују празници за тражени датум. Црвена и црна слова су обележена одговарајућим стилом.',
                child: Column(
                  children: [
                    for (int i = 0, len = dan.praznici.length; i < len; i++)
                      (index) {
                        Praznik praznik = dan.praznici[index];

                        if (index == 0) {
                          return AnimatedSwitcher(
                            duration: Duration(milliseconds: 500),
                            key: UniqueKey(),
                            child: Card(
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                title: Text(_latinica
                                    ? cirilicaLatinica(praznik.naslov)
                                    : praznik.naslov),
                                titleTextStyle:
                                    textTheme.titleMedium?.merge(TextStyle(
                                  color: praznik.crnoSlovo
                                      ? null
                                      : praznik.crvenoSlovo
                                          ? colors.error
                                          : colors.primary,
                                  fontWeight:
                                      praznik.crnoSlovo || praznik.crvenoSlovo
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                )),
                                subtitleTextStyle: textTheme.bodyMedium?.merge(
                                    TextStyle(fontStyle: FontStyle.italic)),
                                // onTap: () {
                                //   showModalBottomSheet(
                                //     context: context,
                                //     builder: (context) =>
                                //         ModalZaPraznik(praznik: praznik),
                                //     showDragHandle: true,
                                //     isScrollControlled: true,
                                //     useSafeArea: true,
                                //   );
                                // },
                              ),
                            ),
                          );
                        } else {
                          return AnimatedSwitcher(
                            duration: Duration(milliseconds: 500),
                            key: UniqueKey(),
                            child: Card(
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                title: Text(_latinica
                                    ? cirilicaLatinica(praznik.naslov)
                                    : praznik.naslov),
                                titleTextStyle:
                                    textTheme.titleMedium?.merge(TextStyle(
                                  color: praznik.crnoSlovo
                                      ? null
                                      : praznik.crvenoSlovo
                                          ? colors.error
                                          : colors.primary,
                                  fontWeight:
                                      praznik.crnoSlovo || praznik.crvenoSlovo
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                )),
                                subtitleTextStyle: textTheme.bodyMedium?.merge(
                                    TextStyle(fontStyle: FontStyle.italic)),
                                // onTap: () {
                                //   showModalBottomSheet(
                                //     context: context,
                                //     builder: (context) =>
                                //         ModalZaPraznik(praznik: praznik),
                                //     showDragHandle: true,
                                //     isScrollControlled: true,
                                //     useSafeArea: true,
                                //   );
                                // },
                              ),
                            ),
                          );
                        }
                      }(i)
                  ],
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

class ModalZaPraznik extends StatefulWidget {
  final Praznik praznik;

  const ModalZaPraznik({super.key, required this.praznik});

  @override
  State<ModalZaPraznik> createState() => _ModalZaPraznikState();
}

class _ModalZaPraznikState extends State<ModalZaPraznik> {
  bool _oglasiOmoguceni = true;
  BannerAd? _bannerAd;

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
                  widget.praznik.naslov,
                  style: textTheme.titleLarge?.merge(
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.praznik.crvenoSlovo
                          ? HSLColor.fromColor(colors.primary)
                              .withHue(0)
                              .toColor()
                          : !widget.praznik.crnoSlovo
                              ? colors.primary
                              : null,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  widget.praznik.opis,
                  style: textTheme.bodyLarge,
                ),
                SizedBox(height: 20),
                Text(
                  'Извор: ${widget.praznik.izvorOpisa}',
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
