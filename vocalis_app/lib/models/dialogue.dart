class DialogueRule {
  final String id;
  final List<String> keywords;
  final String reply;
  final String? suggestion;

  const DialogueRule({
    required this.id,
    required this.keywords,
    required this.reply,
    this.suggestion,
  });
}

class DialogueScenario {
  final String id;
  final String title;
  final String partnerName;
  final String partnerBadge;
  final String avatarUrl;
  final ChatMessage initialMessage;
  final List<DialogueRule> rules;
  final DialogueRule defaultRule;

  const DialogueScenario({
    required this.id,
    required this.title,
    required this.partnerName,
    required this.partnerBadge,
    required this.avatarUrl,
    required this.initialMessage,
    required this.rules,
    required this.defaultRule,
  });
}

class DialogueMatchResult {
  final String text;
  final String? suggestion;
  final String? matchedRuleId;

  const DialogueMatchResult({
    required this.text,
    this.suggestion,
    this.matchedRuleId,
  });
}

class ChatMessage {
  final String id;
  final String sender; // 'ai' or 'user'
  final String text;
  final String timestamp;
  final String? suggestion;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.suggestion,
  });

  bool get isAi => sender == 'ai';
  bool get isUser => sender == 'user';
}

/// Matches user input against dialogue scenario rules using keyword matching.
DialogueMatchResult matchDialogueResponse(
  String input,
  DialogueScenario scenario,
) {
  final normalized = input.toLowerCase();

  for (final rule in scenario.rules) {
    final hasMatch = rule.keywords.any((kw) {
      final pattern = RegExp(
        '(^|\\s|[^a-zA-Z0-9])$kw(\$|\\s|[^a-zA-Z0-9])',
        caseSensitive: false,
      );
      return pattern.hasMatch(normalized) || normalized.contains(kw);
    });

    if (hasMatch) {
      return DialogueMatchResult(
        text: rule.reply,
        suggestion: rule.suggestion,
        matchedRuleId: rule.id,
      );
    }
  }

  return DialogueMatchResult(
    text: scenario.defaultRule.reply,
    suggestion: scenario.defaultRule.suggestion,
  );
}
