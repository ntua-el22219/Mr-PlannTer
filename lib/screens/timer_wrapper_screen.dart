// ignore_for_file: unused_field, unused_element, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../data/database_helper.dart'; // Για αποθήκευση στο τέλος
import '../data/local_storage_service.dart';
import '../services/audio_service.dart';
import '../widgets/cloudy_background.dart';
import '../theme/text_styles.dart';

import 'settings_screen.dart';

// Καταστάσεις του Timer
enum TimerPhase { setup, studying, breaking }

class TimerWrapperScreen extends StatefulWidget {
  const TimerWrapperScreen({super.key});

  @override
  State<TimerWrapperScreen> createState() => _TimerWrapperScreenState();
}
class _PlantLayout {
  final double width;
  final double height;
  final double left;
  final double bottom;
  const _PlantLayout({required this.width, required this.height, required this.left, required this.bottom});
}

class _TimerWrapperScreenState extends State<TimerWrapperScreen> with TickerProviderStateMixin {
  // Individual digit controllers for studying time (MM:SS)
  final TextEditingController _studyMin1Controller = TextEditingController(text: '2');
  final TextEditingController _studyMin2Controller = TextEditingController(text: '5');
  final TextEditingController _studySec1Controller = TextEditingController(text: '0');
  final TextEditingController _studySec2Controller = TextEditingController(text: '0');
  
  // Individual digit controllers for break time (MM:SS)
  final TextEditingController _breakMin1Controller = TextEditingController(text: '0');
  final TextEditingController _breakMin2Controller = TextEditingController(text: '5');
  final TextEditingController _breakSec1Controller = TextEditingController(text: '0');
  final TextEditingController _breakSec2Controller = TextEditingController(text: '0');
  
  final TextEditingController _sessionsController = TextEditingController(text: '4');

  // Timer State 
  TimerPhase _phase = TimerPhase.setup;
  Timer? _timer;
  bool _isRunning = false;
  
  int _secondsRemaining = 0;
  int _totalSessions = 4;
  int _currentSession = 1;
  int _studyTimeMinutes = 25;
  int _breakTimeMinutes = 5;
  int _studyTimeTotalSeconds = 1500; // 25 * 60
  int _breakTimeTotalSeconds = 300; // 5 * 60
  
  // Button press states
  bool _isCancelPressed = false;
  bool _isPlayPressed = false;

  // Audio Service
  late AudioService _audioService;
  late LocalStorageService _storageService;

  // Gamification State 
  int _currentPlantState = 0; // 0 έως 6
  double _secondsPerGrowthStage = 0;
  int _totalStudyTimeElapsed = 0; // Συνολικός χρόνος διαβάσματος σε όλα τα sessions

  // Animation 
  late AnimationController _cloudController;
  late Animation<Alignment> _cloudAnimation;

  // Watering Can Animation
  late AnimationController _wateringCanScaleController;
  late Animation<double> _wateringCanScaleAnimation;
  late Animation<double> _wateringCanGlowAnimation;

  // Assets Paths 
  final List<String> _plantStages = [
    'assets/images/plant_level0.svg',
    'assets/images/plant_level1.svg',
    'assets/images/plant_level2.svg',
    'assets/images/plant_level3.svg',
    'assets/images/plant_level4.svg',
    'assets/images/plant_level5.svg',
    'assets/images/plant_level6.svg',
  ];
  final String _potPath = 'assets/images/happy_pot.svg';
  final String _grassPath = 'assets/images/grass.svg';
  

  final String _wateringModePath = 'assets/images/watering_mode.svg'; // Ποτιστήρι που ποτίζει (studying)
  final String _breakWateringPath = 'assets/images/break_tap_with_water.svg'; // Ποτιστήρι + Βρύση (break)
  final String _tapBeggingPath = 'assets/images/tap_begging.svg'; // Βρύση
  final String _wateringCanDefaultPath = 'assets/images/watering_can_default.svg'; // Ποτιστήρι default

