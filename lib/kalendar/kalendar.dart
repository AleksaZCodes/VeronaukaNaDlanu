import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:table_calendar/table_calendar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:veronauka/kalendar/praznik.dart';
import 'package:veronauka/kalendar/dan.dart';

class Kalendar extends StatefulWidget {
  const Kalendar({super.key});

  @override
  State<Kalendar> createState() => _KalendarState();
}

class _KalendarState extends State<Kalendar> {
  DateTime _izabranDan = DateTime.now();
  DateTime _fokusiranDan = DateTime.now();

  List<List<Dan>> _kalendar = [];

  GlobalKey _kalendar1 = GlobalKey();
  GlobalKey _praznici2 = GlobalKey();
  GlobalKey _praznik3 = GlobalKey();

  Map<dynamic, dynamic> _prikaziUputstva = {};

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() async {
    await _ucitajKalendar();

    await _ucitajStanjePrikazivanjaUputstva();

    if (_prikaziUputstva["kalendar_nov_korisnik"]) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          ShowCaseWidget.of(context)
              .startShowCase([_kalendar1, _praznici2, _praznik3]));

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

  Future<void> _ucitajKalendar() async {
    String jsonNiska =
        await rootBundle.loadString("podaci/kalendar/godine/godina-2023.json");
    List<dynamic> dekodiranKalendar = json.decode(jsonNiska);

    setState(() {
      _kalendar = [
        // Za svaki mesec
        for (int i = 0, len = dekodiranKalendar.length; i < len; i++)
          [
            // Za svaki dan
            for (int j = 0, len1 = dekodiranKalendar[i].length; j < len1; j++)
              Dan(
                objasnjenje: dekodiranKalendar[i][j]["objasnjenje"],
                dan: DateTime.utc(2023, i + 1, j + 1),
                praznici: [
                  // Za svaki praznik
                  for (int k = 0,
                          len2 = dekodiranKalendar[i][j]["praznici"].length;
                      k < len2;
                      k++)
                    Praznik(
                      naslov: dekodiranKalendar[i][j]["praznici"][k]["naslov"],
                      crnoSlovo: dekodiranKalendar[i][j]["praznici"][k]
                              ["crnoSlovo"] ??
                          false,
                      crvenoSlovo: dekodiranKalendar[i][j]["praznici"][k]
                              ["crvenoSlovo"] ??
                          false,
                    )
                ],
              )
          ]
      ];
    });
  }

  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    if (_kalendar.isNotEmpty) {
      Dan dan = _kalendar[_fokusiranDan.month - 1][_fokusiranDan.day - 1];

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
                title: 'Црквени календар',
                description:
                    'Одабери датум о чијим празницима желиш да сазнаш. Подебљани, црни датуми представљају црна, а црвени црвена слова.',
                child: Card(
                  child: TableCalendar(
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2023, 12, 31),
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
                    locale: "sr_RS",
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
                        Dan dan = _kalendar[date.month - 1][date.day - 1];

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

                        return Center(
                          child: Text(
                            '${date.day}',
                            style: textTheme.bodyLarge?.merge(stilTeksta),
                          ),
                        );
                      },
                      selectedBuilder: (context, date, events) {
                        Dan dan = _kalendar[date.month - 1][date.day - 1];

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
                        Dan dan = _kalendar[date.month - 1][date.day - 1];

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
                title: 'Листа празника',
                description:
                    'Овде се појављују празници за тражени датум. Црвена и црна слова су обележена одговарајућим стилом.',
                child: Column(
                  children: [
                    for (int i = 0, len = dan.praznici.length; i < len; i++)
                      (index) {
                        Praznik praznik = dan.praznici[index];

                        if (index == 0) {
                          return Showcase(
                              key: _praznik3,
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
                        title: 'Празник',
                        description:
                        'СПЦ сваког дана прославља одређене светитеље. Они значајнији обележени су дебљим словима и бојама.',
                        child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 500),
                            key: UniqueKey(),
                            child: Card(
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                title: Text(praznik.naslov),
                                titleTextStyle:
                                textTheme.titleMedium?.merge(TextStyle(
                                  color: praznik.crnoSlovo
                                      ? null
                                      : praznik.crvenoSlovo
                                      ? HSLColor.fromColor(colors.primary)
                                      .withHue(0)
                                      .toColor()
                                      : colors.primary,
                                  fontWeight:
                                  praznik.crnoSlovo || praznik.crvenoSlovo
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                )),
                                subtitle: dan.objasnjenje.isNotEmpty
                                    ? Text(
                                  dan.objasnjenje,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                                    : null,
                                subtitleTextStyle: textTheme.bodyMedium?.merge(
                                    TextStyle(fontStyle: FontStyle.italic)),
                                // onTap: () {
                                //   showModalBottomSheet(
                                //     context: context,
                                //     builder: (context) =>
                                //         ModalZaMolitvu(molitva: molitva),
                                //     showDragHandle: true,
                                //     isScrollControlled: true,
                                //     useSafeArea: true,
                                //   );
                                // },
                              ),
                            ),
                          ),);
                        } else {
                          return AnimatedSwitcher(
                            duration: Duration(milliseconds: 500),
                            key: UniqueKey(),
                            child: Card(
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                title: Text(praznik.naslov),
                                titleTextStyle:
                                textTheme.titleMedium?.merge(TextStyle(
                                  color: praznik.crnoSlovo
                                      ? null
                                      : praznik.crvenoSlovo
                                      ? HSLColor.fromColor(colors.primary)
                                      .withHue(0)
                                      .toColor()
                                      : colors.primary,
                                  fontWeight:
                                  praznik.crnoSlovo || praznik.crvenoSlovo
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                )),
                                subtitle: dan.objasnjenje.isNotEmpty
                                    ? Text(
                                  dan.objasnjenje,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                                    : null,
                                subtitleTextStyle: textTheme.bodyMedium?.merge(
                                    TextStyle(fontStyle: FontStyle.italic)),
                                // onTap: () {
                                //   showModalBottomSheet(
                                //     context: context,
                                //     builder: (context) =>
                                //         ModalZaMolitvu(molitva: molitva),
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
