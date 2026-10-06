enum MotionSensitivity {
  low(label: 'Low', threshold: 4),
  medium(label: 'Medium', threshold: 2.5),
  high(label: 'High', threshold: 1.6);

  const MotionSensitivity({required this.label, required this.threshold});

  final String label;

  final double threshold;
}
