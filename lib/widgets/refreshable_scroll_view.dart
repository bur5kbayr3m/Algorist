import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RefreshableScrollView extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final ScrollPhysics physics;
  final EdgeInsets padding;

  const RefreshableScrollView({
    super.key,
    required this.onRefresh,
    required this.child,
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.padding = const EdgeInsets.all(0),
  });

  @override
  State<RefreshableScrollView> createState() => _RefreshableScrollViewState();
}

class _RefreshableScrollViewState extends State<RefreshableScrollView> {

  DateTime _lastRefresh = DateTime.now();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleRefresh() async {
    // Rate limiting: her 2 saniyede bir refresh yapılabilir
    final now = DateTime.now();
    if (now.difference(_lastRefresh).inSeconds < 2) {
      return;
    }

    setState(() => _isRefreshing = true);
    _lastRefresh = now;

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      backgroundColor: const Color(0xFF1E293B),
      color: AppColors.primary,
      strokeWidth: 2,
      child: Opacity(
        opacity: _isRefreshing ? 0.8 : 1.0,
        child: widget.child,
      ),
    );
  }
}
