import 'package:flutter/foundation.dart';

/// Represents a physical dimension using SI base quantities.
///
/// Every physical quantity can be expressed as a product of powers of the
/// 7 SI base dimensions. This class stores those exponents and provides
/// operations for dimensional analysis.
///
/// ## SI Base Dimensions
/// | Symbol | Name | SI Unit | Example |
/// |--------|------|---------|---------|
/// | L | Length | meter (m) | distance, height |
/// | M | Mass | kilogram (kg) | weight, body mass |
/// | T | Time | second (s) | duration, period |
/// | I | Electric Current | ampere (A) | current flow |
/// | Θ | Temperature | kelvin (K) | body temp, weather |
/// | N | Amount of Substance | mole (mol) | chemical amounts |
/// | J | Luminous Intensity | candela (cd) | light brightness |
///
/// ## Usage
/// ```dart
/// // Base dimensions
/// final length = Dimension.L;
/// final time = Dimension.T;
///
/// // Compound dimensions via operators
/// final velocity = Dimension.L / Dimension.T;           // m/s
/// final acceleration = Dimension.L / (Dimension.T * Dimension.T); // m/s²
/// final force = Dimension.M * acceleration;             // kg·m/s² = N
///
/// // Or use predefined common dimensions
/// final speed = Dimension.velocity;
/// final energy = Dimension.energy;
///
/// // Arbitrary user-defined combinations
/// final custom = Dimension(length: 2, time: -1);  // m²/s (kinematic viscosity)
/// ```
@immutable
class Dimension {
  /// Length exponent (L) - meters
  final int length;

  /// Mass exponent (M) - kilograms
  final int mass;

  /// Time exponent (T) - seconds
  final int time;

  /// Electric current exponent (I) - amperes
  final int current;

  /// Thermodynamic temperature exponent (Θ) - kelvin
  final int temperature;

  /// Amount of substance exponent (N) - moles
  final int amount;

  /// Luminous intensity exponent (J) - candelas
  final int luminosity;

