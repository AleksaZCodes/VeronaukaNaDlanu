import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:veronauka/latinica_cirilica.dart';
import 'package:veronauka/oglasi.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';

class DobraDela extends StatefulWidget {
  final bool latinica;

  const DobraDela({super.key, required this.latinica});

  @override
  State<DobraDela> createState() => _DobraDelaState();
}

class _DobraDelaState extends State<DobraDela> {
  bool _ucitano = false;
  bool _oglasiOmoguceni = true;
  RewardedAd? _rewardedAd;
  int _delo = 0;
  bool _latinica = false;

  GlobalKey _delo1 = GlobalKey();
  GlobalKey _delo2 = GlobalKey();
  GlobalKey _delo3 = GlobalKey();

  Map<dynamic, dynamic> _prikaziUputstva = {};

  @override
  void initState() {
    super.initState();

    _setup();
  }

  void dispose() {
    _rewardedAd?.dispose();

    super.dispose();
  }

  void _setup() async {
    await _ucitajStanjeOmogucenostiOglasa();

    if (_oglasiOmoguceni) {
      await _ucitajOglas();
    }

    await _ucitajStanjePrikazivanjaUputstva();

    await _ucitajStanjeIstaknutogDela();

    setState(() {
      _latinica = widget.latinica;
      _ucitano = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) =>
        ShowCaseWidget.of(context).startShowCase([_delo1, _delo2, _delo3]));

    _prikaziUputstva["dobra_dela_nov_korisnik"] = false;

    await _sacuvajStanjePrikazivanjaUputstva();
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

  Future<void> _ucitajStanjeOmogucenostiOglasa() async {
    // Ucitaj box parametara
    Box box = await Hive.box("parametri");

    setState(() {
      _oglasiOmoguceni = box.get('oglasi_omoguceni', defaultValue: true);
    });
  }

  Future<void> _ucitajStanjeIstaknutogDela() async {
    Box box = await Hive.box("parametri");

    setState(() {
      _delo = box.get("istaknuto_delo", defaultValue: 0) % brojDela;
    });

    box.put("istaknuto_delo", _delo + 1);
  }

  void _sacuvajStanjeOmogucenostiOglasa(bool stanje) async {
    // Sacuvaj suprotnu vrednost u globalno stanje
    Box box = await Hive.box('parametri');
    box.put('oglasi_omoguceni', !_oglasiOmoguceni);

    // Izvrni trenutnu vrednost lokalnog stanja
    setState(() {
      _oglasiOmoguceni = stanje;
    });
  }

  Future<void> _ucitajOglas() async {
    await RewardedAd.load(
        adUnitId: Oglasi.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            debugPrint('$ad loaded.');
            // Keep a reference to the ad so you can show it later.
            setState(() {
              _rewardedAd = ad;
            });
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('RewardedAd failed to load: $error');
          },
        ));
  }

  Future<void> _prikaziOglas() async {
    await _ucitajOglas();

    if (_rewardedAd != null) {
      _rewardedAd?.show(onUserEarnedReward: (reward, item) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Хвала што сте погледали оглас!\nУчинили сте добро дело.",
              // Број прегледаних огласа: ${1}
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
        );
      });
    }
  }

  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    List<Delo> _dela = _latinica
        ? delaLatinica(context, textTheme, colors)
        : dela(context, textTheme, colors);
    Delo _istaknuto_delo = _dela[_delo];
    _dela.removeAt(_delo);

    if (_ucitano) {
      return ListView(
        children: [
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
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Delo(
                  textTheme: textTheme,
                  colors: colors,
                  naslov: _latinica
                      ? cirilicaLatinica('Погледајте оглас, повећајте допринос')
                      : 'Погледајте оглас, повећајте допринос',
                  objasnjenje: _latinica
                      ? cirilicaLatinica(
                          'Проценат зараде од огласа иде програмеру за одржавање апликације, док већина иде у хуманитарне сврхе.')
                      : 'Проценат зараде од огласа иде програмеру за одржавање апликације, док већина иде у хуманитарне сврхе.',
                  akcije: [
                    {
                      'stanje': _rewardedAd != null,
                      'tekst': _latinica
                          ? cirilicaLatinica('Учитај оглас')
                          : 'Учитај оглас',
                      'tekst_kliknuto': _latinica
                          ? cirilicaLatinica('Учитавање...')
                          : 'Учитавање...',
                      'callback': () async {
                        await _ucitajOglas();
                      },
                      'callback_kliknuto': () {}
                    },
                  ],
                ),
              ),
            ),
          ),

          ...(_dela
              .map((d) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: d,
                      ),
                    ),
                  ))
              .toList())

          // Omogucite oglase
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 10),
          //   child: Delo(
          //       colors: colors,
          //       textTheme: textTheme,
          //       naslov: 'Омогућите огласе, бесплатно је',
          //       objasnjenje:
          //           'Само користећи апликацију уз огласе генеришете новац који се донира хуманитарним организацијама.',
          //       akcije: [
          //         {
          //           'stanje': !_oglasiOmoguceni,
          //           'tekst': 'Омогући огласе',
          //           'callback': () {
          //             _sacuvajStanjeOmogucenostiOglasa(true);
          //             ScaffoldMessenger.of(context).showSnackBar(
          //               SnackBar(
          //                 content: Text(
          //                   "Хвала што сте омогућили огласе! Учинили сте добро дело.",
          //                   style: textTheme.bodyMedium,
          //                 ),
          //                 backgroundColor: colors.surfaceVariant,
          //               ),
          //             );
          //           },
          //           'tekst_kliknuto': 'Онемогући огласе',
          //           'callback_kliknuto': () {
          //             _sacuvajStanjeOmogucenostiOglasa(false);
          //             ScaffoldMessenger.of(context).showSnackBar(
          //               SnackBar(
          //                 content: Text(
          //                   "Дајте још једну шансу огласима, не сметају толико... Поштујемо Вашу одлуку свакако.",
          //                   style: textTheme.bodyMedium,
          //                 ),
          //                 backgroundColor: colors.surfaceVariant,
          //               ),
          //             );
          //           },
          //         }
          //       ],
          //   ),
          // ),

          // Donirajte novac
          // Card(
          //   child: Padding(
          //     padding: const EdgeInsets.all(15),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Text(
          //           "Донирајте новац, помозите другима",
          //           style: textTheme.titleMedium?.merge(TextStyle(
          //             color: colors.primary,
          //             fontWeight: FontWeight.bold,
          //           )),
          //         ),
          //         SizedBox(height: 8),
          //         Text(
          //           'Једнократно донирајте неку суму новца.',
          //           style: textTheme.bodyMedium?.merge(TextStyle(
          //             fontStyle: FontStyle.italic,
          //           )),
          //         ),
          //         SizedBox(height: 8),
          //         Align(
          //           alignment: Alignment.centerRight,
          //           child: FilledButton(
          //             onPressed: () {},
          //             child: Text(
          //               "Донирај новац",
          //               style: textTheme.bodyMedium?.merge(TextStyle(
          //                 color: colors.background,
          //                 fontStyle: FontStyle.italic,
          //                 fontWeight: FontWeight.bold,
          //               )),
          //             ),
          //           ),
          //         )
          //       ],
          //     ),
          //   ),
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

