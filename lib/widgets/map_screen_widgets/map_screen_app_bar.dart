import 'package:flutter/material.dart';

class MapScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isSearching;
  final VoidCallback onSearchPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onFilterPressed;
  final VoidCallback onMapStylePressed;
  // onReportTruckPressed is intentionally removed from here as it's now a FAB
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
    if (isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onExitSearch,
        ),
        title: TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by name or type...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              if (searchController.text.isEmpty) {
                onExitSearch();
              } else {
                searchController.clear();
              }
            },
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
      );
    } else {
      // Normal AppBar
      return AppBar(
        title: Row(
          children: [
            Expanded(child: Text(title)),
            if (activeFilterDisplay != null && activeFilterDisplay!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Chip(
                  label: Text(activeFilterDisplay!, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: onClearActiveFilter,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  labelPadding: const EdgeInsets.only(left: 6),
                  deleteIconColor: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              )
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Report Truck IconButton is NOT here anymore
          IconButton( 
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'Map Style',
            onPressed: onMapStylePressed,
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: activeFilterDisplay != null ? Theme.of(context).colorScheme.primary : null),
            tooltip: 'Filter',
            onPressed: onFilterPressed,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: onSearchPressed,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: onProfilePressed,
          ),
        ],
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}