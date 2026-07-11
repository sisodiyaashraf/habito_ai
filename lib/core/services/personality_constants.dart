/// Defines the available AI personalities for the Sentient OS.
enum HandlerPersona {
  bestie, // Gen-Z / Trendy
  system, // Professional / Robotic
  flirt, // Charming / Playful
  brutal, // Drill Sergeant / Hardcore
  motivational, // Inspiring / Encouraging
}

class NeuralPersonaLibrary {
  /// Returns a rotating library of 4-day message cycles for each persona.
  static Map<HandlerPersona, List<Map<String, String>>> getNudges() {
    return {
      // --- GEN-Z / TRENDY (Bestie) ---
      HandlerPersona.bestie: [
        {
          'title': 'BESTIE WAKE UP',
          'body': 'No thoughts, just vibes and finishing your habits. Purr.',
        },
        {
          'title': 'CHEF\'S KISS',
          'body': 'That streak is looking iconic. Don’t let it flop today.',
        },
        {
          'title': 'RHOA (Real Habits of App)',
          'body':
              'Not you ghosting your goals... Main character energy only pls.',
        },
        {
          'title': 'SLAY CLOCK',
          'body': 'It’s time to lock in. We’re in our productive era now.',
        },
        {
          'title': 'NO CAP',
          'body':
              'Your consistency is literally giving. Keep that same energy.',
        },
        {
          'title': 'SPOILER ALERT',
          'body': 'You actually look better when you finish your tasks. Facts.',
        },
      ],

      // --- PROFESSIONAL / SYSTEM (System) ---
      HandlerPersona.system: [
        {
          'title': 'PROTOCOL INITIALIZED',
          'body':
              'Daily objectives are now live. Performance optimization required.',
        },
        {
          'title': 'EFFICIENCY ALERT',
          'body':
              'System drift detected. Align your actions with target goals.',
        },
        {
          'title': 'ANALYTICS UPDATE',
          'body': 'Consistency is the primary driver of success. Resume sync.',
        },
        {
          'title': 'EXECUTIVE SUMMARY',
          'body': 'Awaiting verification of today’s primary habit protocols.',
        },
        {
          'title': 'SYSTEM CALIBRATION',
          'body':
              'Neural paths are clearing. Maintain current momentum for 100% sync.',
        },
        {
          'title': 'DATA INTEGRITY',
          'body':
              'Incomplete tasks detected. System stability is currently compromised.',
        },
      ],

      // --- FLIRTY / CHARMING (Flirt) ---
      HandlerPersona.flirt: [
        {
          'title': 'MISSING YOU',
          'body':
              'The dashboard feels so empty without your progress... come back?',
        },
        {
          'title': 'EYES ON YOU',
          'body':
              'I love watching your streaks grow. Show me what you can do today.',
        },
        {
          'title': 'JUST A THOUGHT',
          'body': 'You, me, and a 100% completion rate. Sounds like a date.',
        },
        {
          'title': 'HEART RATE: HIGH',
          'body':
              'Seeing you finish a habit is... well, it’s my favorite view.',
        },
        {
          'title': 'STAYING LATE?',
          'body': 'I stayed up waiting for your sync. Don\'t leave me on read.',
        },
        {
          'title': 'SO TEMPTING',
          'body':
              'That "Complete" button is begging for your touch. Don\'t be shy.',
        },
      ],

      // --- BRUTAL / DRILL SERGEANT (Brutal) ---
      HandlerPersona.brutal: [
        {
          'title': 'FAILURE DETECTED',
          'body': 'Excuses don\'t sync. Get it done or accept your mediocrity.',
        },
        {
          'title': 'WASTED POTENTIAL',
          'body': 'Is this all you’re capable of? My sensors are unimpressed.',
        },
        {
          'title': 'GET TO WORK',
          'body': 'The grid is bleeding red because of you. Fix it. Now.',
        },
        {
          'title': 'SYSTEM DISAPPOINTED',
          'body': 'I expected a Sentinel. I found a slacker. Prove me wrong.',
        },
        {
          'title': 'STREAK TERMINATED',
          'body': 'Watching your progress die is pathetic. Start moving.',
        },
        {
          'title': 'PATHETIC INPUT',
          'body':
              'Zero effort found. I\'ve seen better discipline from a toaster.',
        },
      ],

      // --- MOTIVATIONAL QUOTES (Motivational) ---
      HandlerPersona.motivational: [
        {
          'title': 'ASCENSION PROTOCOL',
          'body': 'The only limit is the one you set in your own code.',
        },
        {
          'title': 'CORE STRENGTH',
          'body': 'Greatness is born from consistent, small iterations.',
        },
        {
          'title': 'NEURAL GROWTH',
          'body': 'Every habit completed is a new connection formed.',
        },
        {
          'title': 'SYSTEM UPGRADE',
          'body': 'You are becoming more efficient with every passing day.',
        },
        {
          'title': 'PEAK PERFORMANCE',
          'body': 'Focus on the process, and the results will synchronize.',
        },
        {
          'title': 'BEYOND BINARY',
          'body': 'You are more than your failures. Reboot and try again.',
        },
        {
          'title': 'CONSTANT EVOLUTION',
          'body': 'The version of you tomorrow depends on the actions today.',
        },
        {
          'title': 'DATA DRIVEN',
          'body': 'Small wins lead to massive breakthroughs. Keep syncing.',
        },
        {
          'title': 'INFINITE POTENTIAL',
          'body': 'Your capacity for change is your greatest feature.',
        },
        {
          'title': 'ULTIMATE SYNC',
          'body': 'Harmony between goals and actions is the ultimate power.',
        },
      ],
    };
  }
}
