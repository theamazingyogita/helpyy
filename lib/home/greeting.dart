String greetingFor(DateTime time) => switch (time.hour) {
  < 5 => 'Up late',
  < 12 => 'Good morning',
  < 17 => 'Good afternoon',
  _ => 'Good evening',
};
