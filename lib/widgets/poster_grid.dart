import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/channel.dart';
import 'tv_focus_highlight.dart';

/// Wiederverwendbares Poster-Grid fuer Filme und Serien.
class PosterGrid extends StatelessWidget {
  final List<Channel> items;
  final void Function(Channel item) onTap;
  const PosterGrid({super.key, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return TvFocusHighlight(
          child: InkWell(
            autofocus: i == 0,
            onTap: () => onTap(item),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.logoUrl != null && item.logoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.logoUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget: (context, url, error) => const _PosterPlaceholder(),
                            placeholder: (context, url) => const _PosterPlaceholder(),
                          )
                        : const _PosterPlaceholder(),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.movie_outlined, size: 32, color: Colors.grey),
    );
  }
}