int brojDela = 4;

List<Delo> dela(context, textTheme, colors) => [
      Delo(
        textTheme: textTheme,
        colors: colors,
        naslov: 'Помозите да други сазнају за апликацију',
        objasnjenje:
            'Издвојите минут да поделите апликацију како би и остали почели да је користе.',
        akcije: [
          {
            'stanje': true,
            'tekst': 'Подели',
            'callback': () async {
              ShareResult rezultat = await Share.shareWithResult(
                "Инсталирајте апликацију Веронаука на длану!",
              );
              if (rezultat.status == ShareResultStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Хвала на дељењу!\nУчинили сте добро дело.",
                      style: textTheme.bodyMedium,
                    ),
                    backgroundColor: colors.surfaceVariant,
                  ),
                );
              }
            }
          }
        ],
      ),
      Delo(
        textTheme: textTheme,
        colors: colors,
        naslov: 'Запратите оца Предрага Поповића',
        objasnjenje:
            'Отац Пеђа је православни свештеник који мисионарећи путем интернета говори о релевантним темама у Православљу.',
        akcije: [
          {
            'stanje': true,
            'tekst': 'Запрати',
            'callback': () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Хвала на праћењу!\nУчинили сте себи и другима добро дело.",
                    style: textTheme.bodyMedium,
                  ),
                  backgroundColor: colors.surfaceVariant,
                ),
              );
              launchUrl(
                Uri.parse(
                  'https://www.youtube.com/@otacpredragpopovic',
                ),
              );
            },
          },
          {
            'stanje': true,
            'tekst': 'Сајт',
            'callback': () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Хвала на посети сајта!\nУчинили сте добро дело.",
                    style: textTheme.bodyMedium,
                  ),
                  backgroundColor: colors.surfaceVariant,
                ),
              );
              launchUrl(
                Uri.parse(
                  'https://otacpredrag.com/',
                ),
              );
            },
          },
        ],
      ),
      Delo(
        textTheme: textTheme,
        colors: colors,
        naslov: 'Подржите организацију Срби за Србе',
        objasnjenje:
            'Срби за Србе је светска хуманитарна организација која помаже социјално угроженим породицама широм Балкана.',
        akcije: [
          {
            'stanje': true,
            'tekst': 'Посети сајт',
            'callback': () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Хвала на посети сајта!\nУчинили сте добро дело.",
                    style: textTheme.bodyMedium,
                  ),
                  backgroundColor: colors.surfaceVariant,
                ),
              );
              launchUrl(
                Uri.parse(
                  'https://www.srbizasrbe.org/',
                ),
              );
            },
          },
        ],
      ),
      Delo(
        textTheme: textTheme,
        colors: colors,
        naslov: 'Помозите рад верског добротворног старатељства Епархије нишке',
        objasnjenje:
            'В. д. с. Епархије нишке “Добри Самарјанин" је добротворна организација која делује у оквиру Епархије нишке СПЦ.',
        akcije: [
          {
            'stanje': true,
            'tekst': 'Посети сајт',
            'callback': () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Хвала на посети сајта!\nУчинили сте добро дело.",
                    style: textTheme.bodyMedium,
                  ),
                  backgroundColor: colors.surfaceVariant,
                ),
              );
              launchUrl(
                Uri.parse(
                  'https://eparhijaniska.rs/aktivnosti/vd-starateljstvo',
                ),
              );
            },
          },
        ],
      ),
    ];

