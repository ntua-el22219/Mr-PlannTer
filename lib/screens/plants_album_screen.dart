import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/database_helper.dart';
import '../data/local_storage_service.dart';
import '../data/flower_colors.dart';
import '../widgets/cloudy_background.dart';
import '../theme/text_styles.dart';

class PlantsAlbumScreen extends StatefulWidget {
  const PlantsAlbumScreen({super.key});

  @override
  State<PlantsAlbumScreen> createState() => _PlantsAlbumScreenState();
}

class _PlantsAlbumScreenState extends State<PlantsAlbumScreen> {
  // Storage service for flower selection
  final LocalStorageService _storageService = LocalStorageService();
  String _selectedFlowerColor = 'PINK';

  @override
  void initState() {
    super.initState();
    _loadSelectedFlower();
  }

  Future<void> _loadSelectedFlower() async {
    setState(() {
      _selectedFlowerColor = _storageService.selectedFlowerColor;
    });
  }

  Future<void> _selectFlowerColor(String colorKey) async {
    await _storageService.setSelectedFlowerColor(colorKey);
    setState(() {
      _selectedFlowerColor = colorKey;
    });
    // Show confirmation with plant-specific message and color
    if (mounted) {
      final selectedFlower = FlowerColors.getByKey(colorKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selectedFlower.name} is very happy that you have selected it!',
            style: AppTextStyles.plantStyle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: selectedFlower.displayColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CloudyAnimatedBackground(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Close Button (X)
            Positioned(
              top: 80,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2.5),
                  ),
                  child: const Icon(Icons.close, size: 35, color: Colors.black),
                ),
              ),
            ),

            // Title
            Positioned(
              top: 140,
              child: Text(
                'Choose your Plant',
                style: AppTextStyles.titleInElement.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4D96FF),
                ),
              ),
            ),

            // Main Yellow Container
            Positioned(
              top: 200,
              bottom: 100,
              child: Container(
                width: 340,
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: _buildFlowerSelection(),
              ),
            ),

            // Done Button
            Positioned(
              bottom: 30,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4D96FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(
                      color: Colors.black,
                      width: 1.5,
                    ),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build flower selection grid
  Widget _buildFlowerSelection() {
    return ListView(
      children: [
        // Description text
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            'Pick a flower color to grow during your study sessions!',
            textAlign: TextAlign.center,
            style: AppTextStyles.mediumStyle.copyWith(
              fontSize: 14,
              color: const Color(0xFF5D4037),
            ),
          ),
        ),

        // Grid of flower options
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.85,
          ),
          itemCount: FlowerColors.all.length,
          itemBuilder: (context, index) {
            final flowerColor = FlowerColors.all[index];
            final isSelected = flowerColor.key == _selectedFlowerColor;

            return _buildFlowerItem(flowerColor, isSelected);
          },
        ),
      ],
    );
  }

  Widget _buildFlowerItem(FlowerColor flowerColor, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectFlowerColor(flowerColor.key),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isSelected
                    ? flowerColor.displayColor.withOpacity(0.2)
                    : Colors.white,
                border: Border.all(
                  color: isSelected ? flowerColor.displayColor : Colors.grey.shade500,
                  width: isSelected ? 3 : 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: flowerColor.displayColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.all(10),
              child: Stack(
                children: [
                  // Flower preview (Level 6)
                  Center(
                    child: SvgPicture.asset(
                      flowerColor.level6ImagePath,
                      fit: BoxFit.contain,
                      placeholderBuilder: (c) =>
                          const Icon(Icons.local_florist, color: Colors.grey),
                    ),
                  ),
                  // Selected checkmark
                  if (isSelected)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: flowerColor.displayColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Flower name
          Text(
            flowerColor.name,
            style: AppTextStyles.plantStyle.copyWith(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? flowerColor.displayColor : const Color(0xFF5D4037),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
