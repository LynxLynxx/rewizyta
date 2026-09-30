/**
 * The waitlist page's questions, by key. The page sends option keys, never its
 * Polish labels, so rewording a question does not split the answers. Keep in
 * step with `apps/website/lib/waitlist/survey.dart`.
 */
export const survey = {
  trade: { multi: true, options: ['chimney', 'gas', 'hvac', 'other'], other: 'other' },
  clients: { multi: false, options: ['under_50', '50_200', '200_500', 'over_500'] },
  platform: { multi: false, options: ['android', 'iphone', 'both'] },
  records: {
    multi: true,
    options: ['notebook', 'spreadsheet', 'phone_contacts', 'kiedyserwis', 'other_app'],
    other: 'other_app',
  },
  reminders: { multi: false, options: ['none', 'call', 'manual_sms', 'automatic'] },
  lost_clients: { multi: false, options: ['none', 'few', 'a_dozen_or_more', 'unknown'] },
  would_pay: { multi: false, options: ['yes', 'maybe', 'no'] },
} as const satisfies Record<string, Question>;

interface Question {
  multi: boolean;
  options: readonly string[];
  /** The option that opens a text field; its text arrives as `<question>_other`. */
  other?: string;
}

/** Stored as-is: a key per answered question, `<question>_other` for the free text. */
export type Answers = Record<string, string | string[]>;

export const maxOtherLength = 200;

/**
 * Checks what the page sent. Every question is optional; a single-choice
 * answer is one option key, a multiple-choice answer a non-empty list of
 * distinct keys, and the "other" text is allowed only when "other" is chosen.
 * Returns null for anything else, so nothing unexpected reaches the database.
 */
export function parseAnswers(value: unknown): Answers | null {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) return null;
  const input = value as Record<string, unknown>;
  const answers: Answers = {};

  for (const [key, answer] of Object.entries(input)) {
    if (key.endsWith('_other')) continue;
    const question: Question | undefined = (survey as Record<string, Question>)[key];
    if (question === undefined) return null;

    const chosen = question.multi ? answer : [answer];
    if (!Array.isArray(chosen) || chosen.length === 0 || new Set(chosen).size !== chosen.length) return null;
    if (!chosen.every((option) => question.options.includes(option))) return null;
    answers[key] = question.multi ? chosen : chosen[0];
  }

  for (const [key, text] of Object.entries(input)) {
    if (!key.endsWith('_other')) continue;
    const questionKey = key.slice(0, -'_other'.length);
    const question: Question | undefined = (survey as Record<string, Question>)[questionKey];
    const chosen = answers[questionKey];
    if (question?.other === undefined || typeof text !== 'string') return null;
    if (!(Array.isArray(chosen) ? chosen : [chosen]).includes(question.other)) return null;
    const trimmed = text.trim().slice(0, maxOtherLength);
    if (trimmed !== '') answers[key] = trimmed;
  }

  return answers;
}
