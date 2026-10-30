// Rule-based routing (Week 13).
// Trigger: a new issue is reported.
// Input: title + description text. Output: category, priority, team, status.
// Rules are checked in order; the FIRST match wins, so urgent/safety rules go first.

const RULES = [
  {
    category: 'safety',
    priority: 'urgent',
    keywords: ['fire', 'smoke', 'spark', 'sparks', 'sparking', 'exposed wire', 'gas leak', 'shock', 'injury', 'broken glass', 'unsafe'],
  },
  {
    category: 'electrical',
    priority: 'high',
    keywords: ['light', 'lights', 'lamp', 'bulb', 'outlet', 'socket', 'power', 'electric', 'switch', 'breaker', 'flickering'],
  },
  {
    category: 'plumbing',
    priority: 'high',
    keywords: ['leak', 'leaking', 'faucet', 'toilet', 'sink', 'pipe', 'drain', 'clogged', 'flood', 'flooded'],
  },
  {
    category: 'airConditioning',
    priority: 'medium',
    keywords: ['aircon', 'air con', 'air conditioner', 'air conditioning', 'ac', 'cooling', 'too hot', 'too cold'],
  },
  {
    category: 'itEquipment',
    priority: 'medium',
    keywords: ['projector', 'computer', 'pc', 'monitor', 'wifi', 'wi-fi', 'internet', 'keyboard', 'mouse', 'printer', 'router'],
  },
  {
    category: 'furniture',
    priority: 'low',
    keywords: ['chair', 'desk', 'table', 'whiteboard', 'cabinet', 'shelf'],
  },
  {
    category: 'cleanliness',
    priority: 'low',
    keywords: ['dirty', 'trash', 'garbage', 'spill', 'smell', 'cockroach', 'pest', 'mess'],
  },
];

// Category -> responsible team. Same category names as the Flutter IssueCategory enum.
const TEAMS = {
  electrical: 'Electrical Maintenance',
  plumbing: 'Plumbing Maintenance',
  airConditioning: 'HVAC Maintenance',
  furniture: 'Carpentry and Furniture',
  itEquipment: 'IT Support',
  cleanliness: 'Janitorial Services',
  safety: 'Campus Safety Office',
  other: 'Coordinator Triage',
};

const FALLBACK_TEAM = 'Coordinator Triage';

function teamFor(category) {
  return TEAMS[category] || FALLBACK_TEAM;
}

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function containsKeyword(text, keyword) {
  return new RegExp(`\\b${escapeRegExp(keyword)}\\b`, 'i').test(text);
}

// Returns { matched, category, priority, status, team, matchedKeyword }.
function routeIssue(title, description) {
  const text = `${title} ${description}`;
  for (const rule of RULES) {
    const hit = rule.keywords.find((k) => containsKeyword(text, k));
    if (hit) {
      return {
        matched: true,
        category: rule.category,
        priority: rule.priority,
        status: 'categorized',
        team: teamFor(rule.category),
        matchedKeyword: hit,
      };
    }
  }
  // No rule matched: leave for a human coordinator.
  return {
    matched: false,
    category: null,
    priority: 'medium',
    status: 'reported',
    team: FALLBACK_TEAM,
    matchedKeyword: null,
  };
}

module.exports = { RULES, TEAMS, teamFor, routeIssue };