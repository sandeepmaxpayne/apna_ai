import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../screens/webview_screen.dart';

Widget formatMessageText(String text, {TextStyle? baseStyle}) {
  // Step 1: Clean redundant markdown characters like ### or ****
  String cleaned = text.replaceAll(RegExp(r'[#+]+'), '').trim();

  // Step 2: Regex for markdown (bold, italic, code, links, URLs)
  final regex = RegExp(
    r'(\*\*.*?\*\*)|(\*.*?\*)|(`.*?`)|(\[([^\]]+)\]\((https?:\/\/[^\s)]+)\))|(https?:\/\/[^\s]+)',
    dotAll: true,
  );

  final spans = <TextSpan>[];
  int lastIndex = 0;

  // Step 3: Iterate through matches
  for (final match in regex.allMatches(cleaned)) {
    if (match.start > lastIndex) {
      spans.add(TextSpan(text: cleaned.substring(lastIndex, match.start)));
    }

    final matchText = match.group(0)!;

    // **bold**
    if (matchText.startsWith('**')) {
      spans.add(TextSpan(
        text: matchText.replaceAll('**', ''),
        style: baseStyle?.copyWith(fontWeight: FontWeight.bold) ??
            const TextStyle(fontWeight: FontWeight.bold),
      ));
    }
    // *italic*
    else if (matchText.startsWith('*')) {
      spans.add(TextSpan(
        text: matchText.replaceAll('*', ''),
        style: baseStyle?.copyWith(fontStyle: FontStyle.italic) ??
            const TextStyle(fontStyle: FontStyle.italic),
      ));
    }
    // `code`
    else if (matchText.startsWith('`')) {
      spans.add(TextSpan(
        text: matchText.replaceAll('`', ''),
        style: baseStyle?.copyWith(
              fontFamily: 'monospace',
              backgroundColor: Colors.black26,
            ) ??
            const TextStyle(
              fontFamily: 'monospace',
              backgroundColor: Colors.black26,
            ),
      ));
    }
    // [label](link)
    else if (match.group(5) != null && match.group(6) != null) {
      final label = match.group(5)!;
      final url = match.group(6)!;
      spans.add(_buildLinkSpan(label, url, baseStyle));
    }
    // Plain URL
    else if (matchText.startsWith('http')) {
      spans.add(_buildLinkSpan(matchText, matchText, baseStyle));
    }

    lastIndex = match.end;
  }

  // Add remaining plain text
  if (lastIndex < cleaned.length) {
    spans.add(TextSpan(text: cleaned.substring(lastIndex)));
  }

  // Step 4: Build RichText output
  final widgets = <Widget>[];
  widgets.add(RichText(
    text: TextSpan(
      style: baseStyle ?? const TextStyle(color: Colors.white, fontSize: 16),
      children: spans,
    ),
  ));

// Detect URLs and add previews
  /* final urlMatches = RegExp(r'https?:\/\/[^\s]+').allMatches(text);
  for (final match in urlMatches) {
    final url = match.group(0)!;
    widgets.add(LinkPreviewCard(url: url));
  }  */

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: widgets,
  );
}

// Helper to build clickable link span
TextSpan _buildLinkSpan(String label, String url, TextStyle? baseStyle) {
  final externalDomains = [
    'youtube.com',
    'youtu.be',
    'spotify.com',
    'open.spotify.com',
    'imdb.com',
    'netflix.com',
    'jiosaavn.com',
    'soundcloud.com',
    'gaana.com',
    'wynk.in',
  ];

  final shouldOpenExternally =
      externalDomains.any((domain) => url.contains(domain));

  return TextSpan(
    text: label,
    style: baseStyle?.copyWith(
          color: Colors.lightBlueAccent,
          decoration: TextDecoration.underline,
        ) ??
        const TextStyle(
          color: Colors.lightBlueAccent,
          decoration: TextDecoration.underline,
        ),
    recognizer: TapGestureRecognizer()
      ..onTap = () async {
        try {
          if (kIsWeb || shouldOpenExternally) {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          } else {
            final ctx = navigatorKey.currentContext;
            if (ctx == null) return;
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => WebViewScreen(url: url, title: "Apna AI"),
              ),
            );
          }
        } catch (e) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
  );
}
