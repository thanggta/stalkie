// lib/src/rules/predicate.dart
class PredicateFormatException implements Exception {
  final String message;
  PredicateFormatException(this.message);
  @override
  String toString() => 'PredicateFormatException: $message';
}

class GameState {
  final Set<String> carvedFragmentIds;
  /// Canonical form: two entity ids sorted and joined with '|'.
  final Set<String> linkedPairs;
  final Set<String> answeredQuestionIds;

  const GameState({
    required this.carvedFragmentIds,
    required this.linkedPairs,
    required this.answeredQuestionIds,
  });

  static String linkKey(String a, String b) {
    final pair = [a, b]..sort();
    return '${pair[0]}|${pair[1]}';
  }

  bool hasLink(String a, String b) =>
      linkedPairs.contains(linkKey(a, b)) || linkedPairs.contains('$a|$b') ||
      linkedPairs.contains('$b|$a');
}

abstract class Predicate {
  const Predicate();
  bool evaluate(GameState s);
}

class CarvedPredicate extends Predicate {
  final String fragmentId;
  const CarvedPredicate(this.fragmentId);
  @override
  bool evaluate(GameState s) => s.carvedFragmentIds.contains(fragmentId);
}

class LinkedPredicate extends Predicate {
  final String a;
  final String b;
  const LinkedPredicate(this.a, this.b);
  @override
  bool evaluate(GameState s) => s.hasLink(a, b);
}

class AnsweredPredicate extends Predicate {
  final String questionId;
  const AnsweredPredicate(this.questionId);
  @override
  bool evaluate(GameState s) => s.answeredQuestionIds.contains(questionId);
}

class AllPredicate extends Predicate {
  final List<Predicate> children;
  const AllPredicate(this.children);
  @override
  bool evaluate(GameState s) => children.every((c) => c.evaluate(s));
}

class AnyPredicate extends Predicate {
  final List<Predicate> children;
  const AnyPredicate(this.children);
  @override
  bool evaluate(GameState s) => children.any((c) => c.evaluate(s));
}

class NotPredicate extends Predicate {
  final Predicate child;
  const NotPredicate(this.child);
  @override
  bool evaluate(GameState s) => !child.evaluate(s);
}

/// The complete grammar. Adding a key requires a decision record in the design spec.
const _allowedKeys = {'carved', 'linked', 'answered', 'all', 'any', 'not'};

Predicate parsePredicate(Map<String, dynamic> json) {
  if (json.length != 1) {
    throw PredicateFormatException(
        'A predicate must have exactly one key, got ${json.keys.toList()}');
  }
  final key = json.keys.first;
  if (!_allowedKeys.contains(key)) {
    throw PredicateFormatException(
        'Unknown predicate "$key". Allowed: ${_allowedKeys.join(', ')}. '
        'Expression strings and script references are not supported (INV-5).');
  }
  final value = json[key];

  switch (key) {
    case 'carved':
      if (value is! String) {
        throw PredicateFormatException('"carved" needs a fragment id string');
      }
      return CarvedPredicate(value);
    case 'answered':
      if (value is! String) {
        throw PredicateFormatException('"answered" needs a question id string');
      }
      return AnsweredPredicate(value);
    case 'linked':
      if (value is! List || value.length != 2) {
        throw PredicateFormatException('"linked" needs exactly two entity ids');
      }
      return LinkedPredicate(value[0] as String, value[1] as String);
    case 'all':
    case 'any':
      if (value is! List || value.isEmpty) {
        throw PredicateFormatException('"$key" needs a non-empty list');
      }
      final children = value
          .map((c) => parsePredicate(Map<String, dynamic>.from(c as Map)))
          .toList();
      return key == 'all' ? AllPredicate(children) : AnyPredicate(children);
    case 'not':
      if (value is! Map) {
        throw PredicateFormatException('"not" needs a predicate object');
      }
      return NotPredicate(parsePredicate(Map<String, dynamic>.from(value)));
    default:
      throw PredicateFormatException('Unreachable');
  }
}
