import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veronauka/latinica_cirilica.dart';

class Informacije extends StatelessWidget {
  final bool latinica;

  const Informacije({super.key, required this.latinica});

  @override
  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                latinica ? cirilicaLatinica("Информације") : "Информације",
                style: textTheme.titleLarge?.merge(TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                )),
              ),
              SizedBox(height: 20),
              Text(
                latinica ? cirilicaLatinica('Апликација "Веронаука на длану" направљена је уз благослов епископа нишког г. Арсенија, под менторством вероучитељице Јулијане Стојановић. Аутор је Алекса Здравковић, самоуки програмер и ученик првог разреда ЕТШ "Никола Тесла" у Нишу.\n\nМисија апликације је подизање свести о важности вере и Бога у православном друштву. Она спаја више аспеката духовног живота у свестрани алат који стаје на длан и служи свим верницима на духовном путу.') : 'Апликација "Веронаука на длану" направљена је уз благослов епископа нишког г. Арсенија, под менторством вероучитељице Јулијане Стојановић. Аутор је Алекса Здравковић, самоуки програмер и ученик првог разреда ЕТШ "Никола Тесла" у Нишу.\n\nМисија апликације је подизање свести о важности вере и Бога у православном друштву. Она спаја више аспеката духовног живота у свестрани алат који стаје на длан и служи свим верницима на духовном путу.',
                style: textTheme.bodyLarge,
              ),
              SizedBox(height: 20),
              Text(
                latinica ? cirilicaLatinica("Сајт и политика приватности:") : "Сајт и политика приватности:",
                style: textTheme.labelLarge?.merge(TextStyle(
                    color: colors.primary, fontWeight: FontWeight.bold)),
              ),
              GestureDetector(
                child: Text(
                  "sites.google.com/view/veronauka-na-dlanu",
                  style: textTheme.labelLarge?.merge(TextStyle(
                    color: colors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.primary,
                  )),
                ),
                onTap: () {
                  launchUrl(
                    Uri.parse(
                      'https://sites.google.com/view/veronauka-na-dlanu',
                    ),
                  );
                },
              ),
              SizedBox(height: 8),
              Text(
                latinica ? cirilicaLatinica("Контакт програмера:") : "Контакт програмера:",
                style: textTheme.labelLarge?.merge(TextStyle(
                    color: colors.primary, fontWeight: FontWeight.bold)),
              ),
              GestureDetector(
                child: Text(
                  "aleksazdravkovic+vnd@proton.me",
                  style: textTheme.labelLarge?.merge(TextStyle(
                    color: colors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.primary,
                  )),
                ),
                onTap: () {
                  launchUrl(
                    Uri(
                      scheme: 'mailto',
                      path: 'aleksazdravkovic+vnd@proton.me',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
