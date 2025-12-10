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
          if (activeFilterDisplay == null || activeFilterDisplay!.isEmpty) ...[
            Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text(
              'FoodTruck',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
          if (activeFilterDisplay != null && activeFilterDisplay!.isNotEmpty)
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      color: colorScheme.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        activeFilterDisplay!,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onClearActiveFilter,
                      child: Icon(
                        Icons.close,
                        color: colorScheme.primary,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.layers_outlined, color: Colors.white),
          iconSize: 21,
          tooltip: 'Map Style',
          onPressed: onMapStylePressed,
          padding: const EdgeInsets.all(6),
          splashRadius: 20,
        ),
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.white),
          iconSize: 21,
          tooltip: 'Filter',
          onPressed: onFilterPressed,
          padding: const EdgeInsets.all(6),
          splashRadius: 20,
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          iconSize: 21,
          tooltip: 'Search',
          onPressed: onSearchPressed,
          padding: const EdgeInsets.all(6),
          splashRadius: 20,
        ),
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          iconSize: 21,
          tooltip: 'Profile',
          onPressed: onProfilePressed,
          padding: const EdgeInsets.all(6),
          splashRadius: 20,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}