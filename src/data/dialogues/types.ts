export interface DialogueRule {
  id: string;
  keywords: string[];
  reply: string;
  suggestion?: string;
}

export interface DialogueScenario {
  id: string;
  title: string;
  partnerName: string;
  partnerBadge: string;
  avatarUrl: string;
  initialMessage: {
    text: string;
    suggestion?: string;
  };
  rules: DialogueRule[];
  defaultRule: {
    reply: string;
    suggestion?: string;
  };
}

export interface DialogueMatchResult {
  text: string;
  suggestion?: string;
  matchedRuleId?: string;
}