List<Delo> delaLatinica(context, textTheme, colors) => [
      Delo(
        textTheme: textTheme,
        colors: colors,
        naslov: cirilicaLatinica('Помозите да други сазнају за апликацију'),
        objasnjenje: cirilicaLatinica(
            'Издвојите минут да поделите апликацију како би и остали почели да је користе.'),
        akcije: [
          {
            'stanje': true,
            'tekst': cirilicaLatinica('Подели'),
            'callback': () async {
              ShareResult rezultat = await Share.shareWithResult(
                cirilicaLatinica("Инсталирајте апликацију Веронаука на длану!"),
              );
              if (rezultat.status == ShareResultStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      cirilicaLatinica(
                          "Хвала на дељењу!\nУчинили сте добро дело."),
                      style: textTheme.bodyMedium,
                    ),
                    backgroundColor: colors.surfaceVariant,
                  ),
                );
              }
            }
          }
        ],
      ),
      Delo(
        textTheme: textTheme,
        colors: colors,
        naslov: cirilicaLatinica('Запратите оца Предрага Поповића'),
        objasnjenje: cirilicaLatinica(
            'Отац Пеђа је православни свештеник који мисионарећи путем интернета говори о релевантним темама у Православљу.'),
        akcije: [
          {
            'stanje': true,
            'tekst': cirilicaLatinica('Запрати'),
            'callback': () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    cirilicaLatinica(
                        "Хвала на праћењу!\nУчинили сте себи и другима добро дело."),
                    style: textTheme.bodyMedium,
                  ),
                  backgroundColor: colors.surfaceVariant,
                ),
              );
              launchUrl(
                Uri.parse(
                  'https://www.youtube.com/@otacpredragpopovic',
                ),
              );
            },
          },
          {
            'stanje': true,
            'tekst': cirilicaLatinica('Сајт'),
            'callback': () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    cirilicaLatinica(
                        "Хвала на посети сајта!\nУчинили сте добро дело."),
                    style: textTheme.bodyMedium,
                  ),
                  backgroundColor: colors.surfaceVariant,
                ),
              );
              launchUrl(
                Uri.parse(
                  'https://otacpredrag.com/',
                ),
              );
            },
          },
        ],
      ),
      Delo(
        textTheme: textTheme,
        colors: colors,
        naslov: cirilicaLatinica('Подржите организацију Срби за Србе'),
        objasnjenje: cirilicaLatinica(
            'Срби за Србе је светска хуманитарна организација која помаже социјално угроженим породицама широм Балкана.'),
        akcije: [
          {
            'stanje': true,
            'tekst': cirilicaLatinica('Посети сајт'),
            'callback': () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    cirilicaLatinica(
                        "Хвала на посети сајта!\nУчинили сте добро дело."),
                    style: textTheme.bodyMedium,
                  ),
                  backgroundColor: colors.surfaceVariant,
                ),
              );
              launchUrl(
                Uri.parse(
                  'https://www.srbizasrbe.org/',
                ),
              );
            },
          },
        ],
      ),
      Delo(
        textTheme: textTheme,
        colors: colors,
        naslov: cirilicaLatinica(
            'Помозите рад верског добротворног старатељства Епархије нишке'),
        objasnjenje: cirilicaLatinica(
            'В. д. с. Епархије нишке “Добри Самарјанин" је добротворна организација која делује у оквиру Епархије нишке СПЦ.'),
        akcije: [
          {
            'stanje': true,
            'tekst': cirilicaLatinica('Посети сајт'),
            'callback': () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    cirilicaLatinica(
                        "Хвала на посети сајта!\nУчинили сте добро дело."),
                    style: textTheme.bodyMedium,
                  ),
                  backgroundColor: colors.surfaceVariant,
                ),
              );
              launchUrl(
                Uri.parse(
                  'https://eparhijaniska.rs/aktivnosti/vd-starateljstvo',
                ),
              );
            },
          },
        ],
      ),
    ];

