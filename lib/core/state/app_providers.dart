import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mock/mock_data.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/models/product_model.dart';

const _localeKey = 'smartfresh.locale';
const _themeKey = 'smartfresh.theme';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences provider must be overridden');
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this.ref) : super(_loadInitialLocale(ref.read(sharedPreferencesProvider)));

  final Ref ref;

  static Locale _loadInitialLocale(SharedPreferences prefs) {
    final code = prefs.getString(_localeKey);
    return Locale(code ?? 'ar');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref.read(sharedPreferencesProvider).setString(_localeKey, locale.languageCode);
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this.ref) : super(_loadInitialTheme(ref.read(sharedPreferencesProvider)));

  final Ref ref;

  static ThemeMode _loadInitialTheme(SharedPreferences prefs) {
    final value = prefs.getString(_themeKey);
    if (value == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_themeKey, mode.name);
  }

  Future<void> setSystemMode() async {
    state = ThemeMode.system;
    await ref.read(sharedPreferencesProvider).remove(_themeKey);
  }
}

class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  void setIndex(int index) => state = index;
}

class ProductsNotifier extends StateNotifier<List<ProductModel>> {
  ProductsNotifier() : super(MockData.products);

  void addProduct(ProductModel product) {
    state = [product, ...state];
  }

  void removeProduct(String id) {
    state = state.where((product) => product.id != id).toList();
  }

  void updateProducts(List<ProductModel> products) {
    state = products;
  }
}

class NotificationsNotifier extends StateNotifier<List<AppNotificationModel>> {
  NotificationsNotifier() : super(MockData.notifications);

  void markAllRead() {
    state = [for (final notification in state) notification.copyWith(isRead: true)];
  }

  void removeById(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier(ref));
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier(ref));
final navigationIndexProvider = StateNotifierProvider<NavigationNotifier, int>((ref) => NavigationNotifier());
final productsProvider = StateNotifierProvider<ProductsNotifier, List<ProductModel>>((ref) => ProductsNotifier());
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<AppNotificationModel>>((ref) => NotificationsNotifier());

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((item) => !item.isRead).length;
});

final mockProductStatsProvider = Provider((ref) => MockData.monthlyStats);
