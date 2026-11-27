# Bundled typography

Nunito400/600/700/800 and Cinzel700 are static instances of Google Fonts upstream
variable fonts downloaded2026-11-21. SIL Open Font License1.1 texts are included.
No runtime font downloads.

Sources: https://github.com/google/fonts/tree/main/ofl/nunito and
https://github.com/google/fonts/tree/main/ofl/cinzel.
Static instances use fontTools.varLib.instancer at each wght coordinate.
The committed TTFs and pubspec registrations are the runtime source of truth.
Screenshot tests load these same files; platform fallback handles additional
scripts/emoji and MaterialIcons remains a separate SDK font.
