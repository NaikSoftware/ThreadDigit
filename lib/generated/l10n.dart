// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `ThreadDigit`
  String get appName {
    return Intl.message(
      'ThreadDigit',
      name: 'appName',
      desc: '',
      args: [],
    );
  }

  /// `Select a machine`
  String get colorManagerSelectMachine {
    return Intl.message(
      'Select a machine',
      name: 'colorManagerSelectMachine',
      desc: '',
      args: [],
    );
  }

  /// `Optimize colors`
  String get optimizeColors {
    return Intl.message(
      'Optimize colors',
      name: 'optimizeColors',
      desc: '',
      args: [],
    );
  }

  /// `Sequence`
  String get sequence {
    return Intl.message(
      'Sequence',
      name: 'sequence',
      desc: '',
      args: [],
    );
  }

  /// `Steps`
  String get steps {
    return Intl.message(
      'Steps',
      name: 'steps',
      desc: '',
      args: [],
    );
  }

  /// `No embroidery steps provided`
  String get stepsIsEmpty {
    return Intl.message(
      'No embroidery steps provided',
      name: 'stepsIsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Change machine`
  String get changeMachine {
    return Intl.message(
      'Change machine',
      name: 'changeMachine',
      desc: '',
      args: [],
    );
  }

  /// `Needles`
  String get needles {
    return Intl.message(
      'Needles',
      name: 'needles',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
