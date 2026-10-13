import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the phone dialer. Works with no data connection; tells the user when
/// this device cannot place calls (e.g. a simulator).
Future<void> dialNumber(BuildContext context, String number) async {
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = await launchUrl(
      Uri(scheme: 'tel', path: number.replaceAll(RegExp(r'[^0-9+]'), '')),
    );
  } catch (_) {}
  if (!ok) {
    messenger.showSnackBar(
      SnackBar(content: Text('Cannot place a call from this device. Dial $number.')),
    );
  }
}