  // Plant layout per level (Figma-based positions/dimensions)
  static const List<_PlantLayout> _plantLayouts = [
    // level 0
    _PlantLayout(width: 173, height: 180.76, left: 6, bottom: 199),
    // level 1
    _PlantLayout(width: 173, height: 180.76, left: 6, bottom: 199),
    // level 2
    _PlantLayout(width: 173, height: 273, left: 6, bottom: 199),
    // level 3
    _PlantLayout(width: 173, height: 380, left: 3, bottom: 198),
    // level 4
    _PlantLayout(width: 173, height: 385, left: 1.5, bottom: 198),
    // level 5
    _PlantLayout(width: 173, height: 390, left: 1.5, bottom: 198),
    // level 6 (fully grown)
    _PlantLayout(width: 173, height: 400, left: 6, bottom: 192),
  ];

  @override
  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _storageService = LocalStorageService();
    
    // Background Animation (ίδιο με Main Page)
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat(reverse: true);

    _cloudAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(CurvedAnimation(parent: _cloudController, curve: Curves.linear));

    // Watering Can Animation (same as Main Page)
    _wateringCanScaleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _wateringCanScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.15),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_wateringCanScaleController);

    _wateringCanGlowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.8).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.8),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_wateringCanScaleController);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cloudController.dispose();
    _wateringCanScaleController.dispose();
    _studyMin1Controller.dispose();
    _studyMin2Controller.dispose();
    _studySec1Controller.dispose();
    _studySec2Controller.dispose();
    _breakMin1Controller.dispose();
    _breakMin2Controller.dispose();
    _breakSec1Controller.dispose();
    _breakSec2Controller.dispose();
    _sessionsController.dispose();
    super.dispose();
  }

  // Logic 

  void _startTimerLogic() {
    // Διαβάζουμε τις τιμές από τα TextFields (Manual Input - individual digits)
    setState(() {
      // Combine individual digits for studying time
      final studyMin1 = int.tryParse(_studyMin1Controller.text) ?? 0;
      final studyMin2 = int.tryParse(_studyMin2Controller.text) ?? 0;
      final studySec1 = int.tryParse(_studySec1Controller.text) ?? 0;
      final studySec2 = int.tryParse(_studySec2Controller.text) ?? 0;
      _studyTimeMinutes = studyMin1 * 10 + studyMin2;
      final studyTimeSeconds = studySec1 * 10 + studySec2;
      _studyTimeTotalSeconds = (_studyTimeMinutes * 60) + studyTimeSeconds;
      
      // Combine individual digits for break time
      final breakMin1 = int.tryParse(_breakMin1Controller.text) ?? 0;
      final breakMin2 = int.tryParse(_breakMin2Controller.text) ?? 0;
      final breakSec1 = int.tryParse(_breakSec1Controller.text) ?? 0;
      final breakSec2 = int.tryParse(_breakSec2Controller.text) ?? 0;
      _breakTimeMinutes = breakMin1 * 10 + breakMin2;
      final breakTimeSeconds = breakSec1 * 10 + breakSec2;
      _breakTimeTotalSeconds = (_breakTimeMinutes * 60) + breakTimeSeconds;
      
      _totalSessions = int.tryParse(_sessionsController.text) ?? 4;
      
      // Αρχικοποίηση χρόνου (use total seconds)
      _secondsRemaining = _studyTimeTotalSeconds;
      _phase = TimerPhase.studying;
      _currentSession = 1;
      _isRunning = true;
      _currentPlantState = 0; // Ξεκινάμε από σπόρο
      _totalStudyTimeElapsed = 0; // Reset συνολικού χρόνου
      
      // Υπολογισμός ρυθμού ανάπτυξης βάσει ΣΥΝΟΛΙΚΟΥ χρόνου όλων των sessions
      final totalStudyTime = _totalSessions * _studyTimeTotalSeconds;
      _secondsPerGrowthStage = totalStudyTime / 6;
    });

    // Play study time start sound for first session
    if (_storageService.isSoundEffectsEnabled) {
      _audioService.playStudyTimeStart();
    }

    _startTicker();
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          
          // Λογική ανάπτυξης φυτού (μόνο στο Studying phase)
          if (_phase == TimerPhase.studying) {
            // Αύξηση συνολικού χρόνου διαβάσματος
            _totalStudyTimeElapsed++;
            
            // Calculate plant state based on TOTAL elapsed study time
            int stage = (_totalStudyTimeElapsed / _secondsPerGrowthStage).floor();
            _currentPlantState = stage.clamp(0, 6);
          }
        } else {
          _handlePhaseEnd();
        }
      });
    });
  }

  void _handlePhaseEnd() async {
    _timer?.cancel();
    
    // Check if sound effects are enabled
    final soundEffectsEnabled = _storageService.isSoundEffectsEnabled;
    
    // ΤΕΛΟΣ ΔΙΑΒΑΣΜΑΤΟΣ
    if (_phase == TimerPhase.studying) {
      
      // Αν υπάρχουν κι άλλα sessions 
      if (_currentSession < _totalSessions) {
        // Play break time start sound
        if (soundEffectsEnabled) {
          await _audioService.playBreakTimeStart();
        }
        
        setState(() {
          _phase = TimerPhase.breaking; // ΑΛΛΑΓΗ ΦΑΣΗΣ ΣΕ ΔΙΑΛΕΙΜΜΑ
          _secondsRemaining = _breakTimeTotalSeconds; // ΧΡΟΝΟΣ ΔΙΑΛΕΙΜΜΑΤΟΣ (με seconds)
        });
        _startTicker(); // Αυτόματη έναρξη του διαλείμματος
      } 
      // Αν ήταν το τελευταίο session
      else {
        // Play end of sessions sound
        if (soundEffectsEnabled) {
          await _audioService.playEndOfSessions();
        }
        
        // Προσπάθεια αποθήκευσης στη βάση (με error handling)
        try {
          final db = DatabaseHelper();
          await db.updatePlantState(6, _totalSessions * _studyTimeMinutes);
          
          // Αποθήκευση στο Album
          await db.addCompletedPlant(
              'assets/images/plant_level6.svg', 
              'Sunflower #${DateTime.now().day}/${DateTime.now().month}'
          );
        } catch (e) {
          print('Error saving to database: $e');
        }

        // Εμφάνιση dialog με ευχαριστίες
        if(mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  backgroundColor: const Color(0xFFFFD966),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mr plant is very happy\nthat you took care of him!',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading2.copyWith(
                            color: const Color(0xFF0C4587),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Κλείσε το dialog
                              // Επιστροφή στο home
                              if(mounted && Navigator.canPop(context)) {
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C4587),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              'OK',
                              style: AppTextStyles.heading2.copyWith(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
        }
      }
    } 
    // ΤΕΛΟΣ ΔΙΑΛΕΙΜΜΑΤΟΣ (BREAKING)
    else if (_phase == TimerPhase.breaking) {
      // Play study time start sound for next session
      if (soundEffectsEnabled) {
        await _audioService.playStudyTimeStart();
      }
      
      // Τέλος Διαλείμματος -> Πάμε στο επόμενο session διαβάσματος
      setState(() {
        _currentSession++; // Αυξάνουμε τον αριθμό του session
        _phase = TimerPhase.studying; // ΕΠΙΣΤΡΟΦΗ ΣΕ ΔΙΑΒΑΣΜΑ
        _secondsRemaining = _studyTimeTotalSeconds; // ΧΡΟΝΟΣ ΜΕΛΕΤΗΣ (με seconds)
        // ΔΕΝ κάνουμε reset το _currentPlantState - συνεχίζει να μεγαλώνει
      });
      _startTicker(); // Αυτόματη έναρξη
    }
  }

  void _togglePause() {
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
      } else {
        _startTicker();
      }
      _isRunning = !_isRunning;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _phase = TimerPhase.setup;
      _isRunning = false;
    });
  }

  // UI Helpers 
  String get _timerString {
    int min = _secondsRemaining ~/ 60;
    int sec = _secondsRemaining % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cloudAnimation,
      builder: (context, child) {
        return Scaffold(
          body: CloudyBackground(
            drift: _cloudAnimation.value,
            child: _phase == TimerPhase.setup 
                ? _buildSetupView() 
                : _buildActiveTimerView(),
          ),
        );
      }
    );
  }

  // VIEW 1: SETUP (Figma 53:206)
  Widget _buildSetupView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        // Calculate responsive positions - exact Figma dimensions
        final containerWidth = 270.0; // Exact Figma width
        final containerHeight = 415.0; // Exact Figma height
        final containerLeft = (screenWidth - containerWidth) / 2;
        final containerTop = (screenHeight - containerHeight) / 2; // Center vertically
        
        final cancelTop = containerTop - 130; // 130px above container
        final cancelLeft = (screenWidth - 87.1) / 2;
        
        final playTop = containerTop + containerHeight + 50; // 50px below container
        
        return Stack(
          children: [
            // Cancel X button (Figma assets: Default 87.1px / Variant2 93px when pressed)
            Positioned(
              top: cancelTop - (_isCancelPressed ? 2.95 : 0),
              left: cancelLeft - (_isCancelPressed ? 2.95 : 0),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isCancelPressed = true),
                onTapUp: (_) {
                  setState(() => _isCancelPressed = false);
                  Navigator.pop(context);
                },
                onTapCancel: () => setState(() => _isCancelPressed = false),
                child: Container(
                  width: _isCancelPressed ? 93 : 87.1,
                  height: _isCancelPressed ? 93 : 87.1,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isCancelPressed ? const Color(0xFF671A1A) : const Color(0xFF1D1B20),
                      width: 8,
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    color: _isCancelPressed ? const Color(0xFF671A1A) : const Color(0xFF1D1B20),
                    size: 45,
                  ),
                ),
              ),
            ),

            // Main yellow container (using studying_parameteres.svg)
            Positioned(
              top: containerTop,
              left: containerLeft,
              child: SizedBox(
                width: containerWidth,
                height: containerHeight,
                child: Stack(
                  children: [
                    // Background SVG
                    SvgPicture.asset(
                      'assets/images/studying parameters.svg',
                      width: containerWidth,
                      height: containerHeight,
                      fit: BoxFit.fill,
                    ),
                    
                    // Editable fields positioned over the SVG white boxes (Figma exact positions)
                    // Studying time - 4 individual boxes for M M : S S
                    // Timer inset: [16.39%, 10%, 69.4%, 10%] - top, right, bottom, left
                    // Box 1 (M1): inset [8.47%, 77.62%, 9.82%, 3.7%] within timer
                    _buildDigitBox(
                      containerWidth, containerHeight,
                      timerTop: 0.1639, timerLeft: 0.10, timerRight: 0.10, timerBottom: 0.694,
                      boxTop: 0.0847, boxLeft: 0.037, boxRight: 0.7762, boxBottom: 0.0982,
                      controller: _studyMin1Controller,
                    ),
                    // Box 2 (M2): inset [8.47%, 54.93%, 9.82%, 26.39%]
                    _buildDigitBox(
                      containerWidth, containerHeight,
                      timerTop: 0.1639, timerLeft: 0.10, timerRight: 0.10, timerBottom: 0.694,
                      boxTop: 0.0847, boxLeft: 0.2639, boxRight: 0.5493, boxBottom: 0.0982,
                      controller: _studyMin2Controller,
                    ),
                    // Box 3 (S1): inset [8.47%, 27.16%, 9.82%, 54.17%]
                    _buildDigitBox(
                      containerWidth, containerHeight,
                      timerTop: 0.1639, timerLeft: 0.10, timerRight: 0.10, timerBottom: 0.694,
                      boxTop: 0.0847, boxLeft: 0.5417, boxRight: 0.2716, boxBottom: 0.0982,
                      controller: _studySec1Controller,
                    ),
                    // Box 4 (S2): inset [8.47%, 4.47%, 9.82%, 76.85%]
                    _buildDigitBox(
                      containerWidth, containerHeight,
                      timerTop: 0.1639, timerLeft: 0.10, timerRight: 0.10, timerBottom: 0.694,
                      boxTop: 0.0847, boxLeft: 0.7685, boxRight: 0.0447, boxBottom: 0.0982,
                      controller: _studySec2Controller,
                    ),
                    
                    // Break time - 4 individual boxes for M M : S S
                    // Timer inset: [50.12%, 10%, 35.66%, 10%]
                    _buildDigitBox(
                      containerWidth, containerHeight,
                      timerTop: 0.5012, timerLeft: 0.10, timerRight: 0.10, timerBottom: 0.3566,
                      boxTop: 0.0847, boxLeft: 0.037, boxRight: 0.7762, boxBottom: 0.0982,
                      controller: _breakMin1Controller,
                    ),
                    _buildDigitBox(
                      containerWidth, containerHeight,
                      timerTop: 0.5012, timerLeft: 0.10, timerRight: 0.10, timerBottom: 0.3566,
                      boxTop: 0.0847, boxLeft: 0.2639, boxRight: 0.5493, boxBottom: 0.0982,
                      controller: _breakMin2Controller,
                    ),
                    _buildDigitBox(
                      containerWidth, containerHeight,
                      timerTop: 0.5012, timerLeft: 0.10, timerRight: 0.10, timerBottom: 0.3566,
                      boxTop: 0.0847, boxLeft: 0.5417, boxRight: 0.2716, boxBottom: 0.0982,
                      controller: _breakSec1Controller,
                    ),
                    _buildDigitBox(
                      containerWidth, containerHeight,
                      timerTop: 0.5012, timerLeft: 0.10, timerRight: 0.10, timerBottom: 0.3566,
                      boxTop: 0.0847, boxLeft: 0.7685, boxRight: 0.0447, boxBottom: 0.0982,
                      controller: _breakSec2Controller,
                    ),
                    
                    // Sessions box: inset [83.61%, 42.47%, 4.77%, 42.59%]
                    Positioned(
                      top: containerHeight * 0.8361,
                      left: containerWidth * 0.4259,
                      right: containerWidth * 0.4247,
                      bottom: containerHeight * 0.0477,
                      child: TextField(
                        controller: _sessionsController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E90FF),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Play button (Figma assets: Default 66px / Variant2 72px when pressed)
            Positioned(
              top: playTop - (_isPlayPressed ? 3 : 0),
              left: (screenWidth - (_isPlayPressed ? 72 : 66)) / 2,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isPlayPressed = true),
                onTapUp: (_) {
                  setState(() => _isPlayPressed = false);
                  _startTimerLogic();
                },
                onTapCancel: () => setState(() => _isPlayPressed = false),
                child: Container(
                  width: _isPlayPressed ? 72 : 66,
                  height: _isPlayPressed ? 72 : 66,
                  decoration: BoxDecoration(
                    color: _isPlayPressed ? const Color(0xFF671A1A) : Colors.black,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Build individual digit box positioned using Figma inset percentages
  Widget _buildDigitBox(
    double containerWidth,
    double containerHeight, {
    required double timerTop,
    required double timerLeft,
    required double timerRight,
    required double timerBottom,
    required double boxTop,
    required double boxLeft,
    required double boxRight,
    required double boxBottom,
    required TextEditingController controller,
  }) {
    // Calculate timer area dimensions
    final timerTopPx = containerHeight * timerTop;
    final timerLeftPx = containerWidth * timerLeft;
    final timerWidth = containerWidth * (1 - timerLeft - timerRight);
    final timerHeight = containerHeight * (1 - timerTop - timerBottom);
    
    // Calculate box position within timer area
    final boxTopPx = timerHeight * boxTop;
    final boxLeftPx = timerWidth * boxLeft;
    final boxWidth = timerWidth * (1 - boxLeft - boxRight);
    final boxHeight = timerHeight * (1 - boxTop - boxBottom);
    
    return Positioned(
      top: timerTopPx + boxTopPx,
      left: timerLeftPx + boxLeftPx,
      width: boxWidth,
      height: boxHeight,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E90FF),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: false,
        ),
      ),
    );
  }

  // Build editable timer with 4 boxes: MM:SS (MM editable, SS always 00)
  Widget _buildEditableTimer(TextEditingController controller) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1E90FF),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minutes input (editable)
          _buildEditableBox(controller, 2),
          const SizedBox(width: 12),
          // Colon separator
          Text(
            ':',
            style: AppTextStyles.titleInElement.copyWith(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          // Seconds (always 00, read-only)
          _buildReadOnlyBox('00'),
        ],
      ),
    );
  }

  // Build single editable box for sessions
  Widget _buildSingleBox(TextEditingController controller) {
    return Container(
      width: 68,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1E90FF),
          width: 2.5,
        ),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E90FF),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  // Build editable white box for minutes
  Widget _buildEditableBox(TextEditingController controller, int maxLength) {
    return Container(
      width: 78,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: maxLength,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E90FF),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  // Build read-only box for seconds (always 00)
  Widget _buildReadOnlyBox(String text) {
    return Container(
      width: 78,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E90FF),
          ),
        ),
      ),
    );
  }

  // Build transparent editable timer for SVG overlay (MM:SS format)
  Widget _buildTransparentEditableTimer(TextEditingController minController, TextEditingController secController) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minutes input (editable)
        _buildTransparentEditableBox(minController, 2),
        const SizedBox(width: 12),
        // Colon separator
        const Text(
          ':',
          style: TextStyle(
            fontSize: 32,
            color: Color(0xFF1E90FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        // Seconds (editable)
        _buildTransparentEditableBox(secController, 2),
      ],
    );
  }

  // Build transparent editable box for overlay on SVG
  Widget _buildTransparentEditableBox(TextEditingController controller, int maxLength) {
    return SizedBox(
      width: 78,
      height: 52,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: maxLength,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E90FF),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: false,
        ),
      ),
    );
  }

  // Build transparent read-only box for SVG overlay
  Widget _buildTransparentReadOnlyBox(String text) {
    return SizedBox(
      width: 78,
      height: 52,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E90FF),
          ),
        ),
      ),
    );
  }

  // Build transparent single box for sessions on SVG overlay
  Widget _buildTransparentSingleBox(TextEditingController controller) {
    return SizedBox(
      width: 68,
      height: 60,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E90FF),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: false,
        ),
      ),
    );
  }

  // Build 4-digit timer (each digit in separate box: M M : S S) - OLD VERSION - NOT USED ANYMORE
  Widget _buildFourDigitTimer(TextEditingController controller) {
    // Split controller text into individual characters
    final text = controller.text.padLeft(2, '0');
    final digit1Controller = TextEditingController(text: text.isNotEmpty ? text[0] : '0');
    final digit2Controller = TextEditingController(text: text.length > 1 ? text[1] : '0');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E90FF),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // First minute digit
          _buildSingleDigitBox(digit1Controller, 0, controller),
          // Second minute digit
          _buildSingleDigitBox(digit2Controller, 1, controller),
          // Colon
          Text(
            ':',
            style: AppTextStyles.titleInElement.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          // First second digit (always 0)
          _buildSingleDigitBox(TextEditingController(text: '0'), -1, null, readOnly: true),
          // Second second digit (always 0)
          _buildSingleDigitBox(TextEditingController(text: '0'), -1, null, readOnly: true),
        ],
      ),
    );
  }

  Widget _buildSingleDigitBox(
    TextEditingController digitController,
    int position,
    TextEditingController? mainController, {
    bool readOnly = false,
  }) {
    return Container(
      width: 42,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: digitController,
        readOnly: readOnly,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E90FF),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (mainController != null && value.isNotEmpty) {
            // Update main controller
            final currentText = mainController.text.padLeft(2, '0');
            String newText = currentText;
            if (position == 0) {
              newText = value + (currentText.length > 1 ? currentText[1] : '0');
            } else if (position == 1) {
              newText = (currentText.isNotEmpty ? currentText[0] : '0') + value;
            }
            mainController.text = newText;
          }
        },
      ),
    );
  }

  // VIEW 2 & 3: ACTIVE TIMER (Studying / Break) 
  Widget _buildActiveTimerView() {
    bool isStudying = _phase == TimerPhase.studying;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Same scale factor as main page
        final double scale = (constraints.maxHeight / 917.0).clamp(0.7, 1.4);
        
        // Dimensions (same as main page)
        final double potHeight = 289 * scale;
        final double potWidth = 173 * scale;
        final double wateringHeight = 227 * scale;
        final double wateringWidth = 233 * scale;
        final double grassHeight = 141 * scale;

        // Positions (same as main page) for pot
        final double potLeft = 6 * scale;
        final double potBottom = 70 * scale;

        // Per-level plant layout (align stem to pot center/top)
        final _PlantLayout layout = _plantLayouts[_currentPlantState];
        final double plantHeight = layout.height * scale;
        final double plantWidth = layout.width * scale;
        final double plantLeft = layout.left * scale; // Use layout.left for per-level positioning
        final double plantBottom = layout.bottom * scale;
        final double wateringBottom = 70 * scale;
        final double wateringRight = -15 * scale; // Ελαφρώς πιο δεξιά
        final double settingsLeft = 10 * scale;
        final double settingsTop = 17 * scale;
        final double settingsSize = 72 * scale;
        
        // Get animation values
        final double scaleValue = _wateringCanScaleAnimation.value;
        final double glowOpacity = _wateringCanGlowAnimation.value;
        
        return Stack(
          children: [
            // Settings Icon
            Positioned(
              left: settingsLeft,
              top: settingsTop,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
                child: SizedBox(
                  width: settingsSize,
                  height: settingsSize,
                  child: const Icon(Icons.settings, size: 40),
                ),
              ),
            ),

            // Τίτλος & Χρονόμετρο 
            Positioned(
              top: 100 * scale,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    isStudying ? "Studying left:" : "Break left:",
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 24 * scale.clamp(0.8, 1.2),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Χρονόμετρο
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 10 * scale),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 2 * scale),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Session: $_currentSession",
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 12 * scale.clamp(0.8, 1.2),
                            ),
                          ),
                        ),
                        SizedBox(height: 5 * scale),
                        Text(
                          _timerString,
                          style: AppTextStyles.bigTitle.copyWith(
                            fontSize: 40 * scale.clamp(0.8, 1.2),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Controls (Play/Pause/Stop)
                  SizedBox(height: 10 * scale),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                        iconSize: 30 * scale.clamp(0.8, 1.2),
                        onPressed: _togglePause,
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        iconSize: 30 * scale.clamp(0.8, 1.2),
                        onPressed: _stopTimer,
                      ),
                    ],
                  )
                ],
              ),
            ),

            // Γρασίδι (same position as main page)
            Positioned(
              bottom: -5 * scale,
              left: 0,
              right: 0,
              child: SvgPicture.asset(
                _grassPath,
                height: grassHeight,
                fit: BoxFit.cover,
              ),
            ),

            // Γλάστρα (same position as main page)
            Positioned(
              left: potLeft,
              bottom: potBottom,
              child: SvgPicture.asset(
                isStudying ? _potPath : 'assets/images/pot_normal.svg',
                height: potHeight,
                width: potWidth,
                fit: BoxFit.contain,
              ),
            ),

            // Φυτό (same position as main page, grows during studying)
            Positioned(
              left: plantLeft,
              bottom: plantBottom,
              child: SvgPicture.asset(
                _plantStages[_currentPlantState],
                height: plantHeight,
                width: plantWidth,
                fit: BoxFit.contain,
              ),
            ),

            // Ποτιστήρι (studying: γυρισμένο, break: με βρύση)
            if (isStudying)
              Positioned(
                left: 106 * scale,
                top: 457 * scale,
                width: 306.828 * scale,
                height: 306.828 * scale,
                child: Transform.rotate(
                  angle: 0 * 3.14159 / 180, 
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 216 * scale,
                    height: 217.92 * scale,
                    child: SvgPicture.asset(
                      _wateringModePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              )
            else
              // Break phase: Watering can with tap (from Figma 141:1077)
              Positioned(
                right: wateringRight,
                bottom: wateringBottom,
                child: SizedBox(
                  width: wateringWidth,
                  height: wateringHeight,
                  child: SvgPicture.asset(
                    _breakWateringPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

          ],
        );
      },
    );
  }
}