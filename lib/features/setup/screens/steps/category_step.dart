import 'package:flutter/material.dart';

import '../../models/setup_options.dart';

class CategoryStep extends StatelessWidget {
  final Set<String> selectedGaps;
  final Set<String> selectedCategories;
  final String activeGapTitle;
  final String? rejectedCategory;
  final ValueChanged<String> onGapTapped;
  final ValueChanged<String> onCategoryTapped;
  final VoidCallback onRejectedCategoryCleared;

  const CategoryStep({
    super.key,
    required this.selectedGaps,
    required this.selectedCategories,
    required this.activeGapTitle,
    this.rejectedCategory,
    required this.onGapTapped,
    required this.onCategoryTapped,
    required this.onRejectedCategoryCleared,
  });

  Map<String, String>? get _activeGap {
    for (final gap in digitalGapOptions) {
      if (gap['title'] == activeGapTitle) {
        return gap;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'What do you sell?',
            style: TextStyle(
              color: Colors.black,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pick your specialization first. Scout AI will prioritize the right businesses and keep the definition below clear for whatever you tap.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          const _SectionLabel(title: 'SPECIALIZATION'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 14,
            children: digitalGapOptions.map((gap) {
              final title = gap['title']!;
              return _PillChip(
                label: title,
                isSelected: selectedGaps.contains(title),
                onTap: () => onGapTapped(title),
              );
            }).toList(),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
              );
            },
            child: _activeGap == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey(_activeGap!['title']),
                    padding: const EdgeInsets.only(top: 18),
                    child: _InfoPanel(
                      title: _activeGap!['title']!,
                      description: _activeGap!['description']!,
                    ),
                  ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel(title: 'CATEGORY'),
              if (rejectedCategory != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D38).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Max 6 selections',
                    style: TextStyle(
                      color: Color(0xFFFF4D38),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 14,
            children: scoutCategoryOptions.map((category) {
              final isRejected = rejectedCategory == category;
              return _PillChip(
                label: category,
                isSelected: selectedCategories.contains(category),
                isRejected: isRejected,
                onTap: () {
                  if (isRejected) {
                    onRejectedCategoryCleared();
                  }
                  onCategoryTapped(category);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF8B8B8B),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isRejected;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.isSelected,
    this.isRejected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: isRejected
              ? const Color(0xFFFF4D38)
              : isSelected
                  ? Colors.black
                  : const Color(0xFFF5F5F3),
          borderRadius: BorderRadius.circular(999),
          border: isRejected
              ? Border.all(color: const Color(0xFFFF4D38), width: 1.5)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isRejected || isSelected ? Colors.white : const Color(0xFF5E5E5E),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String title;
  final String description;

  const _InfoPanel({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F3),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF676767),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