  /// Creates a dimension with the specified exponents.
  ///
  /// All exponents default to 0 (dimensionless).
  const Dimension({
    this.length = 0,
    this.mass = 0,
    this.time = 0,
    this.current = 0,
    this.temperature = 0,
    this.amount = 0,
    this.luminosity = 0,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SI BASE DIMENSIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Dimensionless quantity (pure number, ratio, angle in radians)
  static const dimensionless = Dimension();

  /// Length (L) - meter
  static const L = Dimension(length: 1);

  /// Mass (M) - kilogram
  static const M = Dimension(mass: 1);

  /// Time (T) - second
  static const T = Dimension(time: 1);

  /// Electric current (I) - ampere
  static const I = Dimension(current: 1);

  /// Thermodynamic temperature (Θ) - kelvin
  static const theta = Dimension(temperature: 1);

  /// Amount of substance (N) - mole
  static const N = Dimension(amount: 1);

  /// Luminous intensity (J) - candela
  static const J = Dimension(luminosity: 1);

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMON DERIVED DIMENSIONS - Mechanics
  // ═══════════════════════════════════════════════════════════════════════════

  /// Area (L²) - square meter
  static const area = Dimension(length: 2);

  /// Volume (L³) - cubic meter, liter
  static const volume = Dimension(length: 3);

  /// Velocity/Speed (L·T⁻¹) - meter per second
  static const velocity = Dimension(length: 1, time: -1);

  /// Acceleration (L·T⁻²) - meter per second squared
  static const acceleration = Dimension(length: 1, time: -2);

  /// Force (M·L·T⁻²) - newton
  static const force = Dimension(mass: 1, length: 1, time: -2);

  /// Pressure/Stress (M·L⁻¹·T⁻²) - pascal
  static const pressure = Dimension(mass: 1, length: -1, time: -2);

  /// Energy/Work/Heat (M·L²·T⁻²) - joule
  static const energy = Dimension(mass: 1, length: 2, time: -2);

  /// Power (M·L²·T⁻³) - watt
  static const power = Dimension(mass: 1, length: 2, time: -3);

  /// Momentum (M·L·T⁻¹) - kilogram meter per second
  static const momentum = Dimension(mass: 1, length: 1, time: -1);

  /// Density (M·L⁻³) - kilogram per cubic meter
  static const density = Dimension(mass: 1, length: -3);

  /// Frequency (T⁻¹) - hertz
  static const frequency = Dimension(time: -1);

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMON DERIVED DIMENSIONS - Electromagnetism
  // ═══════════════════════════════════════════════════════════════════════════

  /// Electric charge (I·T) - coulomb
  static const charge = Dimension(current: 1, time: 1);

  /// Voltage/EMF (M·L²·T⁻³·I⁻¹) - volt
  static const voltage = Dimension(mass: 1, length: 2, time: -3, current: -1);

  /// Resistance (M·L²·T⁻³·I⁻²) - ohm
  static const resistance = Dimension(mass: 1, length: 2, time: -3, current: -2);

  /// Capacitance (M⁻¹·L⁻²·T⁴·I²) - farad
  static const capacitance = Dimension(mass: -1, length: -2, time: 4, current: 2);

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMON DERIVED DIMENSIONS - Thermodynamics
  // ═══════════════════════════════════════════════════════════════════════════

  /// Heat capacity/Entropy (M·L²·T⁻²·Θ⁻¹) - joule per kelvin
  static const heatCapacity = Dimension(mass: 1, length: 2, time: -2, temperature: -1);

  // ═══════════════════════════════════════════════════════════════════════════
  // PRACTICAL DIMENSIONS - For tracking apps
  // ═══════════════════════════════════════════════════════════════════════════

  /// Rate (N·T⁻¹) - amount per time (calories/day, steps/hour)
  static const rate = Dimension(amount: 1, time: -1);

  /// Concentration (N·L⁻³) - moles per volume (or amount per volume)
  static const concentration = Dimension(amount: 1, length: -3);

  /// Mass flow rate (M·T⁻¹) - kg per second (water intake/day)
  static const massFlowRate = Dimension(mass: 1, time: -1);

  /// Volume flow rate (L³·T⁻¹) - liters per second
  static const volumeFlowRate = Dimension(length: 3, time: -1);

  // ═══════════════════════════════════════════════════════════════════════════
  // OPERATORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Multiplies two dimensions (adds exponents).
  ///
  /// Example: Mass × Acceleration = Force
  /// ```dart
  /// final force = Dimension.M * Dimension.acceleration;
  /// // M¹ × L¹T⁻² = M¹L¹T⁻²
  /// ```
  Dimension operator *(Dimension other) => Dimension(
        length: length + other.length,
        mass: mass + other.mass,
        time: time + other.time,
        current: current + other.current,
        temperature: temperature + other.temperature,
        amount: amount + other.amount,
        luminosity: luminosity + other.luminosity,
      );

  /// Divides two dimensions (subtracts exponents).
  ///
  /// Example: Length / Time = Velocity
  /// ```dart
  /// final velocity = Dimension.L / Dimension.T;
  /// // L¹ / T¹ = L¹T⁻¹
  /// ```
  Dimension operator /(Dimension other) => Dimension(
        length: length - other.length,
        mass: mass - other.mass,
        time: time - other.time,
        current: current - other.current,
        temperature: temperature - other.temperature,
        amount: amount - other.amount,
        luminosity: luminosity - other.luminosity,
      );

  /// Returns the inverse dimension (negates all exponents).
  ///
  /// Example: inverse of Time = Frequency
  /// ```dart
  /// final frequency = Dimension.T.inverse(); // T⁻¹
  /// ```
  Dimension inverse() => Dimension(
        length: -length,
        mass: -mass,
        time: -time,
        current: -current,
        temperature: -temperature,
        amount: -amount,
        luminosity: -luminosity,
      );

  /// Raises dimension to an integer power.
  ///
  /// Example: Length² = Area
  /// ```dart
  /// final area = Dimension.L.pow(2);  // L²
  /// final volume = Dimension.L.pow(3); // L³
  /// ```
  Dimension pow(int exponent) => Dimension(
        length: length * exponent,
        mass: mass * exponent,
        time: time * exponent,
        current: current * exponent,
        temperature: temperature * exponent,
        amount: amount * exponent,
        luminosity: luminosity * exponent,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns true if this is a dimensionless quantity.
  bool get isDimensionless =>
      length == 0 &&
      mass == 0 &&
      time == 0 &&
      current == 0 &&
      temperature == 0 &&
      amount == 0 &&
      luminosity == 0;

  /// Returns true if this is a base dimension (only one non-zero exponent of 1).
  bool get isBase {
    final exponents = [length, mass, time, current, temperature, amount, luminosity];
    return exponents.where((e) => e != 0).length == 1 &&
        exponents.any((e) => e == 1);
  }

  /// Returns true if this dimension is compatible with another.
  /// Two dimensions are compatible if they are equal.
  bool isCompatibleWith(Dimension other) => this == other;

  // ═══════════════════════════════════════════════════════════════════════════
  // SERIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a Dimension from a JSON map.
  factory Dimension.fromJson(Map<String, dynamic> json) => Dimension(
        length: json['L'] as int? ?? 0,
        mass: json['M'] as int? ?? 0,
        time: json['T'] as int? ?? 0,
        current: json['I'] as int? ?? 0,
        temperature: json['Θ'] as int? ?? 0,
        amount: json['N'] as int? ?? 0,
        luminosity: json['J'] as int? ?? 0,
      );

  /// Converts this Dimension to a JSON map.
  /// Only includes non-zero exponents for compactness.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (length != 0) map['L'] = length;
    if (mass != 0) map['M'] = mass;
    if (time != 0) map['T'] = time;
    if (current != 0) map['I'] = current;
    if (temperature != 0) map['Θ'] = temperature;
    if (amount != 0) map['N'] = amount;
    if (luminosity != 0) map['J'] = luminosity;
    return map;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EQUALITY & DISPLAY
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dimension &&
          length == other.length &&
          mass == other.mass &&
          time == other.time &&
          current == other.current &&
          temperature == other.temperature &&
          amount == other.amount &&
          luminosity == other.luminosity;

  @override
  int get hashCode => Object.hash(
        length,
        mass,
        time,
        current,
        temperature,
        amount,
        luminosity,
      );

  /// Returns a human-readable string representation.
  ///
  /// Uses SI symbols with superscript exponents:
  /// - "L¹T⁻¹" for velocity
  /// - "M¹L²T⁻²" for energy
  /// - "1" for dimensionless
  @override
  String toString() {
    if (isDimensionless) return '1';

    final parts = <String>[];
    if (length != 0) parts.add('L${_formatExponent(length)}');
    if (mass != 0) parts.add('M${_formatExponent(mass)}');
    if (time != 0) parts.add('T${_formatExponent(time)}');
    if (current != 0) parts.add('I${_formatExponent(current)}');
    if (temperature != 0) parts.add('Θ${_formatExponent(temperature)}');
    if (amount != 0) parts.add('N${_formatExponent(amount)}');
    if (luminosity != 0) parts.add('J${_formatExponent(luminosity)}');

    return parts.join('·');
  }

  /// Returns a more readable format like "m/s" or "kg·m/s²"
  String toReadableString() {
    if (isDimensionless) return 'dimensionless';

    // Try to match common dimensions first
    final name = _commonName;
    if (name != null) return name;

    // Otherwise build from parts
    return toString();
  }

  String? get _commonName {
    if (this == dimensionless) return 'dimensionless';
    if (this == L) return 'length';
    if (this == M) return 'mass';
    if (this == T) return 'time';
    if (this == I) return 'current';
    if (this == theta) return 'temperature';
    if (this == N) return 'amount';
    if (this == J) return 'luminosity';
    if (this == area) return 'area';
    if (this == volume) return 'volume';
    if (this == velocity) return 'velocity';
    if (this == acceleration) return 'acceleration';
    if (this == force) return 'force';
    if (this == pressure) return 'pressure';
    if (this == energy) return 'energy';
    if (this == power) return 'power';
    if (this == momentum) return 'momentum';
    if (this == density) return 'density';
    if (this == frequency) return 'frequency';
    if (this == charge) return 'charge';
    if (this == voltage) return 'voltage';
    if (this == resistance) return 'resistance';
    if (this == rate) return 'rate';
    if (this == concentration) return 'concentration';
    if (this == massFlowRate) return 'mass flow rate';
    if (this == volumeFlowRate) return 'volume flow rate';
    return null;
  }

  static String _formatExponent(int n) {
    if (n == 1) return '';
    const superscripts = {
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
      '-': '⁻',
    };
    return n.toString().split('').map((c) => superscripts[c] ?? c).join();
  }
}
