import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// Uber-style searchable picker for a fixed list of options (e.g. nationality /
/// country). Presents the same tappable field + bottom-sheet-with-search
/// experience as [KafiLocationPicker], but for a curated string list rather
/// than a geocoded place — so country/nationality selection feels identical to
/// picking a location.
class KafiSearchablePicker extends StatelessWidget {
  const KafiSearchablePicker({
    super.key,
    required this.value,
    required this.options,
    required this.onSelected,
    this.hint,
    this.title,
    this.icon = Icons.public,
    this.purple = false,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final String? hint;
  final String? title;
  final IconData icon;
  final bool purple;

  Future<void> _open(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchableSheet(
        options: options,
        title: title ?? hint ?? '',
        current: value,
        purple: purple,
      ),
    );
    if (selected != null && selected.trim().isNotEmpty) {
      onSelected(selected.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    final border = purple ? KafiColors.purB : KafiColors.cardBorder;
    final bg = purple ? KafiColors.inputBgP : KafiColors.inputBg;
    final accent = purple ? KafiColors.pur : KafiColors.roseD;
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: border, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: bg,
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                empty ? (hint ?? '') : value,
                style: KafiTheme.nunito(14,
                    color: empty ? KafiColors.ts : KafiColors.td),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: KafiColors.ts, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SearchableSheet extends StatefulWidget {
  const _SearchableSheet({
    required this.options,
    required this.title,
    required this.current,
    required this.purple,
  });

  final List<String> options;
  final String title;
  final String current;
  final bool purple;

  @override
  State<_SearchableSheet> createState() => _SearchableSheetState();
}

class _SearchableSheetState extends State<_SearchableSheet> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  late List<String> _filtered = widget.options;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.options
          : widget.options
              .where((o) => o.toLowerCase().contains(q))
              .toList();
    });
  }

  Color get _accent => widget.purple ? KafiColors.pur : KafiColors.roseD;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _handle(),
            _header(),
            _searchBar(),
            const Divider(height: 1),
            Expanded(child: _list(scrollCtrl)),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: KafiColors.ts.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title.isEmpty ? AppStrings.locationSearchHint.tr : widget.title,
                style: KafiTheme.fredoka(18, color: KafiColors.td),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: KafiColors.ts),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          decoration: BoxDecoration(
            color: KafiColors.inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: KafiColors.cardBorder),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.search, color: _accent, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _focusNode,
                  onChanged: _filter,
                  style: KafiTheme.nunito(14, color: KafiColors.td),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: AppStrings.locationSearchHint.tr,
                    hintStyle: KafiTheme.nunito(14, color: KafiColors.ts),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: KafiColors.ts, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _filter('');
                  },
                ),
            ],
          ),
        ),
      );

  Widget _list(ScrollController ctrl) {
    if (_filtered.isEmpty) {
      return ListView(
        controller: ctrl,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          Center(
            child: Text(
              AppStrings.locationSearchPrompt.tr,
              style: KafiTheme.fredoka(16, color: KafiColors.td),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      controller: ctrl,
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (_, i) {
        final o = _filtered[i];
        final selected = o == widget.current;
        return ListTile(
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected
                  ? (widget.purple ? KafiColors.purL : KafiColors.roseP)
                  : KafiColors.navyS,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              selected ? Icons.check_rounded : Icons.public,
              color: selected ? _accent : KafiColors.navy,
              size: 18,
            ),
          ),
          title: Text(o,
              style: KafiTheme.nunito(14,
                  color: selected ? _accent : KafiColors.td,
                  w: selected ? FontWeight.w800 : FontWeight.w600)),
          onTap: () => Navigator.pop(context, o),
        );
      },
    );
  }
}
