import 'package:flutter/material.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'dart:async';
// import 'package:timezone/timezone.dart';

// import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veronauka/color_schemes.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:veronauka/latinica_cirilica.dart';
import 'package:veronauka/oglasi.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:veronauka/stranice.dart';
import 'package:veronauka/informacije.dart';
import 'package:in_app_review/in_app_review.dart';

final InAppReview inAppReview = InAppReview.instance;

// FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  await initializeDateFormatting();
  await Hive.initFlutter();

  Box box = await Hive.openBox("parametri");

  // await Supabase.initialize(
  //   url: 'https://lyxjszgxrueppahrlqzh.supabase.co',
  //   anonKey:
  //       'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5eGpzemd4cnVlcHBhaHJscXpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDkwNDMyOTMsImV4cCI6MjAyNDYxOTI5M30.NwRQ9rdqtttmxgEEuE9Als4BhH_guROGCaVROqq58ds',
  // );

  // var initializationSettingsAndroid =
  //     AndroidInitializationSettings("launch_icon");
  // var initializationSettings =6
  //     InitializationSettings(android: initializationSettingsAndroid);
  // await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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

  if (_novKorisnik) {
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
      disableMovingAnimation: true,
      builder: Builder(
        builder: (context) => App(),
      ),
    ),
  ));
}

