/// GNSS satellite data model - from GPSTest/Google GPS tools inspired features
class GnssSatellite {
  final int prn;                // Satellite PRN number
  final String constellation;   // GPS, GLONASS, Galileo, BeiDou, QZSS, NavIC
  final double snr;             // Signal-to-Noise Ratio (C/N0) in dB-Hz
  final double elevation;       // Elevation angle in degrees
  final double azimuth;         // Azimuth angle in degrees
  final bool usedInFix;         // Whether satellite was used in last position fix
  final bool hasEphemeris;      // Has ephemeris data
  final bool hasAlmanac;        // Has almanac data
  final String? frequencyBand;  // L1, L5, etc.

  GnssSatellite({
    required this.prn,
    required this.constellation,
    this.snr = 0,
    this.elevation = 0,
    this.azimuth = 0,
    this.usedInFix = false,
    this.hasEphemeris = false,
    this.hasAlmanac = false,
    this.frequencyBand,
  });

  /// Get constellation color for UI
  int get constellationColor {
    switch (constellation) {
      case 'GPS':       return 0xFF4ADE80; // Green
      case 'GLONASS':   return 0xFF60A5FA; // Blue
      case 'Galileo':   return 0xFFFBBF24; // Yellow
      case 'BeiDou':    return 0xFFF97316; // Orange
      case 'QZSS':      return 0xFFA78BFA; // Purple
      case 'NavIC':     return 0xFFEF4444; // Red
      case 'SBAS':      return 0xFF34D399; // Emerald
      default:          return 0xFF71717A; // Grey
    }
  }

  /// Signal quality category
  String get signalQuality {
    if (snr >= 40) return 'Excellent';
    if (snr >= 30) return 'Good';
    if (snr >= 20) return 'Fair';
    if (snr >= 10) return 'Weak';
    return 'Very Weak';
  }

  /// Get constellation icon
  String get constellationIcon {
    switch (constellation) {
      case 'GPS':       return '🇺🇸';
      case 'GLONASS':   return '🇷🇺';
      case 'Galileo':   return '🇪🇺';
      case 'BeiDou':    return '🇨🇳';
      case 'QZSS':      return '🇯🇵';
      case 'NavIC':     return '🇮🇳';
      default:          return '🛰️';
    }
  }

  /// Convert to JSON for logging
  Map<String, dynamic> toJson() => {
    'prn': prn,
    'constellation': constellation,
    'snr': snr,
    'elevation': elevation,
    'azimuth': azimuth,
    'used_in_fix': usedInFix,
    'has_ephemeris': hasEphemeris,
    'has_almanac': hasAlmanac,
    'frequency_band': frequencyBand,
  };
}
