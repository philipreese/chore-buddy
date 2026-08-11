import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_strings.dart';
import 'standard_strings.dart';
import 'superhero_strings.dart';
import 'wheel_of_time_strings.dart';

enum AppVoice {
  superhero,
  standard,
  wheelOfTime,
}

/// Voice-agnostic metadata for a voice's Settings picker row -- resolvable
/// for any [AppVoice] regardless of which one is currently active, unlike
/// [appStringsProvider] which only ever reflects the active one.
class VoiceMetadata {
  final String displayName;
  final String glyph;

  const VoiceMetadata({required this.displayName, required this.glyph});
}

/// Single source of truth for what a voice is: one enum value, one
/// [AppStrings] implementation registered here, one [VoiceMetadata] entry
/// registered here. Both maps are const, so adding a voice (spec 25) is a
/// new file plus three one-line additions -- this map, [_voiceMetadata],
/// and the enum above -- with the compiler enforcing every enum value
/// resolves in both maps.
const Map<AppVoice, AppStrings> _voiceStrings = {
  AppVoice.superhero: SuperheroStrings(),
  AppVoice.standard: StandardStrings(),
  AppVoice.wheelOfTime: WheelOfTimeStrings(),
};

const Map<AppVoice, VoiceMetadata> _voiceMetadata = {
  AppVoice.superhero: VoiceMetadata(displayName: 'Superhero', glyph: '🦸'),
  AppVoice.standard: VoiceMetadata(displayName: 'Standard', glyph: '📋'),
  AppVoice.wheelOfTime:
      VoiceMetadata(displayName: 'Wheel of Time', glyph: '☸️'),
};

extension AppVoiceExtension on AppVoice {
  /// This voice's full string set, independent of whichever voice is
  /// currently active app-wide -- e.g. so the Settings picker can show
  /// every row's own signature line at once.
  AppStrings get strings => _voiceStrings[this]!;

  VoiceMetadata get metadata => _voiceMetadata[this]!;
}

class VoiceNotifier extends Notifier<AppVoice> {
  @override
  AppVoice build() {
    return AppVoice.superhero;
  }

  void setVoice(AppVoice voice) {
    state = voice;
  }
}

final voiceProvider = NotifierProvider<VoiceNotifier, AppVoice>(
  VoiceNotifier.new,
);

final appStringsProvider = Provider<AppStrings>((ref) {
  final voice = ref.watch(voiceProvider);
  return voice.strings;
});
