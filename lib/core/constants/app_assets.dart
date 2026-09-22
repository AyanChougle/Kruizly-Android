class AppAssets {
  static const String logoDark = '''assets/images/logo-dark.png''';
  static const String logoLight = '''assets/images/logo-light.png''';
  static const String logoOriginal = '''assets/images/logo-original.png''';
  static const String logo = '''assets/images/logo.png''';

  // Fallback vehicle photos
  static const String carPlaceholder = 'assets/images/logo-original.png';

  static String getCarImagePath(String brand, String model) {
    final b = brand.trim();
    final m = model.trim();
    return 'assets/fleet/$b $m.png';
  }

  static List<String> getCarImageCandidates(String brand, String model) {
    final b = brand.trim();
    final m = model.trim();
    return [
      'assets/fleet/$b $m.png',
      'assets/fleet/$b $m.jpg',
      'assets/fleet/$m.png',
      'assets/fleet/$m.jpg',
      'assets/fleet/$b.png',
      'assets/fleet/${b.replaceAll(' ', '')} $m.png',
      carPlaceholder,
    ];
  }
}
