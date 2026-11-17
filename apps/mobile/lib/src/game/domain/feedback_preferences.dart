/// Device-local presentation preferences; never influence rules or commands.
class FeedbackPreferences {
  const FeedbackPreferences({
    this.sound = false,
    this.haptics = true,
    this.reduceMotion = false,
  });
  final bool sound;
  final bool haptics;
  final bool reduceMotion;

  FeedbackPreferences copyWith({
    bool? sound,
    bool? haptics,
    bool? reduceMotion,
  }) =>
      FeedbackPreferences(
        sound: sound ?? this.sound,
        haptics: haptics ?? this.haptics,
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'sound': sound,
        'haptics': haptics,
        'reduceMotion': reduceMotion,
      };

  factory FeedbackPreferences.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1 ||
        json['sound'] is! bool ||
        json['haptics'] is! bool ||
        json['reduceMotion'] is! bool) {
      throw const FormatException('Invalid game feedback preferences.');
    }
    return FeedbackPreferences(
      sound: json['sound'] as bool,
      haptics: json['haptics'] as bool,
      reduceMotion: json['reduceMotion'] as bool,
    );
  }
}
