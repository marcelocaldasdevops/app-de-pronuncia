import { DialogueScenario, DialogueMatchResult } from './types';
import { coffeeNycScenario } from './coffee-nyc';

export * from './types';
export { coffeeNycScenario };

/**
 * Matches user input against dialogue scenario rules using keyword matching.
 */
export function matchDialogueResponse(
  input: string,
  scenario: DialogueScenario
): DialogueMatchResult {
  const normalized = input.toLowerCase();

  for (const rule of scenario.rules) {
    const hasMatch = rule.keywords.some((kw) => {
      // Check word boundary or clean substring match
      const regex = new RegExp(`(^|\\s|[^a-zA-Z0-9])${kw}($|\\s|[^a-zA-Z0-9])`, 'i');
      return regex.test(normalized) || normalized.includes(kw);
    });

    if (hasMatch) {
      return {
        text: rule.reply,
        suggestion: rule.suggestion,
        matchedRuleId: rule.id,
      };
    }
  }

  return {
    text: scenario.defaultRule.reply,
    suggestion: scenario.defaultRule.suggestion,
  };
}
