enum MotionSensitivity {
  low(label: 'Low', threshold: 4),
  medium(label: 'Medium', threshold: 2.5),
  high(label: 'High', threshold: 1.6);

  const MotionSensitivity({required this.label, required this.threshold});

  final String label;

  /// How sharply acceleration in m/s² has to jump between two readings for a
  /// tap. Lower picks up softer taps, and more accidental bumps.
  final double threshold;
}
