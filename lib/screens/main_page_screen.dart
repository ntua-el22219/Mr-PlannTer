import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


import 'settings_screen.dart';
import 'plants_album_screen.dart';
import 'timer_wrapper_screen.dart';
import '../widgets/cloudy_background.dart';
import '../widgets/mr_watering_can.dart';

class MainPageScreen extends StatefulWidget {
  const MainPageScreen({super.key});

  @override
  State<MainPageScreen> createState() => _MainPageScreenState();
}

class _MainPageScreenState extends State<MainPageScreen> with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late Animation<Alignment> _cloudAnimation;
  late AnimationController _wateringCanAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  // PATHS ASSETS
  final String _plantImagePath = 'assets/images/plant_level6.svg';
  final String _albumImagePath = 'assets/images/plants_calendar_album.svg';
  final String _potImagePath = 'assets/images/happy_pot.svg';
  final String _grassImagePath = 'assets/images/grass.svg';

  @override
  void initState() {
    super.initState();

    //  Animation για τα σύννεφα στο background
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat(reverse: true);

    _cloudAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(CurvedAnimation(parent: _cloudController, curve: Curves.linear));

    //  Animation για το watering can - σταδιακή μεγέθυνση και φωτισμός
    _wateringCanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6), // Πλήρης κύκλος: μεγάλωμα + παραμονή + μικραίνω
    )..repeat();

    // Scale animation: 1.0 -> 1.15 -> 1.15 (stay) -> 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30, // 30% του χρόνου για μεγάλωμα
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.15),
        weight: 40, // 40% του χρόνου για παραμονή
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30, // 30% του χρόνου για μικραίνω
      ),
    ]).animate(_wateringCanAnimationController);

    // Glow animation: 0.0 -> 0.8 -> 0.8 (stay) -> 0.0
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.8).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.8),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_wateringCanAnimationController);
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _wateringCanAnimationController.dispose();
    super.dispose();
  }

  void _onWateringCanTapped(BuildContext context) {
    // Το πάτημα στο ποτιστήρι ανοίγει το Timer Setup
    Navigator.push(context, MaterialPageRoute(builder: (c) => const TimerWrapperScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      // Συνδυάζουμε τα animations για να ανανεώνεται το UI
      animation: Listenable.merge([_cloudAnimation, _wateringCanAnimationController]),
      builder: (context, child) {
        return Scaffold(
          body: CloudyBackground(
            drift: _cloudAnimation.value,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Scale factor για responsive layout βασισμένο στο Figma (412x917)
                final double scale = (constraints.maxHeight / 917.0).clamp(0.7, 1.4);
                
                // Ακριβείς διαστάσεις από Figma (node 190:4709)
                final double plantHeight = 400 * scale; // Μεγαλύτερο φυτό
                final double plantWidth = 173 * scale;
                final double potHeight = 289 * scale;
                final double potWidth = 173 * scale;
                final double wateringHeight = 227 * scale;
                final double wateringWidth = 233 * scale;
                final double grassHeight = 141 * scale;
                
                // Ακριβείς θέσεις από Figma
                final double potLeft = 6 * scale;
                final double potBottom = 70 * scale;
                
                // Φυτό: Κεντραρισμένο πάνω στη γλάστρα - left: 6px, bottom: 198px
                final double plantLeft = 6 * scale;
                final double plantBottom = 192 * scale;
                
                final double wateringBottom = 70 * scale;
                final double wateringRight = -10 * scale; // Ελάχιστα πιο αριστερά
                final double settingsLeft = 10 * scale;
                final double settingsTop = 17 * scale;
                
                // Album: Αγκιστρωμένο στη δεξιά πλευρά (412 - 266 - 121.5 = 24.5px from right)
                final double albumRight = 24.5 * scale;
                final double albumTop = 23 * scale;

                return Stack(
                  children: [
                    // Settings Icon (Figma: left: 10px, top: 17px, size: 72px)
                    Positioned(
                      top: settingsTop,
                      left: settingsLeft,
                      child: IconButton(
                        icon: Icon(Icons.settings, size: 72 * scale, color: Colors.black),
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()));
                        },
                      ),
                    ),

                    // Album Icon (αγκιστρωμένο στη δεξιά πλευρά: right: 24.5px, top: 23px)
                    Positioned(
                      top: albumTop,
                      right: albumRight,
                      child: GestureDetector(
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (c) => const PlantsAlbumScreen()));
                        },
                        child: SvgPicture.asset(
                          _albumImagePath,
                          height: 97.5 * scale,
                          width: 121.5 * scale,
                          errorBuilder: (c, e, s) => const Icon(Icons.book, size: 40, color: Colors.brown),
                        ),
                      ),
                    ),

                    // Γρασίδι (Figma: bottom: 0, κάτω κάτω της οθόνης)
                    Positioned(
                      bottom: -5 * scale,
                      left: 0,
                      right: 0,
                      child: SvgPicture.asset(
                        _grassImagePath,
                        height: grassHeight,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Γλάστρα (Figma: left: 6px, bottom: 70px)
                    Positioned(
                      left: potLeft,
                      bottom: potBottom,
                      child: SvgPicture.asset(
                        _potImagePath,
                        height: potHeight,
                        width: potWidth,
                      ),
                    ),

                    // Φυτό (κεντραρισμένο πάνω στη γλάστρα: left: 6px, bottom: 196.24px)
                    Positioned(
                      left: plantLeft,
                      bottom: plantBottom,
                      child: SvgPicture.asset(
                        _plantImagePath,
                        height: plantHeight,
                        width: plantWidth,
                      ),
                    ),

                    // Ποτιστήρι με σταδιακό animation (μεγάλωμα + φωτισμός)
                    Positioned(
                      right: wateringRight,
                      bottom: wateringBottom,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        alignment: Alignment.centerRight, // Μεγαλώνει από τη δεξιά πλευρά
                        child: Container(
                          decoration: _glowAnimation.value > 0.01
                              ? BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(_glowAnimation.value),
                                      blurRadius: 34.5,
                                      spreadRadius: 3,
                                      offset: const Offset(-12, 17),
                                    ),
                                  ],
                                )
                              : null,
                          child: MrWateringCan(
                            variant: WateringCanVariant.defaultMode, // Πάντα default
                            width: wateringWidth,
                            height: wateringHeight,
                            onTap: () => _onWateringCanTapped(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}