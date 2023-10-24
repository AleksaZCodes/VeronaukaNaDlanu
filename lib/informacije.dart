import 'package:flutter/material.dart';

class Informacije extends StatelessWidget {
  const Informacije({super.key});

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
                "Информације",
                style: textTheme.titleLarge?.merge(TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                )),
              ),
              SizedBox(height: 20),
              Text(// уз благослов епископа нишког г. Арсенија,
                'Апликација "Веронаука на длану" направљена је под менторством вероучитељице Јулијане Стојановић. Аутор је Алекса Здравковић, самоуки програмер и ученик првог разреда ЕТШ "Никола Тесла" у Нишу.\n\nМисија апликације је подизање свести о важности вере и Бога у православном друштву. Она спаја више аспеката духовног живота у свестрани алат који стаје на длан и служи свим верницима на духовном путу.',
                style: textTheme.bodyLarge,
              ),
              SizedBox(height: 20),
              RichText(text: TextSpan(
                children: [
                  TextSpan(
                    text: "Сајт и политика приватности:\n",
                    style: textTheme.labelLarge?.merge(TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold
                    )),
                  ),
                  TextSpan(
                    text: "aleksazcodes.github.io/veronaukanadlanu\n\n",
                    style: textTheme.labelLarge?.merge(TextStyle(
                      color: colors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.primary,
                    )),
                  ),
                  TextSpan(
                    text: "Контакт програмера:\n",
                    style: textTheme.labelLarge?.merge(TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold
                    )),
                  ),
                  TextSpan(
                    text: "aleksazdravkovic+vnd@proton.me",
                    style: textTheme.labelLarge?.merge(TextStyle(
                      color: colors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.primary,
                    )),
                  ),
                ]
              )),
            ],
          ),
        ),
      ],
    );
  }
}
