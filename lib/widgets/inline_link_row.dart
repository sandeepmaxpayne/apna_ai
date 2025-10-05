import 'package:flutter/material.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:url_launcher/url_launcher.dart';

class InlineLinkRow extends StatefulWidget {
  final List<String> urls;
  const InlineLinkRow({super.key, required this.urls});

  @override
  State<InlineLinkRow> createState() => _InlineLinkRowState();
}

class _InlineLinkRowState extends State<InlineLinkRow> {
  final List<_LinkMeta> _links = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    final unique = <String, String>{};

    // Group by domain and limit to 1 per domain
    for (final url in widget.urls) {
      final domain = Uri.tryParse(url)?.host ?? url;
      if (!unique.containsKey(domain)) {
        unique[domain] = url;
      }
    }

    final futures = unique.values.map((url) async {
      try {
        final data = await MetadataFetch.extract(url);
        return _LinkMeta(url, data);
      } catch (_) {
        return _LinkMeta(url, null);
      }
    });

    final result = await Future.wait(futures);
    if (mounted) {
      setState(() {
        _links.addAll(result);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _links.map((meta) => _buildCard(meta)).toList(),
        ),
      ),
    );
  }

  Widget _buildCard(_LinkMeta meta) {
    final data = meta.metadata;
    final bg = data?.image ?? '';
    final host = Uri.tryParse(meta.url)?.host ?? '';

    // 🎨 Color accent by source
    final accent = _getAccentForHost(host);

    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(meta.url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        height: 120,
        width: 120,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.3), width: 1),
          color: Colors.white.withOpacity(0.04),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bg.isNotEmpty)
              Image.network(
                bg,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.25),
                colorBlendMode: BlendMode.darken,
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.7), Colors.transparent],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _getShortTitle(data?.title ?? host),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌈 Accent color per platform
  Color _getAccentForHost(String host) {
    if (host.contains('spotify')) return const Color(0xFF1DB954);
    if (host.contains('youtube')) return const Color(0xFFFF0000);
    if (host.contains('imdb')) return const Color(0xFFF5C518);
    if (host.contains('jiosaavn') || host.contains('saavn'))
      return const Color(0xFF00BFA5);
    return Colors.blueAccent;
  }

  String _getShortTitle(String title) {
    return title.length > 30 ? '${title.substring(0, 27)}...' : title;
  }
}

class _LinkMeta {
  final String url;
  final Metadata? metadata;
  _LinkMeta(this.url, this.metadata);
}
