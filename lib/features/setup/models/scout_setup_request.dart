class ScoutSetupRequest {
  final String country;
  final String location;
  final List<String> categories;
  final List<String> digitalGaps;

  const ScoutSetupRequest({
    required this.country,
    required this.location,
    required this.categories,
    required this.digitalGaps,
  });

  String get locationLabel => '$location, $country';
}
