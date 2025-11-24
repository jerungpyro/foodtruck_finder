import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MapScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isSearching;
  final VoidCallback onSearchPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onFilterPressed;
  final VoidCallback onMapStylePressed;
  final VoidCallback onExitSearch;
  final TextEditingController searchController;
  final String? activeFilterDisplay;
  final VoidCallback? onClearActiveFilter;

  const MapScreenAppBar({
    super.key,
    required this.title,
    required this.isSearching,
    required this.onSearchPressed,
    required this.onProfilePressed,
    required this.onFilterPressed,
    required this.onMapStylePressed,
    required this.onExitSearch,
    required this.searchController,
    this.activeFilterDisplay,
    this.onClearActiveFilter,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (isSearching) {
      return AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: onExitSearch,
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'Search by name or type...',
              hintStyle: TextStyle(color: Colors.white70, fontSize: 16),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.white70, size: 22),
            ),
          ),
        ),
        actions: [
          if (searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => searchController.clear(),
            ),
        ],
      );
    }
    
    // Normal AppBar with modern design
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: colorScheme.primary,
      elevation: 0,
      title: Row(
        children: [
          Icon(Icons.local_shipping_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          const Text(
            'FoodTruck',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        if (activeFilterDisplay != null && activeFilterDisplay!.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeFilterDisplay!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onClearActiveFilter,
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        IconButton(
          icon: const Icon(Icons.layers_rounded, color: Colors.white, size: 24),
          tooltip: 'Map Style',
          onPressed: onMapStylePressed,
        ),
        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            color: Colors.white,
            size: 24,
          ),
          tooltip: 'Filter',
          onPressed: onFilterPressed,
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
          tooltip: 'Search',
          onPressed: onSearchPressed,
        ),
        IconButton(
          icon: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          tooltip: 'Profile',
          onPressed: onProfilePressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}