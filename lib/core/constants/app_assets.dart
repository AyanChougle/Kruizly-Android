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

  static String getFleetImage(String fullNameOrBrand, [String? model]) {
    final b = model == null ? fullNameOrBrand : fullNameOrBrand;
    final m = model ?? '';
    final candidates = getCarImageCandidates(b, m);
    return candidates.firstWhere(
      (c) => c != carPlaceholder,
      orElse: () => 'assets/fleet/Toyota Glanza.png',
    );
  }

  /// Maps known vehicle aliases, models, or backend paths to available local assets
  static final Map<String, String> _knownAliases = {
    // Thar Roxx (matches exact asset: assets/fleet/Mahindra Thar Roxx.png)
    'thar roxx': 'assets/fleet/Mahindra Thar Roxx.png',
    'thar roxx sunroof': 'assets/fleet/Mahindra Thar Roxx.png',
    'mahindra thar roxx': 'assets/fleet/Mahindra Thar Roxx.png',
    'thar': 'assets/fleet/Mahindra Thar.png',
    'mahindra thar': 'assets/fleet/Mahindra Thar.png',

    // BMW (matches exact asset: assets/fleet/BMW 520D.png)
    'bmw': 'assets/fleet/BMW 520D.png',
    'bmw 520d': 'assets/fleet/BMW 520D.png',
    'bmw m5': 'assets/fleet/BMW 520D.png',
    'bmw m5 modified': 'assets/fleet/BMW 520D.png',
    'bmw m5 modified sunroof': 'assets/fleet/BMW 520D.png',
    '520d': 'assets/fleet/BMW 520D.png',
    'm5': 'assets/fleet/BMW 520D.png',

    // Toyota Taisor / Rumion / Crysta
    'taisor': 'assets/fleet/Toyota Urban Cruiser Taisor.png',
    'toyota taisor': 'assets/fleet/Toyota Urban Cruiser Taisor.png',
    'urban cruiser taisor': 'assets/fleet/Toyota Urban Cruiser Taisor.png',
    'toyota urban cruiser taisor': 'assets/fleet/Toyota Urban Cruiser Taisor.png',
    'rumion': 'assets/fleet/Toyota Rumion.png',
    'toyota rumion': 'assets/fleet/Toyota Rumion.png',
    'innova': 'assets/fleet/Toyota Innova Crysta.png',
    'innova crysta': 'assets/fleet/Toyota Innova Crysta.png',
    'toyota innova crysta': 'assets/fleet/Toyota Innova Crysta.png',
    'glanza': 'assets/fleet/Toyota Glanza.png',
    'toyota glanza': 'assets/fleet/Toyota Glanza.png',

    // MG Hector
    'mg hector': 'assets/fleet/MG Hector.jpg',
    'hector': 'assets/fleet/MG Hector.jpg',

    // Kia
    'seltos': 'assets/fleet/Kia Carens.png',
    'kia seltos': 'assets/fleet/Kia Carens.png',
    'seltos sunroof': 'assets/fleet/Kia Carens.png',
    'carens': 'assets/fleet/Kia Carens.png',
    'kia carens': 'assets/fleet/Kia Carens.png',

    // Tata
    'tigor': 'assets/fleet/Tata Altroz.png',
    'tata tigor': 'assets/fleet/Tata Altroz.png',
    'altroz': 'assets/fleet/Tata Altroz.png',
    'tata altroz': 'assets/fleet/Tata Altroz.png',
    'punch': 'assets/fleet/Tata Punch.png',
    'tata punch': 'assets/fleet/Tata Punch.png',
    'nexon': 'assets/fleet/Tata Nexon.png',
    'tata nexon': 'assets/fleet/Tata Nexon.png',
    'safari': 'assets/fleet/Tata Safari.png',
    'tata safari': 'assets/fleet/Tata Safari.png',

    // Jeep
    'compass': 'assets/fleet/Jeep Compass.png',
    'compass 4x4': 'assets/fleet/Jeep Compass.png',
    'compass 4x4 sunroof': 'assets/fleet/Jeep Compass.png',
    'jeep compass': 'assets/fleet/Jeep Compass.png',

    // Maruti Suzuki
    'swift': 'assets/fleet/Maruti Suzuki Swift.png',
    'swift vxi': 'assets/fleet/Maruti Suzuki Swift.png',
    'swift vxi (o)': 'assets/fleet/Maruti Suzuki Swift.png',
    'maruti suzuki swift': 'assets/fleet/Maruti Suzuki Swift.png',
    'dzire': 'assets/fleet/Maruti Suzuki Dzire.png',
    'dzire zxi+': 'assets/fleet/Maruti Suzuki Dzire.png',
    'dzire zxi+ sunroof': 'assets/fleet/Maruti Suzuki Dzire.png',
    'maruti suzuki dzire': 'assets/fleet/Maruti Suzuki Dzire.png',
    'ertiga': 'assets/fleet/Maruti Suzuki Ertiga.png',
    'ertiga (2023 unit)': 'assets/fleet/Maruti Suzuki Ertiga.png',
    'ertiga (2025 unit)': 'assets/fleet/Maruti Suzuki Ertiga.png',
    'ertiga hybrid': 'assets/fleet/Maruti Suzuki Ertiga.png',
    'maruti suzuki ertiga': 'assets/fleet/Maruti Suzuki Ertiga.png',
    'fronx': 'assets/fleet/Maruti Suzuki Fronx.png',
    'maruti suzuki fronx': 'assets/fleet/Maruti Suzuki Fronx.png',
    'brezza': 'assets/fleet/Maruti Suzuki Brezza.png',
    'maruti suzuki brezza': 'assets/fleet/Maruti Suzuki Brezza.png',
    'baleno': 'assets/fleet/Maruti Suzuki Baleno.png',
    'maruti suzuki baleno': 'assets/fleet/Maruti Suzuki Baleno.png',
    'grand vitara': 'assets/fleet/Maruti Suzuki Grand Vitara.png',
    'maruti suzuki grand vitara': 'assets/fleet/Maruti Suzuki Grand Vitara.png',
    'ignis': 'assets/fleet/Maruti Suzuki Ignis.png',
    'maruti suzuki ignis': 'assets/fleet/Maruti Suzuki Ignis.png',
    'wagonr': 'assets/fleet/Maruti Suzuki WagonR.png',
    'maruti suzuki wagonr': 'assets/fleet/Maruti Suzuki WagonR.png',
    'xl6': 'assets/fleet/Maruti Suzuki XL6.png',
    'maruti suzuki xl6': 'assets/fleet/Maruti Suzuki XL6.png',

    // Hyundai
    'aura': 'assets/fleet/Hyundai Aura.png',
    'hyundai aura': 'assets/fleet/Hyundai Aura.png',
    'creta': 'assets/fleet/Hyundai Creta.png',
    'hyundai creta': 'assets/fleet/Hyundai Creta.png',
    'exter': 'assets/fleet/Hyundai Exter.png',
    'hyundai exter': 'assets/fleet/Hyundai Exter.png',
    'i20': 'assets/fleet/Hyundai i20.png',
    'hyundai i20': 'assets/fleet/Hyundai i20.png',

    // Mahindra
    'xuv700': 'assets/fleet/Mahindra XUV700.png',
    'mahindra xuv700': 'assets/fleet/Mahindra XUV700.png',
    'xuv500': 'assets/fleet/Mahindra XUV500.png',
    'mahindra xuv500': 'assets/fleet/Mahindra XUV500.png',
    'scorpio n': 'assets/fleet/Mahindra Scorpio N.png',
    'mahindra scorpio n': 'assets/fleet/Mahindra Scorpio N.png',
    '7xo': 'assets/fleet/Mahindra 7XO.png',
    'mahindra 7xo': 'assets/fleet/Mahindra 7XO.png',
  };

  static List<String> getCarImageCandidates(String brand, String model, [String? serverPath]) {
    final b = brand.trim();
    final m = model.trim();
    final combinedKey = '$b $m'.toLowerCase();
    final modelKey = m.toLowerCase();

    final candidates = <String>[];

    // 0. Keyword-based authoritative matching for Thar Roxx & BMW
    if (combinedKey.contains('thar roxx') || modelKey.contains('thar roxx')) {
      candidates.add('assets/fleet/Mahindra Thar Roxx.png');
      candidates.add('assets/fleet/thar roxx.png');
    } else if (combinedKey.contains('thar') || modelKey.contains('thar')) {
      candidates.add('assets/fleet/Mahindra Thar.png');
    }

    if (combinedKey.contains('bmw') || modelKey.contains('bmw') || modelKey.contains('520d') || modelKey.contains('m5')) {
      candidates.add('assets/fleet/BMW 520D.png');
    }

    // 1. Direct server path if provided and points to local assets
    if (serverPath != null && serverPath.isNotEmpty) {
      final clean = serverPath.trim();
      if (clean.startsWith('assets/')) {
        candidates.add(clean);
        // Also check with .png / .jpg swapped
        if (clean.endsWith('.png')) candidates.add(clean.replaceAll('.png', '.jpg'));
        if (clean.endsWith('.jpg')) candidates.add(clean.replaceAll('.jpg', '.png'));
      }
    }

    // 2. Check alias map
    if (_knownAliases.containsKey(combinedKey)) {
      candidates.add(_knownAliases[combinedKey]!);
    }
    if (_knownAliases.containsKey(modelKey)) {
      candidates.add(_knownAliases[modelKey]!);
    }

    // 3. Normalized combinations
    candidates.addAll([
      'assets/fleet/$b $m.png',
      'assets/fleet/$b $m.jpg',
      'assets/fleet/$m.png',
      'assets/fleet/$m.jpg',
      'assets/fleet/$b.png',
      'assets/fleet/${b.replaceAll(' ', '')} $m.png',
    ]);

    // 4. Fallback placeholder
    candidates.add(carPlaceholder);
    return candidates.toSet().toList(); // deduplicate while preserving priority
  }
}

