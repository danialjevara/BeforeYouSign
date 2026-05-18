import 'package:flutter/foundation.dart';

@immutable
class HighlightedClause {
  const HighlightedClause({
    required this.excerpt,
    required this.highlightStart,
    required this.highlightEnd,
  });

  final String excerpt;
  final int highlightStart;
  final int highlightEnd;

  bool get hasHighlight => highlightStart >= 0 && highlightEnd > highlightStart;
}

HighlightedClause buildHighlightedClause({
  required String documentText,
  required String evidence,
}) {
  final compactDocument = _compactWhitespace(documentText);
  final compactEvidence = _compactWhitespace(
    evidence.replaceAll('"', '').replaceAll("'", ''),
  );

  if (compactEvidence.isEmpty) {
    return const HighlightedClause(
      excerpt: '',
      highlightStart: -1,
      highlightEnd: -1,
    );
  }

  final searchCandidates = _buildSearchCandidates(compactEvidence);
  final documentLower = compactDocument.toLowerCase();

  for (final candidate in searchCandidates) {
    final matchIndex = documentLower.indexOf(candidate.toLowerCase());
    if (matchIndex == -1) {
      continue;
    }

    const contextRadius = 88;
    final excerptStart = (matchIndex - contextRadius).clamp(
      0,
      compactDocument.length,
    );
    final excerptEnd = (matchIndex + candidate.length + contextRadius).clamp(
      0,
      compactDocument.length,
    );

    var excerpt = compactDocument.substring(excerptStart, excerptEnd).trim();
    var highlightStart = matchIndex - excerptStart;
    var highlightEnd = highlightStart + candidate.length;

    if (excerptStart > 0) {
      excerpt = '...$excerpt';
      highlightStart += 3;
      highlightEnd += 3;
    }
    if (excerptEnd < compactDocument.length) {
      excerpt = '$excerpt...';
    }

    return HighlightedClause(
      excerpt: excerpt,
      highlightStart: highlightStart,
      highlightEnd: highlightEnd,
    );
  }

  return HighlightedClause(
    excerpt: compactEvidence,
    highlightStart: 0,
    highlightEnd: compactEvidence.length,
  );
}

List<String> _buildSearchCandidates(String evidence) {
  final candidates = <String>{};

  void addCandidate(String value) {
    final normalized = _compactWhitespace(
      value.replaceAll(RegExp(r'^[.]+|[.]+$'), ''),
    );
    if (normalized.length >= 6) {
      candidates.add(normalized);
    }
  }

  addCandidate(evidence);
  for (final piece in evidence.split('...')) {
    addCandidate(piece);
  }
  for (final piece in evidence.split(RegExp(r'[,:;]'))) {
    addCandidate(piece);
  }

  final ordered = candidates.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  return ordered;
}

String _compactWhitespace(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