// final supabase = Supabase.instance.client;

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _indeks = 0;
  BannerAd? _bannerAd;
  bool _oglasiOmoguceni = true;
  bool _novKorisnik = true;
  bool _latinica = false;

  @override
  void initState() {
    super.initState();

    setup();
  }

  void setup() async {
    await _ucitajStanjeNovogKorisnika();
    await _ucitajStanjeOmogucenostiOglasa();
    await _ucitajStanjeLatinice();

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

    RateMyApp rateMyApp = RateMyApp(
      preferencesPrefix: 'rateMyApp_',
      minDays: 2,
      minLaunches: 2,
      remindDays: 5,
      remindLaunches: 2,
    );

    rateMyApp.init().then((_) async {
      if (rateMyApp.shouldOpenDialog) {
        if (await inAppReview.isAvailable()) {
          inAppReview.requestReview();
        }
      }
    });

    // bool _zakazanaNotifikacija = await _ucitajStanjeZakazaneNotifikacije();
    //
    // if (!_zakazanaNotifikacija) {
    //   await _scheduleDailyNotifications();
    //   await _sacuvajStanjeZakazaneNotifikacije(true);
    // }

    // await _scheduleDailyNotifications();

    // String? _aktuelnaVerzijaAplikacije =
    //     await _ucitajAktuelnuVerzijuAplikacije();
    // String _verzijaAplikacije = await _ucitajVerzijuAplikacije();

    // if (_verzijaAplikacije != _aktuelnaVerzijaAplikacije) {
    //   print("Nova verzija dostupna!");
    // }
  }

  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  // TZDateTime _nextInstanceOfTime(Time time) {
  //   final now = TZDateTime.now(getLocation("Serbia/Belgrade"));
  //   var scheduledDate = TZDateTime(
  //     now.location,
  //     now.year,
  //     now.month,
  //     now.day,
  //     time.hour,
  //     time.minute,
  //   );
  //   if (scheduledDate.isBefore(now)) {
  //     scheduledDate = scheduledDate.add(const Duration(days: 1));
  //   }
  //   return scheduledDate;
  // }

  // Future<void> _scheduleDailyNotifications() async {
  //   var androidPlatformChannelSpecifics = AndroidNotificationDetails(
  //     'VeronaukaNaDlanu',
  //     'Veronauka',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //   );
  //   var iOSPlatformChannelSpecifics = IOSNotificationDetails();
  //   var platformChannelSpecifics = NotificationDetails(
  //     android: androidPlatformChannelSpecifics,
  //     iOS: iOSPlatformChannelSpecifics,
  //   );
  //
  //   await flutterLocalNotificationsPlugin.zonedSchedule(
  //     0,
  //     'Хеј, сврати на апликацију!',
  //     'Помоли се, прочитај поглавље Библије и учини добро себи и другима.',
  //     _nextInstanceOfTime(Time(8, 0, 0)),
  //     platformChannelSpecifics,
  //     androidAllowWhileIdle: true,
  //     uiLocalNotificationDateInterpretation:
  //         UILocalNotificationDateInterpretation.absoluteTime,
  //     matchDateTimeComponents: DateTimeComponents.time,
  //   );
  // }

  Future<void> _ucitajStanjeLatinice() async {
    Box box = await Hive.box("parametri");

    setState(() {
      _latinica = box.get("latinica", defaultValue: false);
    });
  }

  Future<void> _sacuvajStanjeLatinice() async {
    Box box = await Hive.box("parametri");
    box.put("latinica", _latinica);
  }

  Future<void> _ucitajStanjeNovogKorisnika() async {
    Box box = await Hive.box("parametri");
    Map<dynamic, dynamic> prikaziUputstva =
        box.get('prikazi_uputstva', defaultValue: {'nov_korisnik': true});

    setState(() {
      _novKorisnik = prikaziUputstva['nov_korisnik'];
    });
  }

  Future<void> _sacuvajStanjeNovogKorisnika(bool stanje) async {
    Box box = await Hive.box("parametri");
    Map<dynamic, dynamic> prikaziUputstva = box.get('prikazi_uputstva');

    prikaziUputstva['nov_korisnik'] = stanje;
    box.put('prikazi_uputstva', prikaziUputstva);

    setState(() {
      _novKorisnik = stanje;
    });
  }

  Future<void> _ucitajStanjeOmogucenostiOglasa() async {
    // Ucitaj box parametara
    Box box = await Hive.box("parametri");

    setState(() {
      _oglasiOmoguceni = box.get('oglasi_omoguceni', defaultValue: true);
    });
  }

  // Future<String?> _ucitajAktuelnuVerzijuAplikacije() async {
  //   List<Map<String, dynamic>>? odgovor =
  //       await supabase.from("informacije").select();
  //   return odgovor[0]["verzija"];
  // }

  Future<String> _ucitajVerzijuAplikacije() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
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
          _novKorisnik
              ? _latinica
                  ? cirilicaLatinica('Добродошли!')
                  : 'Добродошли!'
              : _latinica
                  ? cirilicaLatinica(stranice[_indeks].naslov)
                  : stranice[_indeks].naslov,
          style: textTheme.headlineMedium?.merge(
            TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              _sacuvajStanjeNovogKorisnika(true);

              Box box = await Hive.box("parametri");
              box.put("prikazi_uputstva", {
                "nov_korisnik": true,
                "pocetna_nov_korisnik": true,
                "molitve_nov_korisnik": true,
                "biblija_nov_korisnik_glavno": true,
                "biblija_nov_korisnik_citanje": true,
                "kalendar_nov_korisnik": true,
                "dobra_dela_nov_korisnik": true,
              });
            },
            icon: FaIcon(
              FontAwesomeIcons.circleQuestion,
              color: colors.primary,
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Informacije(latinica: _latinica,),
                showDragHandle: true,
                isScrollControlled: true,
                useSafeArea: true,
              );
            },
            icon: FaIcon(
              FontAwesomeIcons.ellipsisVertical,
              color: colors.primary,
            ),
          ),
        ],
      ),
      body: _novKorisnik
          ? PopScope(
              canPop: false,
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/splash/splash-foreground-512.png'),
                      // Text(
                      //   'Хвала Вам што сте овде!',
                      //   style: textTheme.titleMedium!.merge(
                      //     TextStyle(
                      //       color: colors.primary,
                      //     ),
                      //   ),
                      //   textAlign: TextAlign.center,
                      // ),
                      // SizedBox(
                      //   height: 20,
                      // ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton(
                            onPressed: () {
                              _sacuvajStanjeNovogKorisnika(false);
                            },
                            child: Text(_latinica
                                ? cirilicaLatinica('Упутство')
                                : 'Упутство'),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              _sacuvajStanjeNovogKorisnika(false);

                              Box box = await Hive.box("parametri");
                              box.put("prikazi_uputstva", {
                                "nov_korisnik": false,
                                "pocetna_nov_korisnik": false,
                                "molitve_nov_korisnik": false,
                                "biblija_nov_korisnik_glavno": false,
                                "biblija_nov_korisnik_citanje": false,
                                "kalendar_nov_korisnik": false,
                                "dobra_dela_nov_korisnik": false,
                              });
                            },
                            child: Text(_latinica
                                ? cirilicaLatinica('Прескочи')
                                : 'Прескочи'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _latinica = !_latinica;
                              });
                              _sacuvajStanjeLatinice();
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.language,
                                  color: colors.primary,
                                ),
                                SizedBox(width: 10,),
                                Text(_latinica ? "Ћирилица" : "Latinica"),
                              ],
                            ),
                          ),
                          SizedBox(width: 8,),
                          OutlinedButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => Informacije(latinica: _latinica),
                                showDragHandle: true,
                                isScrollControlled: true,
                                useSafeArea: true,
                              );
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.ellipsisVertical,
                                  color: colors.primary,
                                ),
                                SizedBox(width: 10,),
                                Text(_latinica ? "Informacije" : "Информације"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          : stranice[_indeks].stranicaBuilder(_idiNaIndeks, _latinica),
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
                if (_bannerAd != null && _oglasiOmoguceni)
                  Container(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
              ],
            ),
    );
  }
}
