import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return navigator?.pushNamed<T>(routeName, arguments: arguments) ?? Future.value(null);
  }

  static Future<T?> pushReplacementNamed<T extends Object?>(String routeName, {Object? arguments, Object? result}) {
    return navigator?.pushReplacementNamed<T, Object?>(routeName, arguments: arguments, result: result) ?? Future.value(null);
  }

  static void pop<T>([T? result]) {
    navigator?.pop<T>(result);
  }

  static void popUntil(String routeName) {
    navigator?.popUntil(ModalRoute.withName(routeName));
  }

  static Future<T?> pushAndClearStack<T>(String routeName, {Object? arguments}) {
    return navigator?.pushNamedAndRemoveUntil<T>(
      routeName,
          (route) => false,
      arguments: arguments,
    ) ?? Future.value(null);
  }

  static BuildContext? get currentContext => navigatorKey.currentContext;
}