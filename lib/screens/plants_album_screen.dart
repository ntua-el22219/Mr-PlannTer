import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/database_helper.dart';
import '../widgets/cloudy_background.dart';
import '../theme/text_styles.dart';

class PlantsAlbumScreen extends StatefulWidget {
  const PlantsAlbumScreen({super.key});

  @override
  State<PlantsAlbumScreen> createState() => _PlantsAlbumScreenState();
}

class _PlantsAlbumScreenState extends State<PlantsAlbumScreen> {
  // Λίστα με τα φυτά που έχουν αποθηκευτεί
  List<Map<String, dynamic>> _completedPlants = [];
  bool _isLoading = true;
  
  // Page Controller για τις τελείες 
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadAlbum();
  }

  Future<void> _loadAlbum() async {
    final plants = await DatabaseHelper().getCompletedPlants();
    setState(() {
      _completedPlants = plants;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Υπολογισμός σελίδων (6 φυτά ανά σελίδα)
    final int itemsPerPage = 6;
    final int totalPages = (_completedPlants.isEmpty) 
        ? 1 
        : (_completedPlants.length / itemsPerPage).ceil();

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

            // Main Yellow Container
            Positioned(
              top: 150,
              bottom: 100,
              child: Container(
                width: 320, 
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F), 
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: _isLoading 
                          ? const Center(child: CircularProgressIndicator())
                          : PageView.builder(
                              controller: _pageController,
                              itemCount: totalPages,
                              onPageChanged: (page) {
                                setState(() {
                                  _currentPage = page;
                                });
                              },
                              itemBuilder: (context, pageIndex) {
                                // Υπολογισμός ποια φυτά ανήκουν σε αυτή τη σελίδα
                                final startIndex = pageIndex * itemsPerPage;
                                final endIndex = (startIndex + itemsPerPage < _completedPlants.length) 
                                    ? startIndex + itemsPerPage 
                                    : _completedPlants.length;
                                
                                final pagePlants = _completedPlants.sublist(
                                  startIndex < _completedPlants.length ? startIndex : 0, 
                                  endIndex > startIndex ? endIndex : startIndex
                                );

                                return _buildGridPage(pagePlants, itemsPerPage);
                              },
                            ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Pagination Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalPages, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index 
                                ? const Color(0xFF8D6E63) 
                                : Colors.grey.shade600, 
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Grid Builder 
  Widget _buildGridPage(List<Map<String, dynamic>> plants, int totalSlots) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // Απενεργοποίηση scroll μέσα στο page view
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 Στήλες
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.85, 
      ),
      itemCount: totalSlots, // Πάντα σχεδιάζουμε 6 κουτιά 
      itemBuilder: (context, index) {
        if (index < plants.length) {
          // Έχουμε φυτό
          final plant = plants[index];
          return _buildPlantItem(plant['plant_name'], plant['plant_image_path']);
        } else {
          // Κενό κουτί (Placeholder)
          return _buildEmptyItem();
        }
      },
    );
  }

  Widget _buildPlantItem(String name, String imagePath) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              border: Border.all(color: Colors.grey.shade500),
            ),
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(
              imagePath, 
              fit: BoxFit.contain,
              // Fallback αν δεν υπάρχει εικόνα στη βάση
              placeholderBuilder: (c) => const Icon(Icons.local_florist, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 5),
        // Name Label
        Text(
          name, 
          style: AppTextStyles.plantStyle.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyItem() {
    return Column(
      children: [
        // Empty Gray Box with diagonal line (Visual fake)
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              border: Border.all(color: Colors.grey.shade500),
            ),
            child: CustomPaint(
              painter: DiagonalLinePainter(),
              child: Center(
                child: Text('Empty', style: AppTextStyles.caption.copyWith(color: Colors.grey, fontSize: 10)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        // Empty Name Line
        Container(width: 50, height: 2, color: Colors.transparent),
      ],
    );
  }
}

// Custom Painter για τη διαγώνια γραμμή στα κενά κουτιά 
class DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade500
      ..strokeWidth = 1;
    
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}