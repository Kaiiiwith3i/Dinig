import 'package:flutter/material.dart';

enum IdType {
  nationalId('Philippine National ID', 'PSA National ID', Icons.badge_outlined),
  driversLicense("Driver's License", "LTO Driver's License", Icons.credit_card_outlined),
  passport('Passport', 'Department of Foreign Affairs', Icons.menu_book_outlined),
  umid('UMID Card', 'SSS, GSIS, or Pag-IBIG', Icons.account_box_outlined);

  final String title;
  final String subtitle;
  final IconData icon;

  const IdType(this.title, this.subtitle, this.icon);
}
