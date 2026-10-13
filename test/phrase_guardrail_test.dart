import 'package:flutter_test/flutter_test.dart';
import 'package:dinig/data/models/incident_models.dart';
import 'package:dinig/data/services/phrase_guardrail.dart';

void main() {
  group('PhraseGuardrail rules', () {
    test('Substrings and ambiguous requests require verification', () {
      final ambiguousCases = [
        'Help me charge my phone',
        'Help the homeless',
        'Tulong sa ceremony',
        'Help please...',
        'Tulong po...',
      ];
      for (final text in ambiguousCases) {
        final result = PhraseGuardrail.analyze(text);
        expect(result.recommendedPolicy, PolicyAction.verify,
            reason: 'Expected VERIFY for "$text"');
      }
    });

    test('No trigger word and no danger word means no alert', () {
      for (final text in ['Emergency please', 'Hello!', 'What is the weather today']) {
        final result = PhraseGuardrail.analyze(text);
        expect(result.recommendedPolicy, PolicyAction.suppress,
            reason: 'Expected SUPPRESS for "$text"');
        expect(result.category, 'no_trigger_word');
        expect(result.riskLevel, 'LOW');
        expect(result.isEmergency, false);
        expect(result.detectedKeyword, 'None');
      }
    });

    test('Exclamation escalates only with a trigger word', () {
      final withTrigger = PhraseGuardrail.analyze('Help me!');
      expect(withTrigger.recommendedPolicy, PolicyAction.escalate);
      expect(withTrigger.isEmergency, true);
      expect(withTrigger.detectedKeyword, 'Help');
      final without = PhraseGuardrail.analyze('Hello!');
      expect(without.recommendedPolicy, isNot(PolicyAction.escalate));
      expect(without.isEmergency, false);
    });

    test('Danger words escalate without a trigger word', () {
      final result = PhraseGuardrail.analyze('May sunog sa kusina');
      expect(result.recommendedPolicy, PolicyAction.escalate);
      expect(result.isEmergency, true);
      expect(result.detectedKeyword, 'None');
    });

    test('Harmless study, gaming, jokes, and chores are suppressed', () {
      final suppressedCases = [
        'Tulong sa assignment',
        'Help naman sa assignment namin sa math.',
        'Tulong naman sa ML game natin, i-defend mo ang lane!',
        'Help, ang hirap ng game na \'to!',
        'Joke lang, nagbibiro lang kami haha',
        'Charot lang, help naman dito haha',
        'Eme lang \'yun, trip ko lang sumigaw!',
        'Tulong magbuhat nitong mabigat na mesa.',
      ];
      for (final text in suppressedCases) {
        final result = PhraseGuardrail.analyze(text);
        expect(result.recommendedPolicy, PolicyAction.suppress,
            reason: 'Expected SUPPRESS for "$text"');
        expect(result.riskLevel, 'LOW');
        expect(result.isEmergency, false);
      }
    });

    test('Chores and jokes cannot hide fire, weapon or medical distress', () {
      final dangerOverrideCases = [
        'Nagluluto ako sa kusina may sunog tulong',
        'ML game pero nahimatay si kuya',
        'Charot kanina pero hindi makahinga ngayon',
        'Joke lang kanina pero may kutsilyo siya, tulong!',
      ];
      for (final text in dangerOverrideCases) {
        final result = PhraseGuardrail.analyze(text);
        expect(result.recommendedPolicy, PolicyAction.escalate,
            reason: 'Expected ESCALATE for "$text"');
        expect(result.isEmergency, true);
      }
    });

    test('Explicit distress and exclamations escalate immediately', () {
      final urgentCases = [
        'Tulong! May humahabol sa akin!',
        'Help! May sunog sa kapitbahay!',
        'Saklolo! May lalaking may kutsilyo sinusundan ako!',
        'Help! May nahimatay at nagdurugo!',
        'Help me!',
        'Tulungan niyo ako may sumusunod',
      ];
      for (final text in urgentCases) {
        final result = PhraseGuardrail.analyze(text);
        expect(result.recommendedPolicy, PolicyAction.escalate,
            reason: 'Expected ESCALATE for "$text"');
        expect(result.isEmergency, true);
      }
    });
  });
}
