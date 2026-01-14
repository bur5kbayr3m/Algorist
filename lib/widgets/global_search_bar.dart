import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class GlobalSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String hintText;
  final VoidCallback? onClear;

  const GlobalSearchBar({
    super.key,
    required this.onSearch,
    this.hintText = 'Ara...',
    this.onClear,
  });

  @override
  State<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends State<GlobalSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear?.call();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onSearch,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white54,
            size: 20,
          ),
          suffixIcon: _hasText
              ? GestureDetector(
                  onTap: _clearSearch,
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class SearchHistory {


  static Future<List<String>> getHistory() async {
    // TODO: SharedPreferences implementation
    return [];
  }

  static Future<void> addToHistory(String query) async {
    // TODO: SharedPreferences implementation
  }

  static Future<void> clearHistory() async {
    // TODO: SharedPreferences implementation
  }
}
