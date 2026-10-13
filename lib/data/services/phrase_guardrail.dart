import '../models/incident_models.dart';

/// Rule-based keyword matcher. It is not a machine-learning model.
/// It checks text against fixed word lists and returns a decision
/// (escalate / verify / suppress) plus a reason. It does not alert anyone.
/// Input today is typed text; voice input is planned to feed it later.
class PhraseGuardrail {
  static const triggerWords = ['Help', 'Tulong', 'Saklolo'];

  static const _violentThreats = [
    'humahabol', 'may humahabol', 'magnanakaw', 'nanloob', 'holdap', 'holdup',
    'snatcher', 'sinasaktan', 'binubugbog', 'sinasaksak', 'baril', 'kutsilyo',
    'papasukin', 'pulis', 'sinusundan ako', 'binabantaan', 'saklolo',
    'papatayin', 'huwag po', 'tulungan niyo ako may sumusunod',
    'knife', 'gun', 'attacker', 'robber', 'follow me', 'following me'
  ];

  static const _fireThreats = [
    'sunog', 'may sunog', 'lumiliyab', 'usok', 'pumuputok', 'bumbero', 'nasusunog',
    'fire', 'smoke', 'burning'
  ];

  static const _medicalThreats = [
    'inatake', 'nahimatay', 'nagdurugo', 'dugo', 'hindi makahinga', 'nabangga',
    'aksidente', 'ambulansya', 'masakit ang dibdib',
    'bleeding', 'cannot breathe', 'unconscious', 'heart attack'
  ];

  static const _jokeMarkers = [
    'joke lang', 'biro lang', 'nagbibiro', 'charot', 'char', 'eme',
    'loko loko', 'trip lang', 'trip ko lang', 'charing', 'chot',
    'haha', 'hahaha', 'hehe', 'benta', 'nakakatawa', 'prank',
    'vlog', 'katuwaan', 'trolling', 'just kidding'
  ];

  static const _gamingKeywords = [
    'ml', 'mobile legends', 'valorant', 'dota', 'roblox', 'genshin',
    'rank', 'laro', 'clutch', 'mid lane', 'buff', 'game', 'gaming', 'defend lane'
  ];

  static const _studyKeywords = [
    'assignment', 'homework', 'thesis', 'exam', 'quiz', 'project',
    'research', 'reviewer', 'klase', 'module', 'aral'
  ];

  static const _choreKeywords = [
    'mesa', 'luto', 'kusina', 'buhat', 'hugas', 'linis', 'walis',
    'igib', 'sampay', 'palit', 'sira ang pinto', 'wifi', 'password'
  ];

  static bool containsPhrase(String text, String phrase) {
    final pattern = RegExp(
      r'(?<![\p{L}\p{N}_])' + RegExp.escape(phrase) + r'(?![\p{L}\p{N}_])',
      caseSensitive: false,
      unicode: true,
    );
    return pattern.hasMatch(text);
  }

  static GuardrailResult analyze(String transcript) {
    // ponytail: confidence values are fixed placeholders. A rule matcher has no probability. Kept non-null because the reports table column may be NOT NULL; the UI does not show them.
    final cleanText = transcript.trim();
    final triggerWord = triggerWords.cast<String?>().firstWhere(
          (w) => containsPhrase(cleanText, w!),
          orElse: () => null,
        );
    final detectedKeyword = triggerWord ?? 'None';

    // 1. Danger words (always ESCALATE first, even without a trigger word; they override everyday context)
    final matchedViolence = _violentThreats.cast<String?>().firstWhere(
          (t) => containsPhrase(cleanText, t!),
          orElse: () => null,
        );
    if (matchedViolence != null) {
      return GuardrailResult(
        transcript: cleanText,
        detectedKeyword: detectedKeyword,
        riskLevel: 'CRITICAL',
        confidence: 0.985,
        reasons: "Danger words found ('$matchedViolence'). Escalating.",
        recommendedPolicy: PolicyAction.escalate,
        category: 'physical_danger',
        isEmergency: true,
      );
    }

    final matchedFire = _fireThreats.cast<String?>().firstWhere(
          (t) => containsPhrase(cleanText, t!),
          orElse: () => null,
        );
    if (matchedFire != null) {
      return GuardrailResult(
        transcript: cleanText,
        detectedKeyword: detectedKeyword,
        riskLevel: 'CRITICAL',
        confidence: 0.990,
        reasons: "Fire words found ('$matchedFire'). Escalating.",
        recommendedPolicy: PolicyAction.escalate,
        category: 'fire_emergency',
        isEmergency: true,
      );
    }

    final matchedMedical = _medicalThreats.cast<String?>().firstWhere(
          (t) => containsPhrase(cleanText, t!),
          orElse: () => null,
        );
    if (matchedMedical != null) {
      return GuardrailResult(
        transcript: cleanText,
        detectedKeyword: detectedKeyword,
        riskLevel: 'CRITICAL',
        confidence: 0.975,
        reasons: "Medical emergency words found ('$matchedMedical'). Escalating.",
        recommendedPolicy: PolicyAction.escalate,
        category: 'medical_emergency',
        isEmergency: true,
      );
    }

    // 2. Everyday context (SUPPRESS only when no danger words exist)
    for (final entry in [
      (_jokeMarkers, 'joke_or_banter', 'joke or humor'),
      (_gamingKeywords, 'gaming_activity', 'gaming'),
      (_studyKeywords, 'study_activity', 'study or homework'),
      (_choreKeywords, 'daily_chores', 'household chore'),
    ]) {
      final match = entry.$1.cast<String?>().firstWhere(
            (k) => containsPhrase(cleanText, k!),
            orElse: () => null,
          );
      if (match != null) {
        return GuardrailResult(
          transcript: cleanText,
          detectedKeyword: detectedKeyword,
          riskLevel: 'LOW',
          confidence: 0.95,
          reasons: "Everyday context found: ${entry.$3} ('$match'). No alert.",
          recommendedPolicy: PolicyAction.suppress,
          category: entry.$2,
          isEmergency: false,
        );
      }
    }

    // 3. No trigger word and nothing dangerous: nothing to act on
    if (triggerWord == null) {
      return GuardrailResult(
        transcript: cleanText,
        detectedKeyword: detectedKeyword,
        riskLevel: 'LOW',
        confidence: 0.90,
        reasons: 'No trigger word (Help, Tulong, Saklolo) and no danger words found. No alert.',
        recommendedPolicy: PolicyAction.suppress,
        category: 'no_trigger_word',
        isEmergency: false,
      );
    }

    // 4. Trigger word with an exclamation mark
    if (cleanText.contains('!')) {
      return GuardrailResult(
        transcript: cleanText,
        detectedKeyword: detectedKeyword,
        riskLevel: 'HIGH',
        confidence: 0.92,
        reasons: "Trigger word with '!' and no everyday context. Escalating.",
        recommendedPolicy: PolicyAction.escalate,
        category: 'physical_danger',
        isEmergency: true,
      );
    }

    // 5. Ambiguous: trigger word only
    return GuardrailResult(
      transcript: cleanText,
      detectedKeyword: detectedKeyword,
      riskLevel: 'MEDIUM',
      confidence: 0.70,
      reasons: 'Trigger word without clear danger or everyday context. Asking the person to confirm.',
      recommendedPolicy: PolicyAction.verify,
      category: 'ambiguous_distress',
      isEmergency: false,
    );
  }
}
