/// Build type: standard (free) or advanced (paid).
/// Set at build time via: --dart-define=APP_BUILD=standard|advanced
bool get isStandardBuild =>
    const String.fromEnvironment('APP_BUILD', defaultValue: 'standard') == 'standard';

bool get isAdvancedBuild => !isStandardBuild;
