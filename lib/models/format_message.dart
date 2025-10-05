import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../screens/webview_screen.dart';

/// Formats text with markdown (**bold**, *italic*, `code`)
/// Detects clickable links (https:// or www.)
/// Cleans redundant symbols (#, ****)
/// Automatically shortens long displayed URLs.
Widget formatMessageText(String text, {TextStyle? baseStyle}) {
  // Step 1: Clean redundant symbols
  String cleaned = text.replaceAll(RegExp(r'[#+]+'), '').trim();

  // Step 2: Regex for markdown + URLs
  final regex = RegExp(
    r'(\*\*[^*]+\*\*)|(\*[^*]+\*)|(`[^`]+`)|((?:https?:\/\/|www\.)[^\s]+)',
    dotAll: true,
  );

  final spans = <TextSpan>[];
  int lastIndex = 0;

  // Step 3: Parse text
  for (final match in regex.allMatches(cleaned)) {
    if (match.start > lastIndex) {
      spans.add(TextSpan(text: cleaned.substring(lastIndex, match.start)));
    }

    final matchText = match.group(0)!;

    if (matchText.startsWith('**')) {
      spans.add(TextSpan(
        text: matchText.replaceAll('**', ''),
        style: baseStyle?.copyWith(fontWeight: FontWeight.bold) ??
            const TextStyle(fontWeight: FontWeight.bold),
      ));
    } else if (matchText.startsWith('*')) {
      spans.add(TextSpan(
        text: matchText.replaceAll('*', ''),
        style: baseStyle?.copyWith(fontStyle: FontStyle.italic) ??
            const TextStyle(fontStyle: FontStyle.italic),
      ));
    } else if (matchText.startsWith('`')) {
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
    } else if (matchText.startsWith('http') || matchText.startsWith('www.')) {
      String url = matchText.trim();
      if (url.startsWith('www.')) url = 'https://$url';

      // Shorten URL for display
      String displayUrl = Uri.tryParse(url)?.host ?? url;
      String? path = Uri.tryParse(url)?.path;
      if (path != null && path.isNotEmpty) {
        displayUrl += path.length > 20 ? '${path.substring(0, 20)}...' : path;
      }

      spans.add(
        TextSpan(
          text: displayUrl,
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
              final ctx = navigatorKey.currentContext;
              if (ctx == null) return;

              try {
                // Try to open inside WebView
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => WebViewScreen(url: url, title: "Apna AI"),
                  ),
                );
              } catch (e) {
                // If WebView fails (e.g. site blocks embedding), open externally
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                } else {
                  debugPrint("❌ Could not open URL: $url");
                  debugPrint(e.toString());
                }
              }
            },
        ),
      );
    }

    lastIndex = match.end;
  }

  if (lastIndex < cleaned.length) {
    spans.add(TextSpan(text: cleaned.substring(lastIndex)));
  }

  return RichText(
    text: TextSpan(
      style: baseStyle ?? const TextStyle(color: Colors.white, fontSize: 16),
      children: spans,
    ),
  );
}
