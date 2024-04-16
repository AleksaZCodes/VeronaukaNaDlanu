import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:veronauka/oglasi.dart';

import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';

class Clanci extends StatefulWidget {
  const Clanci({super.key});

  @override
  State<Clanci> createState() => _ClanciState();
}

class _ClanciState extends State<Clanci> {
  bool _ucitano = false;

  GlobalKey _delo1 = GlobalKey();
  GlobalKey _delo2 = GlobalKey();
  GlobalKey _delo3 = GlobalKey();

  Map<dynamic, dynamic> _prikaziUputstva = {};

  @override
  void initState() {
    super.initState();

    _setup();
  }

  void _setup() async {
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

  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

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
                          'Истакнуто добро дело:',
                          style: textTheme.bodyMedium?.merge(TextStyle(
                            fontStyle: FontStyle.italic,
                          )),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    //   x
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
                // child: x
              ),
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: CircularProgressIndicator(), // Show a loading indicator
      );
    }
  }
}

class Clanak extends StatelessWidget {
  const Clanak({
    super.key,
    required this.textTheme,
    required this.colors,
    required this.naslov,
    required this.tekst,
  });

  final TextTheme textTheme;
  final ColorScheme colors;
  final String naslov;
  final String tekst;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
            child: AspectRatio(
              child: Image.file(File("podaci/krsna_slava.png")),
              aspectRatio: 4 / 3,
            ),
            flex: 2,),
        SizedBox(
          width: 8,
        ),
        Flexible(
          flex: 3,
          child: Text(
            naslov,
            style: textTheme.titleMedium?.merge(TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            )),
          ),
        ),
      ],
    );
  }
}
