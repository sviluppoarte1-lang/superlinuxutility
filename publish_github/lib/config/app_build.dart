/// Build type: standard (free), advanced (paid), or personal (dev/test, no license).
/// Set at build time via: --dart-define=APP_BUILD=standard|advanced|personal
String get _appBuild =>
    const String.fromEnvironment('APP_BUILD', defaultValue: 'standard');

bool get isStandardBuild => _appBuild == 'standard';

bool get isAdvancedBuild => _appBuild == 'advanced' || _appBuild == 'personal';

/// Personal build: same features as advanced but no license check (for dev/test).
bool get isPersonalBuild => _appBuild == 'personal';
