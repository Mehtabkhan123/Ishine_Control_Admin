import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit to manage the application's ThemeMode (dark / light / system).
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({ThemeMode initialMode = ThemeMode.dark}) : super(initialMode);

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      emit(ThemeMode.light);
    } else {
      emit(ThemeMode.dark);
    }
  }

  void setTheme(ThemeMode mode) {
    if (state != mode) {
      emit(mode);
    }
  }

  bool get isDark => state == ThemeMode.dark;
}
