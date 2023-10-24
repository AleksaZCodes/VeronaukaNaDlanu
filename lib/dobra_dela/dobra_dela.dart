import 'package:flutter/material.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();

    _setup();
  }

  void dispose() {
    _interstitialAd?.dispose();

    super.dispose();
  }

  void _setup() async {
    await _ucitajStanjeOmogucenostiOglasa();
    setState(() {
      _ucitano = true;
    });
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
    await InterstitialAd.load(
      adUnitId: Oglasi.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _interstitialAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
        },
      ),
    );
  }

  Future<void> _prikaziOglas() async {
    await _ucitajOglas();

    if (_interstitialAd != null) {
      _interstitialAd?.show();
    }
  }

  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    if (_ucitano) {
      return Container(
        child: ListView(
          children: [
            // Omogucite oglase
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Омогућите огласе, бесплатно је",
                        style: textTheme.titleMedium?.merge(TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        )),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Само користећи апликацију уз огласе генеришете новац који се донира хуманитарним фондацијама.",
                        style: textTheme.bodyMedium?.merge(TextStyle(
                          fontStyle: FontStyle.italic,
                        )),
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: !_oglasiOmoguceni
                            ? FilledButton(
                                onPressed: () {
                                  _sacuvajStanjeOmogucenostiOglasa(true);
                                },
                                child: Text(
                                  "Омогући огласе",
                                  style: textTheme.bodyMedium?.merge(TextStyle(
                                    color: colors.background,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold,
                                  )),
                                ),
                              )
                            : OutlinedButton(
                                onPressed: () {
                                  _sacuvajStanjeOmogucenostiOglasa(false);
                                },
                                child: Text(
                                  "Онемогући огласе",
                                  style: textTheme.bodyMedium?.merge(TextStyle(
                                    color: colors.primary,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold,
                                  )),
                                ),
                              ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            // Pogledajte oglas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Погледајте оглас, повећајте допринос",
                        style: textTheme.titleMedium?.merge(TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        )),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Бесплатно погледајте оглас који зарађује малу количину новца. Више њих - већи допринос. (још боље - кликните на њега)",
                        style: textTheme.bodyMedium?.merge(TextStyle(
                          fontStyle: FontStyle.italic,
                        )),
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _oglasiOmoguceni
                            ? FilledButton(
                                onPressed: () async {
                                  await _prikaziOglas();
                                },
                                child: Text(
                                  "Учитај оглас",
                                  style: textTheme.bodyMedium?.merge(TextStyle(
                                    color: colors.background,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold,
                                  )),
                                ),
                              )
                            : OutlinedButton(
                                onPressed: () {},
                                child: Text(
                                  "Прво омогућите огласе",
                                  style: textTheme.bodyMedium?.merge(TextStyle(
                                    color: colors.primary,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold,
                                  )),
                                ),
                              ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            // Podelite aplikaciju
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Помозите да други сазнају за апликацију",
                        style: textTheme.titleMedium?.merge(TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        )),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Издвојите минут да оцените и поделите апликацију како би и остали почели да је користе.",
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
                            FilledButton(
                              onPressed: () async {},
                              child: Text(
                                "Оцени",
                                style: textTheme.bodyMedium?.merge(TextStyle(
                                  color: colors.background,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                )),
                              ),
                            ),
                            SizedBox(width: 8),
                            FilledButton(
                              onPressed: () async {
                                ShareResult rezultat = await Share.shareWithResult("");
                                if (rezultat.status == ShareResultStatus.success) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Хвала на дељењу! Учинили сте добро дело.")));
                                }
                              },
                              child: Text(
                                "Подели",
                                style: textTheme.bodyMedium?.merge(TextStyle(
                                  color: colors.background,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                )),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
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
        ),
      );
    } else {
      return Center(
        child: CircularProgressIndicator(), // Show a loading indicator
      );
    }
  }
}
