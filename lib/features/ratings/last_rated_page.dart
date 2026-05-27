import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../controllers/rating_controller.dart';
import 'rating_detail_page.dart';

/// Page showing the ships with the most recent ratings in the app.
class LastRatedPage extends StatefulWidget {
  const LastRatedPage({super.key});

  @override
  State<LastRatedPage> createState() => _LastRatedPageState();
}

class _LastRatedPageState extends State<LastRatedPage> {
  static const _bgTop = Color(0xFF0A1628);
  static const _bgBottom = Color(0xFF0D2137);
  static const _accentBlue = Color(0xFF64B5F6);
  static const _accentTeal = Color(0xFF26A69A);
  static const _cardBg = Color(0x0DFFFFFF);
  static const _cardBorder = Color(0x1A64B5F6);
  static const _mutedText = Color(0x99FFFFFF);
  static const _bodyText = Color(0xD9FFFFFF);

  final RatingController _controller = RatingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<LastRatedShipItem> _items = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _loadItems();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadItems({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _controller.loadLastRatedShips(forceRefresh: forceRefresh);
      await _loadLikeStates(items);

      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLikeStates(List<LastRatedShipItem> items) async {
    final groupedIds = <String, List<String>>{};
    for (final item in items) {
      groupedIds.putIfAbsent(item.shipId, () => <String>[]).add(item.ratingId);
    }

    await Future.wait(
      groupedIds.entries.map((entry) {
        return _controller.loadRatingLikeStates(
          entry.key,
          entry.value,
          notify: false,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgTop, _bgBottom],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.lastRatedShipsTitle),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentBlue),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _bodyText, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadItems(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentBlue.withValues(alpha: 0.15),
                  foregroundColor: _accentBlue,
                ),
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.noRecentRatings,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _mutedText, fontSize: 14),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadItems(forceRefresh: true),
      color: _accentBlue,
      backgroundColor: _bgBottom,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) => _buildRatingCard(_items[index], l10n),
      ),
    );
  }

  Widget _buildRatingCard(LastRatedShipItem item, AppLocalizations l10n) {
    final shipName =
        item.shipName.isNotEmpty ? item.shipName : l10n.defaultShipName;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwnRating = item.userId.isNotEmpty && item.userId == currentUid;
    final liked = _controller.hasUserLikedRating(item.shipId, item.ratingId);
    final likeCount = _controller.getRatingLikeCount(item.shipId, item.ratingId);
    final likerNames = _controller.getRatingLikerNames(item.shipId, item.ratingId);
    final likedByText = _formatLikedByText(likerNames, likeCount, l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetail(item),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accentBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_boat,
                        color: _accentBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shipName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.ratedBy.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.pilotCallSign(item.ratedBy),
                              style: const TextStyle(
                                color: _accentTeal,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildScoreBadge(item.averageScore),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: _mutedText,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _controller.formatDate(item.date),
                      style: const TextStyle(
                        color: _mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      color: _mutedText,
                      size: 20,
                    ),
                  ],
                ),
                if (!isOwnRating) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: _cardBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _controller.toggleRatingLike(item.shipId, item.ratingId);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                  size: 18,
                                  color: liked ? _accentTeal : _mutedText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$likeCount',
                                  style: const TextStyle(
                                    color: _mutedText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (likedByText.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () => _showLikersSheet(item.shipId, item.ratingId, l10n),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  likedByText,
                                  style: const TextStyle(
                                    color: _mutedText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
          const SizedBox(width: 4),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              color: Color(0xFFFFC107),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLikedByText(
    List<String> names,
    int totalCount,
    AppLocalizations l10n,
  ) {
    if (names.isEmpty || totalCount <= 0) return '';

    final visibleNames = names
        .where((name) => name.trim().isNotEmpty)
        .take(2)
        .toList();
    if (visibleNames.isEmpty) return '';

    if (totalCount == 1 || visibleNames.length == 1) {
      final remaining = totalCount - 1;
      if (remaining > 0) {
        return l10n.likedBy('${visibleNames.first} ${l10n.andMore(remaining)}');
      }
      return l10n.likedBy(visibleNames.first);
    }

    if (totalCount == 2) {
      return l10n.likedBy(
        '${visibleNames.first} ${l10n.andWord} ${visibleNames.last}',
      );
    }

    return l10n.likedBy(
      '${visibleNames.first}, ${visibleNames.last} ${l10n.andMore(totalCount - 2)}',
    );
  }

  void _openDetail(LastRatedShipItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RatingDetailPage(rating: item.rating),
      ),
    );
  }

  Future<void> _showLikersSheet(
    String shipId,
    String ratingId,
    AppLocalizations l10n,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF132D4A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: FutureBuilder<List<String>>(
              future: _controller.fetchAllRatingLikerNames(shipId, ratingId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(color: _accentTeal),
                    ),
                  );
                }

                final names = snapshot.data ?? const <String>[];
                if (names.isEmpty) {
                  return SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        l10n.noRecords,
                        style: const TextStyle(
                          color: _mutedText,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _accentBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.likedBy('').trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: names.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: _cardBorder,
                            height: 1,
                          ),
                          itemBuilder: (_, index) {
                            final name = names[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: const Icon(
                                Icons.thumb_up,
                                color: _accentTeal,
                                size: 18,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  color: _bodyText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
