import 'package:flutter/material.dart';

class LocaleController extends ValueNotifier<Locale?> {
  LocaleController() : super(null);

  void setLocale(Locale locale) {
    value = locale;
  }

  void clear() {
    value = null;
  }
}

final localeController = LocaleController();