class Delo extends StatelessWidget {
  const Delo({
    super.key,
    required this.textTheme,
    required this.colors,
    required this.akcije,
    required this.naslov,
    required this.objasnjenje,
  });

  final TextTheme textTheme;
  final ColorScheme colors;
  final List<Map<String, dynamic>> akcije;
  final String naslov;
  final String objasnjenje;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          naslov,
          style: textTheme.titleMedium?.merge(TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.bold,
          )),
        ),
        SizedBox(height: 8),
        Text(
          objasnjenje,
          style: textTheme.bodyMedium?.merge(TextStyle(
            fontStyle: FontStyle.italic,
          )),
        ),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0, len = akcije.length; i < len; i++)
                akcije[i]['stanje']
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton(
                            onPressed: akcije[i]['callback'],
                            child: Text(
                              akcije[i]['tekst'],
                              style: textTheme.bodyMedium?.merge(TextStyle(
                                color: colors.background,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                              )),
                            ),
                          ),
                          if (i < len - 1)
                            SizedBox(
                              width: 8,
                            )
                        ],
                      )
                    : OutlinedButton(
                        onPressed: akcije[i]['callback_kliknuto'],
                        child: Text(
                          akcije[i]['tekst_kliknuto'],
                          style: textTheme.bodyMedium?.merge(TextStyle(
                            color: colors.primary,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                          )),
                        ),
                      )
            ],
          ),
        ),
      ],
    );
  }
}
