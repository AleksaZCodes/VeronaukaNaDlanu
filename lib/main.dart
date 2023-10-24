import 'package:flutter/material.dart';
import 'package:veronauka/color_schemes.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:veronauka/oglasi.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:veronauka/stranice.dart';
import 'package:veronauka/informacije.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  await initializeDateFormatting();
  await Hive.initFlutter();

  Box box = await Hive.openBox("parametri");

  runApp(MaterialApp(
    theme: ThemeData(
      colorScheme: lightColorScheme,
      fontFamily: 'Areal',
      useMaterial3: true,
    ),
    debugShowCheckedModeBanner: false,
    home: App(),
  ));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _indeks = 0;
  BannerAd? _banner;
  bool _oglasiOmoguceni = true;

  @override
  void initState() {
    super.initState();

    _ucitajStanjeOmogucenostiOglasa();

    BannerAd(
      adUnitId: Oglasi.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _banner = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  void _ucitajStanjeOmogucenostiOglasa() async {
    // Ucitaj box parametara
    Box box = await Hive.box("parametri");

    setState(() {
      _oglasiOmoguceni = box.get('oglasi_omoguceni', defaultValue: true);
    });
  }

  void _idiNaIndeks(indeks) {
    setState(() {
      _indeks = indeks;
    });
  }

  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(
          stranice[_indeks].naslov,
          style: textTheme.headlineMedium?.merge(
            TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Informacije(),
                  showDragHandle: true,
                  isScrollControlled: true,
                  useSafeArea: true,
                );
              },
              icon: FaIcon(
                FontAwesomeIcons.ellipsisVertical,
                color: colors.primary,
              ))
        ],
      ),
      body: stranice[_indeks].stranicaBuilder(_idiNaIndeks),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomNavigationBar(
            unselectedItemColor: colors.outlineVariant,
            backgroundColor: colors.background,
            selectedItemColor: colors.primary,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
            currentIndex: _indeks,
            type: BottomNavigationBarType.fixed,
            onTap: _idiNaIndeks,
            items: [
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.house),
                label: 'Почетна',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.personPraying),
                label: 'Молитве',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.bookBible),
                label: 'Библија',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.calendar),
                label: 'Календар',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.handHoldingHeart),
                label: 'Добра дела',
              ),
            ],
          ),
          if (_banner != null && _oglasiOmoguceni)
            Container(
              width: _banner!.size.width.toDouble(),
              height: _banner!.size.height.toDouble(),
              child: AdWidget(ad: _banner!),
            ),
        ],
      ),
    );
  }
}
