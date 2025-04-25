import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/mobile_case_controller.dart';
import '../../models/mobile_case_model.dart';
import '../../theme/color_theme.dart';
import '../../routes/app_routes.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

class CaseSearchDelegate extends SearchDelegate<MobileCaseModel?> {
  final MobileCaseController caseController = Get.find<MobileCaseController>();
  final RxList<MobileCaseModel> _localSearchResults = <MobileCaseModel>[].obs;
  final RxBool _isSearchingOnline = false.obs;
  final RxString _selectedFilter = 'All'.obs;
  final RxBool _showFilters = false.obs;
  Timer? _debounceTimer;
  
  // Debounce duration for search
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  TextStyle? get searchFieldStyle => const TextStyle(
    color: Colors.white,
    fontSize: 16,
  );

  // Available filter options
  final List<String> _filterOptions = ['All', 'Brand', 'Model', 'Price: Low to High', 'Price: High to Low'];

  // Custom cache manager for thumbnails
  static final customCacheManager = CacheManager(
    Config(
      'searchThumbnailCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'searchThumbnailCache'),
      fileService: HttpFileService(),
    ),
  );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorTheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
    );
  }

  @override
  String get searchFieldLabel => 'Search cases...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Iconsax.filter, color: Colors.white),
        onPressed: () {
          _showFilters.value = !_showFilters.value;
        },
      ),
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.white),
        onPressed: () {
          if (query.isEmpty) {
            close(context, null);
          } else {
            query = '';
            _localSearchResults.clear();
            _debounceTimer?.cancel();
          }
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
        color: Colors.white,
      ),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    _initiateSearch();
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyState();
    }
    _initiateSearch();
    return _buildSearchResults();
  }

  void _initiateSearch() {
    // Cancel any existing timer
    _debounceTimer?.cancel();
    
    // Start a new timer
    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    if (query.isEmpty) {
      _localSearchResults.clear();
      return;
    }

    try {
      // First search in local database
      final localResults = await _searchLocal();
      
      if (localResults.isNotEmpty) {
        _localSearchResults.assignAll(localResults);
        _applyFilter();
        return;
      }

      // If no local results, search online
      _isSearchingOnline.value = true;
      final onlineResults = await _searchOnline();
      
      if (onlineResults.isNotEmpty) {
        // Cache the results locally
        await _cacheResults(onlineResults);
        _localSearchResults.assignAll(onlineResults);
        _applyFilter();
      } else {
        _localSearchResults.clear();
      }
    } catch (e) {
      print('Search error: $e');
      Get.snackbar(
        'Error',
        'Failed to perform search',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorTheme.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      _isSearchingOnline.value = false;
    }
  }

  Future<List<MobileCaseModel>> _searchLocal() async {
    final searchQuery = query.toLowerCase();
    
    // Search in Hive box (local database)
    return caseController.cases.where((mobileCase) {
      final brand = mobileCase.brand.toLowerCase();
      final model = mobileCase.model.toLowerCase();
      final description = mobileCase.description?.toLowerCase() ?? '';
      
      return brand.contains(searchQuery) ||
             model.contains(searchQuery) ||
             description.contains(searchQuery) ||
             '$brand $model'.contains(searchQuery);
    }).toList();
  }

  Future<List<MobileCaseModel>> _searchOnline() async {
    try {
      return await caseController.searchCasesOnline(query);
    } catch (e) {
      print('Online search error: $e');
      return [];
    }
  }

  Future<void> _cacheResults(List<MobileCaseModel> results) async {
    try {
      await caseController.cacheSearchResults(results);
    } catch (e) {
      print('Caching error: $e');
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Iconsax.search_normal_1,
            size: 64,
            color: ColorTheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Start typing to search for cases',
            style: TextStyle(
              fontSize: 16,
              color: ColorTheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Obx(() {
      return Column(
        children: [
          if (_showFilters.value)
            _buildFilterOptions(),
          Expanded(
            child: _isSearchingOnline.value
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: ColorTheme.primary),
                        SizedBox(height: 16),
                        Text('Searching online...'),
                      ],
                    ),
                  )
                : _localSearchResults.isEmpty
                    ? _buildEmptyResults()
                    : _buildResultsList(),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Iconsax.search_status,
            size: 64,
            color: ColorTheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found for "$query"',
            style: TextStyle(
              fontSize: 16,
              color: ColorTheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try using different keywords',
            style: TextStyle(
              fontSize: 14,
              color: ColorTheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ColorTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() => ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter.value == filter;
          
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            selectedColor: ColorTheme.primary.withOpacity(0.2),
            labelStyle: TextStyle(
              color: isSelected ? ColorTheme.primary : ColorTheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (selected) {
              if (selected) {
                _selectedFilter.value = filter;
                _applyFilter();
              }
            },
          );
        },
      )),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _localSearchResults.length,
      itemBuilder: (context, index) {
        final mobileCase = _localSearchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: ColorTheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              close(context, null); // Close search first
              Get.toNamed(
                AppRoutes.caseDetails,
                arguments: mobileCase,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Image
                  _buildCaseImage(mobileCase),
                  const SizedBox(width: 12),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand & Model
                        Text(
                          '${mobileCase.brand} ${mobileCase.model}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: ColorTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Price
                        Text(
                          '\$${mobileCase.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: ColorTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        
                        // Quantity
                        Row(
                          children: [
                            const Icon(
                              Iconsax.box,
                              size: 14,
                              color: ColorTheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${mobileCase.quantity} units',
                              style: TextStyle(
                                fontSize: 13,
                                color: ColorTheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Chevron
                  const Icon(
                    Iconsax.arrow_right_3,
                    color: ColorTheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getBrandLogoPath(String brand) {
    // Convert brand name to lowercase and remove spaces for asset path
    final formattedBrand = brand.toLowerCase().replaceAll(' ', '_');
    return 'assets/images/$formattedBrand.png';
  }

  Widget _buildCaseImage(MobileCaseModel mobileCase) {
    // If no imageUrl, directly show brand logo
    if (mobileCase.imageUrl == null || mobileCase.imageUrl!.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _buildBrandLogo(mobileCase.brand),
      );
    }

    // If there is an imageUrl, try to load it with fallback to brand logo
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Hero(
        tag: 'case_image_${mobileCase.id}',
        child: CachedNetworkImage(
          imageUrl: mobileCase.imageUrl!,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          cacheManager: customCacheManager,
          placeholder: (context, url) => _buildShimmerEffect(),
          errorWidget: (context, url, error) => _buildBrandLogo(mobileCase.brand),
        ),
      ),
    );
  }

  Widget _buildBrandLogo(String brand) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: ColorTheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Image.asset(
          _getBrandLogoPath(brand),
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // If brand logo fails to load, show brand initial
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ColorTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  brand[0].toUpperCase(),
                  style: const TextStyle(
                    color: ColorTheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: ColorTheme.surfaceVariant.withOpacity(0.4),
      highlightColor: ColorTheme.surfaceVariant.withOpacity(0.2),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _applyFilter() {
    if (_selectedFilter.value == 'All' || _localSearchResults.isEmpty) {
      return; // No filter needed
    }

    List<MobileCaseModel> filteredResults = List.from(_localSearchResults);

    switch (_selectedFilter.value) {
      case 'Brand':
        filteredResults.sort((a, b) => a.brand.compareTo(b.brand));
        break;
      case 'Model':
        filteredResults.sort((a, b) => a.model.compareTo(b.model));
        break;
      case 'Price: Low to High':
        filteredResults.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        filteredResults.sort((a, b) => b.price.compareTo(a.price));
        break;
    }

    _localSearchResults.assignAll(filteredResults);
  }
} 