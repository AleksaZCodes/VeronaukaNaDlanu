import 'package:flutter/material.dart';
import 'package:veronauka/color_schemes.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:veronauka/oglasi.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:veronauka/stranice.dart';
import 'package:veronauka/informacije.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  await initializeDateFormatting();
  await Hive.initFlutter();

  Box box = await Hive.openBox("parametri");

  Future<String> _ucitajVerzijuAplikacije() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<String?> _ucitajSacuvanuVerzijuAplikacije() async {
    return box.get('verzija_aplikacije', defaultValue: null);
  }

  Future<void> _sacuvajVerzijuAplikacije(String verzija) async {
    box.put('verzija_aplikacije', verzija);
  }

  String _verzijaAplikacije = await _ucitajVerzijuAplikacije();
  String? _sacuvanaVerzijaAplikacije = await _ucitajSacuvanuVerzijuAplikacije();
  bool _novKorisnik = _sacuvanaVerzijaAplikacije == null;
  // bool _novaVerzija = _verzijaAplikacije != _sacuvanaVerzijaAplikacije;

  print(
      "${_verzijaAplikacije} : ${_sacuvanaVerzijaAplikacije} : ${_novKorisnik}");

  if (_novKorisnik || true) {
    box.put("prikazi_uputstva", {
      "nov_korisnik": true,
      "pocetna_nov_korisnik": true,
      "molitve_nov_korisnik": true,
      "biblija_nov_korisnik_glavno": true,
      "biblija_nov_korisnik_citanje": true,
      "kalendar_nov_korisnik": true,
      "dobra_dela_nov_korisnik": true,
    });
  }

  await _sacuvajVerzijuAplikacije(_verzijaAplikacije);

  runApp(MaterialApp(
    theme: ThemeData(
      colorScheme: lightColorScheme,
      fontFamily: 'Areal',
      useMaterial3: true,
    ),
    debugShowCheckedModeBanner: false,
    home: ShowCaseWidget(
      builder: Builder(
        builder: (context) => App(),
      ),
    ),
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
  bool _novKorisnik = true;

  @override
  void initState() {
    super.initState();

    setup();
  }

  void setup() async {
    await _ucitajStanjeNovogKorisnika();
    await _ucitajStanjeOmogucenostiOglasa();

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

  Future<void> _ucitajStanjeNovogKorisnika() async {
    Box box = await Hive.box("parametri");
    Map<dynamic, dynamic> prikaziUputstva =
        box.get('prikazi_uputstva', defaultValue: {'nov_korisnik': true});

    setState(() {
      _novKorisnik = prikaziUputstva['nov_korisnik'];
    });
  }

  Future<void> _sacuvajStanjeNovogKorisnika() async {
    Box box = await Hive.box("parametri");
    Map<dynamic, dynamic> prikaziUputstva = box.get('prikazi_uputstva');

    prikaziUputstva['nov_korisnik'] = false;
    box.put('prikazi_uputstva', prikaziUputstva);
  }

  Future<void> _ucitajStanjeOmogucenostiOglasa() async {
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
          _novKorisnik ? 'Добродошли!' : stranice[_indeks].naslov,
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
      body: _novKorisnik
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/splash/splash-foreground-512.png'),
                Text(
                  'Хвала Вам што сте овде!',
                  style: textTheme.titleMedium!.merge(
                    TextStyle(
                      color: colors.primary,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 20,
                ),
                FilledButton(
                  onPressed: () {
                    _sacuvajStanjeNovogKorisnika();
                    setState(() {
                      _novKorisnik = false;
                    });
                  },
                  child: Text('ЗАПОЧНИ'),
                )
              ],
            )
          : stranice[_indeks].stranicaBuilder(_idiNaIndeks),
      bottomNavigationBar: _novKorisnik
          ? null
          : Column(
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
