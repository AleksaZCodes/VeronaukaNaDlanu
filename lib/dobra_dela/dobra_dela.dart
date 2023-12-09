import 'package:flutter/material.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:veronauka/oglasi.dart';

import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';

class DobraDela extends StatefulWidget {
  const DobraDela({super.key});

  @override
  State<DobraDela> createState() => _DobraDelaState();
}

class _DobraDelaState extends State<DobraDela> {
  bool _ucitano = false;
  bool _oglasiOmoguceni = true;
  RewardedAd? _rewardedAd;

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

    _ucitajStanjePrikazivanjaUputstva();

    setState(() {
      _ucitano = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) =>
        ShowCaseWidget.of(context).startShowCase([_delo1, _delo2, _delo3]));

    _prikaziUputstva["dobra_dela_nov_korisnik"] = false;

    _sacuvajStanjePrikazivanjaUputstva();
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
    RewardedAd.load(
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
      _rewardedAd?.show(onUserEarnedReward: (reward, item) {});
    }
  }

  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    if (_ucitano) {
      return ListView(
        children: [
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

          // Pogledajte oglas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Delo(
              colors: colors,
              textTheme: textTheme,
              naslov: 'Погледајте оглас, повећајте допринос',
              objasnjenje:
                  'Бесплатно погледајте оглас који зарађује малу количину новца. Више њих - већи допринос. (још боље - кликните на њега)',
              akcije: [
                {
                  'stanje': _oglasiOmoguceni && _rewardedAd != null,
                  'tekst': 'Прикажи оглас',
                  'callback': () async {
                    await _prikaziOglas();
                  },
                  'tekst_kliknuto': 'Учитава се...',
                  'callback_kliknuto': () {}
                }
              ],
            ),
          ),

          // Podelite aplikaciju
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Delo(
              textTheme: textTheme,
              colors: colors,
              naslov: 'Помозите да други сазнају за апликацију',
              objasnjenje:
                  'Издвојите минут да оцените и поделите апликацију како би и остали почели да је користе.',
              akcije: [
                {'stanje': true, 'tekst': 'Оцени', 'callback': () {}},
                {
                  'stanje': true,
                  'tekst': 'Подели',
                  'callback': () async {
                    ShareResult rezultat = await Share.shareWithResult(
                        "Инсталирајте апликацију Веронаука на длану!");
                    if (rezultat.status == ShareResultStatus.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Хвала на дељењу! Учинили сте добро дело.",
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
          ),

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
          //           'Једнократно донирајте неку суму новца коју ћемо проследити фондацији "Буди хуман".',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
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
        ),
      ),
    );
  }
}
