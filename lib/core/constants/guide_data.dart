// lib/core/constants/guide_data.dart

class GuideData {
  static const Map<String, Map<String, String>> screenGuides = {
    'core': {
      'label': 'SENTINEL',
      'message':
          'Welcome to the Core. This is your neural command center. Track your daily syncs here.',
    },
    'vault': {
      'label': 'SENTINEL',
      'message':
          'The Vault archives your decrypted Bot Cards. Collect more cards to evolve your neural level.',
    },
    'habits': {
      'label': 'HABIT_PROTOCOL',
      'message':
          "Habits are long-term rewiring. Use them for tasks that don't have a strict daily deadline.",
    },
    'dailies': {
      'label': 'DAILY_SYNC',
      'message':
          'Make Dailies for time sensitive tasks that need to be done on a regular schedule.',
    },
    'dossier': {
      'label': 'USER_DOSSIER',
      'message':
          'This is your encrypted profile. You can modify your Neural ID here and view your total XP.',
    },
  };
}
