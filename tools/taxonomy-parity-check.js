#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const fixturePath = path.join(__dirname, '..', 'docs', 'fixtures', 'taxonomy-parity-v1.json');

function fail(message) {
  console.error(`[taxonomy-parity-check] ${message}`);
  process.exit(1);
}

function normalizeValue(value) {
  if (value == null) return '';
  return String(value).trim();
}

function getOrderedValues(vector, rankOrder) {
  const out = [];
  const source = vector.resolved_taxa || {};
  for (const rank of rankOrder) {
    out.push(normalizeValue(source[rank]));
  }
  return out;
}

function detectCombos(orderedValues) {
  let hasThreeInRow = false;
  let pairRuns = 0;

  let runStart = 0;
  while (runStart < orderedValues.length) {
    let runEnd = runStart;
    const runValue = orderedValues[runStart];
    while (runEnd + 1 < orderedValues.length && orderedValues[runEnd + 1] === runValue) {
      runEnd += 1;
    }

    const runLength = runEnd - runStart + 1;
    if (runValue !== '' && runValue !== 'X' && runValue !== '-') {
      if (runLength >= 3) hasThreeInRow = true;
      if (runLength >= 2) pairRuns += Math.floor(runLength / 2);
    }

    runStart = runEnd + 1;
  }

  return {
    three_in_a_row: hasThreeInRow,
    two_sets_of_two: pairRuns >= 2,
  };
}

function main() {
  if (!fs.existsSync(fixturePath)) {
    fail(`Fixture missing: ${fixturePath}`);
  }

  const fixture = JSON.parse(fs.readFileSync(fixturePath, 'utf8'));
  const vectors = Array.isArray(fixture.vectors) ? fixture.vectors : [];
  const rankOrder = fixture.rank_order || {};

  if (!Array.isArray(rankOrder.presence) || !Array.isArray(rankOrder.absence)) {
    fail('Fixture rank_order.presence and rank_order.absence must be arrays.');
  }

  if (vectors.length === 0) {
    fail('Fixture contains no vectors.');
  }

  let failures = 0;
  for (const vector of vectors) {
    const mode = vector.mode === 'absence' ? 'absence' : 'presence';
    const order = rankOrder[mode];
    const values = getOrderedValues(vector, order);
    const actual = detectCombos(values);
    const expected = vector.expected || {};

    const expectThree = Boolean(expected.three_in_a_row);
    const expectTwoSets = Boolean(expected.two_sets_of_two);

    if (actual.three_in_a_row !== expectThree || actual.two_sets_of_two !== expectTwoSets) {
      failures += 1;
      console.error(`FAIL ${vector.id}: expected three_in_a_row=${expectThree}, two_sets_of_two=${expectTwoSets}; got three_in_a_row=${actual.three_in_a_row}, two_sets_of_two=${actual.two_sets_of_two}`);
    } else {
      console.log(`PASS ${vector.id}`);
    }
  }

  if (failures > 0) {
    fail(`Parity failures: ${failures}`);
  }

  console.log(`[taxonomy-parity-check] OK (${vectors.length} vectors)`);
}

main();
