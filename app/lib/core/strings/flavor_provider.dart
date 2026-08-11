import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_strings.dart';
import 'superhero_strings.dart';

enum AppFlavor {
  superhero,
}

extension AppFlavorExtension on AppFlavor {
  AppStrings get strings {
    switch (this) {
      case AppFlavor.superhero:
        return const SuperheroStrings();
    }
  }
}

class FlavorNotifier extends Notifier<AppFlavor> {
  @override
  AppFlavor build() {
    return AppFlavor.superhero;
  }

  void setFlavor(AppFlavor flavor) {
    state = flavor;
  }
}

final flavorProvider = NotifierProvider<FlavorNotifier, AppFlavor>(
  FlavorNotifier.new,
);

final appStringsProvider = Provider<AppStrings>((ref) {
  final flavor = ref.watch(flavorProvider);
  return flavor.strings;
});
