import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:bebsho/services/speech_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Enable full-screen sticky immersive mode for kids (prevents accidental swipe exits)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Asynchronously initialize global speech engine once for low-RAM devices
  GlobalSpeechEngine().init();
  runApp(const PremiumKidsApp());
}

class PremiumKidsApp extends StatelessWidget {
  const PremiumKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnleyLab Kids English',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // AnleyLab Blue
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFFF59E0B), // AnleyLab Gold
          surface: const Color(0xFF0F172A),   // AnleyLab Deep Navy
        ),
      ),
      home: const AppSplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  APP SPLASH SCREEN (AnleyLab & Bebsho Kids Opening Screen)
// ─────────────────────────────────────────────────────────
class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  final FlutterTts tts = FlutterTts();
  bool isReady = false;
  bool isEntering = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _animCtrl.forward();

    tts.setLanguage("en-US");
    tts.setSpeechRate(0.40);
    tts.setPitch(1.35);

    _initEngine();
  }

  Future<void> _initEngine() async {
    await GlobalSpeechEngine().init();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        isReady = true;
      });
    }
  }

  Future<void> _launchApp() async {
    if (isEntering) return;
    setState(() => isEntering = true);

    try {
      await tts.stop();
      await tts.speak("Welcome to Bebsho Kids! Let's learn!");
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const MainGameMapScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Interactive Bouncing Logo Button
                GestureDetector(
                  onTap: isReady ? _launchApp : null,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isEntering ? 130 : 120,
                      height: isEntering ? 130 : 120,
                      decoration: BoxDecoration(
                        color: isEntering ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isEntering ? const Color(0xFF10B981) : const Color(0xFF2563EB)).withValues(alpha: 0.45),
                            blurRadius: 32,
                            spreadRadius: 8,
                          ),
                        ],
                        border: Border.all(color: Colors.white30, width: 3),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            isEntering ? Icons.play_arrow_rounded : Icons.mic_rounded,
                            size: 58,
                            color: Colors.white,
                          ),
                          const Positioned(
                            right: 18,
                            top: 18,
                            child: Icon(Icons.star_rounded, size: 28, color: Color(0xFFF59E0B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // AnleyLab Brand Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF475569), width: 1),
                  ),
                  child: const Text(
                    "ANLEYLAB",
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // App Title
                const Text(
                  "Bebsho Kids",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Offline Voice English Learning",
                  style: TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),

                const Spacer(),

                // Dynamic Interactive Play Button vs Loading Indicator
                if (!isReady) ...[
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Loading Speech Engine...",
                    style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), // Emerald Green
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 8,
                        ),
                        onPressed: _launchApp,
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                        label: const Text(
                          "LET'S PLAY",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum AgeGroup { starter, explorer, hero }

extension AgeGroupExtension on AgeGroup {
  String get title {
    switch (this) {
      case AgeGroup.starter:
        return 'Beginner';
      case AgeGroup.explorer:
        return 'Intermediate';
      case AgeGroup.hero:
        return 'Advanced';
    }
  }

  String get key {
    switch (this) {
      case AgeGroup.starter:
        return 'starter_3_4';
      case AgeGroup.explorer:
        return 'explorer_5_6';
      case AgeGroup.hero:
        return 'hero_7_10';
    }
  }
}

class MainGameMapScreen extends StatefulWidget {
  const MainGameMapScreen({super.key});

  @override
  State<MainGameMapScreen> createState() => _MainGameMapScreenState();
}

class _MainGameMapScreenState extends State<MainGameMapScreen> {
  AgeGroup activeGroup = AgeGroup.starter;
  int xp = 0;
  int streak = 1;
  int completedLevel = 1;
  int totalLevels = 10;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgressForGroup(activeGroup);
  }

  Future<void> _loadProgressForGroup(AgeGroup group) async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    int wordCount = 0;
      if (group == AgeGroup.starter) {
        wordCount = 212;
      } else if (group == AgeGroup.explorer) {
        wordCount = 764;
      } else {
        wordCount = 1024;
      }

    setState(() {
      activeGroup = group;
      xp = prefs.getInt('${group.key}_xp') ?? 0;
      streak = prefs.getInt('user_streak') ?? 1;
      completedLevel = prefs.getInt('${group.key}_completed_level') ?? 1;
      totalLevels = (wordCount / 10).ceil();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // AnleyLab Deep Navy
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        toolbarHeight: 75,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Age Group Picker Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF475569), width: 2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AgeGroup>(
                  value: activeGroup,
                  dropdownColor: const Color(0xFF334155),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                  items: AgeGroup.values.map((AgeGroup group) {
                    return DropdownMenuItem<AgeGroup>(
                      value: group,
                      child: Text(
                        group.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (AgeGroup? newGroup) {
                    if (newGroup != null) _loadProgressForGroup(newGroup);
                  },
                ),
              ),
            ),
            // XP & Streak Badge
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 24),
                  onPressed: () => showAboutDeveloperModal(context),
                ),
                const SizedBox(width: 4),
                _buildHeaderBadge(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFF97316),
                  value: "$streak",
                ),
                const SizedBox(width: 8),
                _buildHeaderBadge(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  value: "$xp XP",
                ),
              ],
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 30, bottom: 80),
                  child: Center(
                    child: SizedBox(
                      width: math.min(MediaQuery.of(context).size.width, 600),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: totalLevels,
                        itemBuilder: (context, index) {
                          int levelNumber = index + 1;
                          bool isCompleted = levelNumber < completedLevel;
                          bool isCurrent = levelNumber == completedLevel;
                          bool isLocked = levelNumber > completedLevel;

                          // Winding path layout
                          double xOffset = math.sin(index * 0.8) * 80;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 20),
                            child: Transform.translate(
                              offset: Offset(xOffset, 0),
                              child: Center(
                                child: _buildLevelNodeButton(
                                  context: context,
                                  level: levelNumber,
                                  isCompleted: isCompleted,
                                  isCurrent: isCurrent,
                                  isLocked: isLocked,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Professional AnleyLab Branding Footer
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Text(
                      "AnleyLab Learning Engine",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderBadge({required IconData icon, required Color iconColor, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF475569), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelNodeButton({
    required BuildContext context,
    required int level,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLocked,
  }) {
    Color baseColor = isCompleted
        ? const Color(0xFF10B981) // Completed Green
        : isCurrent
            ? const Color(0xFFF59E0B) // Active Gold
            : const Color(0xFF475569); // Locked Slate

    Color bottomColor = isCompleted
        ? const Color(0xFF047857)
        : isCurrent
            ? const Color(0xFFD97706)
            : const Color(0xFF334155);

    bool isSentenceLevel = (level % 2 == 0);

    return GestureDetector(
      onTap: !isLocked
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => isSentenceLevel
                      ? SentenceBuilderLessonScreen(
                          level: level,
                          ageGroup: activeGroup,
                        )
                      : InteractiveLessonScreen(
                          level: level,
                          ageGroup: activeGroup,
                        ),
                ),
              );
              _loadProgressForGroup(activeGroup);
            }
          : null,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (isCurrent)
            Positioned(
              top: -34,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: const Text(
                  "PLAY",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          // 3D Pressable Button Container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: bottomColor,
              shape: BoxShape.circle,
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: baseColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock_rounded, color: Colors.white30, size: 28)
                    : isCompleted
                        ? const Icon(Icons.star_rounded, color: Colors.white, size: 34)
                        : Text(
                            "$level",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                            ),
                          ),
              ),
            ),
          ),
          // Level Type Indicator Badge (Word vs Sentence)
          Positioned(
            bottom: -18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSentenceLevel ? const Color(0xFF2563EB) : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSentenceLevel ? const Color(0xFF60A5FA) : const Color(0xFF475569), width: 1),
              ),
              child: Text(
                isSentenceLevel ? "SENTENCE" : "WORD",
                style: TextStyle(
                  color: isSentenceLevel ? Colors.white : Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// lightweight custom confetti particle representation
class ConfettiParticle {
  double x, y;
  double vx, vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.45; // simulated gravity
    rotation += rotationSpeed;
  }
}

class InteractiveLessonScreen extends StatefulWidget {
  final int level;
  final AgeGroup ageGroup;

  const InteractiveLessonScreen({
    super.key,
    required this.level,
    required this.ageGroup,
  });

  @override
  State<InteractiveLessonScreen> createState() => _InteractiveLessonScreenState();
}

class _InteractiveLessonScreenState extends State<InteractiveLessonScreen> with TickerProviderStateMixin {
  final AudioPlayer audioPlayer = AudioPlayer();
  final FlutterTts tts = FlutterTts();
  VoskFlutterPlugin? vosk;
  Model? model;
  Recognizer? recognizer;
  SpeechService? speechService;

  StreamSubscription<String>? _partialSub;
  StreamSubscription<String>? _resultSub;

  List<Map<String, dynamic>> levelWords = [];
  int currentIndex = 0;
  String status = "Preparing Engine...";
  String recognizedText = "";
  bool isListening = false;
  bool isReady = false;
  bool isMobilePlatform = false;

  // Confetti Animation support
  late AnimationController _confettiController;
  final List<ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  String get currentWord => levelWords.isNotEmpty ? levelWords[currentIndex]["word"] : "";
  String get currentPhonetic => levelWords.isNotEmpty ? levelWords[currentIndex]["phonetic"] : "";

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Prevent tablet screen sleep during active lesson
    isMobilePlatform = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (isMobilePlatform) {
      vosk = VoskFlutterPlugin.instance();
    }

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(() {
        setState(() {
          for (var p in _particles) {
            p.update();
          }
        });
      });

    _loadWordsAndInit();
  }

  Future<void> _loadWordsAndInit() async {
    try {
      final String response = await rootBundle.loadString('assets/words.json');
      final List<dynamic> data = jsonDecode(response);
      final allWords = List<Map<String, dynamic>>.from(data);

      int ageValue = widget.ageGroup == AgeGroup.starter ? 3 : (widget.ageGroup == AgeGroup.explorer ? 5 : 7);
      final groupWords = allWords.where((w) => w['minAge'] == ageValue).toList();

      int startIndex = (widget.level - 1) * 10;
      int endIndex = (startIndex + 10) <= groupWords.length ? (startIndex + 10) : groupWords.length;

      setState(() {
        levelWords = groupWords.sublist(startIndex, endIndex);
      });
    } catch (_) {
      setState(() => status = "Parse error");
      return;
    }

    await _initSpeechEngine();
  }

  Future<void> _initSpeechEngine() async {
    // Highly engaging kid-friendly voice settings (Energetic, high-pitched fallback)
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.38);
    await tts.setPitch(1.35); // Energetic and cheerful cartoonish/teacher pitch!
    await tts.setVolume(1.0); // Ensure maximum audio output volume for tablet speakers

    if (isMobilePlatform) {
      var perm = await Permission.microphone.request();
      if (!perm.isGranted) {
        setState(() => status = "Microphone Permission Denied");
        return;
      }

      try {
        await GlobalSpeechEngine().init();

        _partialSub?.cancel();
        _partialSub = GlobalSpeechEngine().onPartialResult?.listen((text) {
          if (!mounted || !isListening) return;
          if (text.isNotEmpty) {
            setState(() => recognizedText = text);
            _evaluateSpokenWord(text);
          }
        });

        _resultSub?.cancel();
        _resultSub = GlobalSpeechEngine().onResult?.listen((text) {
          if (!mounted || !isListening) return;
          if (text.isNotEmpty) {
            setState(() => recognizedText = text);
            _evaluateSpokenWord(text);
          }
        });
      } catch (e) {
        setState(() => status = "Engine initialization failed");
        return;
      }
    }

    setState(() {
      isReady = true;
      status = "Tap mic & repeat!";
    });

    if (levelWords.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _playAudioForWord(currentWord);
    }
  }

  Future<void> _playAudioForWord(String word) async {
    final audioPath = 'audio/${word.toLowerCase().trim()}.mp3';
    try {
      await audioPlayer.stop();
      await audioPlayer.play(AssetSource(audioPath));
    } catch (_) {
      await tts.stop();
      await tts.speak(word);
    }
  }

  // Trigger high-satisfaction lightweight confetti explosion
  void _triggerSuccessConfetti() {
    _particles.clear();
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    
    final List<Color> colors = [
      const Color(0xFFF59E0B), // Gold
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEC4899), // Pink
      const Color(0xFFEF4444), // Red
    ];

    // Emit 30 vibrant colorful particles
    for (int i = 0; i < 30; i++) {
      _particles.add(ConfettiParticle(
        x: width / 2,
        y: height * 0.4,
        vx: (_random.nextDouble() - 0.5) * 16,
        vy: -_random.nextDouble() * 14 - 4,
        size: _random.nextDouble() * 12 + 6,
        color: colors[_random.nextInt(colors.length)],
        rotation: _random.nextDouble() * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.3,
      ));
    }

    _confettiController.forward(from: 0.0);
  }

  Future<void> _toggleListening() async {
    if (!isReady) return;

    if (isListening) {
      if (isMobilePlatform) await GlobalSpeechEngine().stop();
      setState(() => isListening = false);
    } else {
      await audioPlayer.stop();
      await tts.stop();
      // Allow audio hardware 350ms to release playback focus before opening record stream
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() {
        isListening = true;
        recognizedText = "";
        status = "Listening...";
      });
      if (isMobilePlatform) {
        try {
          await GlobalSpeechEngine().start();
        } catch (e) {
          if (mounted) {
            setState(() {
              isListening = false;
              status = "Mic error! Tap to retry";
            });
          }
        }
      }
    }
  }

  void _evaluateSpokenWord(String spoken) async {
    if (isMobilePlatform) await GlobalSpeechEngine().stop();
    if (mounted) setState(() => isListening = false);

    final cleanSpoken = spoken.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), '').trim();
    final cleanExpected = currentWord.toLowerCase().trim();

    if (cleanSpoken == cleanExpected || cleanSpoken.contains(cleanExpected)) {
      _triggerSuccessConfetti();
      if (mounted) setState(() => status = "CORRECT! 🎉");
      
      // Cheerful correct tone fallback via energetic speech
      await speakWordPitched("Awesome!");
      await Future.delayed(const Duration(milliseconds: 1100));

      if (currentIndex + 1 < levelWords.length) {
        if (mounted) {
          setState(() {
            currentIndex++;
            recognizedText = "";
            status = "Tap mic & repeat!";
          });
        }
        _playAudioForWord(currentWord);
      } else {
        await _completeLevelSequence();
      }
    } else {
      if (mounted) setState(() => status = "Try again!");
      await speakWordPitched("Try again");
    }
  }

  Future<void> speakWordPitched(String txt) async {
    await tts.stop();
    await tts.speak(txt);
  }

  Future<void> _completeLevelSequence() async {
    final prefs = await SharedPreferences.getInstance();
    String prefix = widget.ageGroup.key;

    int currentXp = prefs.getInt('${prefix}_xp') ?? 0;
    int currentCompletedLevel = prefs.getInt('${prefix}_completed_level') ?? 1;

    await prefs.setInt('${prefix}_xp', currentXp + 100);
    if (widget.level >= currentCompletedLevel) {
      await prefs.setInt('${prefix}_completed_level', widget.level + 1);
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StarRewardDialog(
          level: widget.level,
          xpEarned: 100,
          onNextLevel: () {
            int nextLevel = widget.level + 1;
            bool isNextSentence = (nextLevel % 2 == 0);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => isNextSentence
                    ? SentenceBuilderLessonScreen(level: nextLevel, ageGroup: widget.ageGroup)
                    : InteractiveLessonScreen(level: nextLevel, ageGroup: widget.ageGroup),
              ),
            );
          },
          onHome: () => Navigator.pop(context),
        ),
      );
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _partialSub?.cancel();
    _resultSub?.cancel();
    _confettiController.dispose();
    audioPlayer.dispose();
    if (isMobilePlatform) {
      GlobalSpeechEngine().stop();
    }
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (levelWords.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 18))),
      );
    }

    double progress = (currentIndex + 1) / levelWords.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 14,
            backgroundColor: const Color(0xFF1E293B),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Word Display Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF334155), width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentWord.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "\"$currentPhonetic\"",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        IconButton(
                          onPressed: () => _playAudioForWord(currentWord),
                          icon: const Icon(Icons.volume_up_rounded, size: 36, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  if (recognizedText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Heard: \"$recognizedText\"",
                      style: const TextStyle(fontSize: 18, color: Color(0xFF10B981), fontWeight: FontWeight.w800),
                    ),
                  ],
                  const Spacer(),
                  // Mic Trigger
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        boxShadow: [
                          BoxShadow(
                            color: (isListening ? Colors.red : const Color(0xFF10B981)).withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: 4,
                          )
                        ],
                      ),
                      child: Icon(
                        isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Confetti Overlay Layer
            if (_particles.isNotEmpty)
              IgnorePointer(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: ConfettiPainter(particles: _particles),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Particle rendering canvas
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      
      // Draw rectangular paper-like confetti flakes
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


// ─────────────────────────────────────────────────────────
//  SENTENCE BUILDER LESSON SCREEN  (Levels 11+)
// ─────────────────────────────────────────────────────────
class SentenceBuilderLessonScreen extends StatefulWidget {
  final int level;
  final AgeGroup ageGroup;
  const SentenceBuilderLessonScreen({
    super.key,
    required this.level,
    required this.ageGroup,
  });
  @override
  State<SentenceBuilderLessonScreen> createState() =>
      _SentenceBuilderLessonScreenState();
}

class _SentenceBuilderLessonScreenState
    extends State<SentenceBuilderLessonScreen> {
  final FlutterTts tts = FlutterTts();
  List<Map<String, dynamic>> sentences = [];
  String? selectedWord;
  bool? isCorrect;
  bool isLoading = true;

  Map<String, dynamic> get current => sentences[0];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Prevent tablet screen sleep during active lesson
    tts.setLanguage("en-US");
    tts.setSpeechRate(0.38);
    tts.setPitch(1.25);
    tts.setVolume(1.0); // Ensure maximum audio output volume for tablet speakers
    _loadSentence();
  }

  Future<void> _loadSentence() async {
    try {
      final String json = await rootBundle.loadString('assets/sentences.json');
      final Map<String, dynamic> data = jsonDecode(json);
      final String ageKey = widget.ageGroup.key;
      if (data.containsKey(ageKey)) {
        final all = List<Map<String, dynamic>>.from(data[ageKey]);
        if (all.isNotEmpty) {
          final int idx = (widget.level - 1) % all.length;
          setState(() {
            sentences = [all[idx]];
            isLoading = false;
          });
          await Future.delayed(const Duration(milliseconds: 400));
          await _speakSentence();
          return;
        }
      }
    } catch (_) {}
    setState(() => isLoading = false);
  }

  Future<void> _speakSentence() async {
    if (sentences.isEmpty) return;
    final String full =
        "${current['framePrefix']} ${current['targetWord']} ${current['frameSuffix']}"
            .trim();
    await tts.stop();
    await tts.speak(full);
  }

  Future<void> _checkAnswer(String word) async {
    final bool correct =
        word.toLowerCase() == current['targetWord'].toString().toLowerCase();
    setState(() {
      selectedWord = word;
      isCorrect = correct;
    });
    final String full =
        "${current['framePrefix']} $word ${current['frameSuffix']}".trim();
    await tts.stop();
    await tts.speak(full);

    if (correct) {
      await Future.delayed(const Duration(milliseconds: 1300));
      if (mounted) await _completeLevel();
    } else {
      await Future.delayed(const Duration(milliseconds: 900));
      setState(() { selectedWord = null; isCorrect = null; });
      await tts.speak("Try again!");
    }
  }

  Future<void> _completeLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final String prefix = widget.ageGroup.key;
    final int xp = prefs.getInt('${prefix}_xp') ?? 0;
    final int done = prefs.getInt('${prefix}_completed_level') ?? 1;
    await prefs.setInt('${prefix}_xp', xp + 100);
    if (widget.level >= done) {
      await prefs.setInt('${prefix}_completed_level', widget.level + 1);
    }
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => StarRewardDialog(
          level: widget.level,
          xpEarned: 100,
          onNextLevel: () {
            int nextLevel = widget.level + 1;
            bool isNextSentence = (nextLevel % 2 == 0);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => isNextSentence
                    ? SentenceBuilderLessonScreen(level: nextLevel, ageGroup: widget.ageGroup)
                    : InteractiveLessonScreen(level: nextLevel, ageGroup: widget.ageGroup),
              ),
            );
          },
          onHome: () => Navigator.pop(context),
        ),
      );
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }
    if (sentences.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            leading: BackButton(color: Colors.white, onPressed: () => Navigator.pop(context))),
        body: const Center(child: Text('Coming soon!', style: TextStyle(color: Colors.white70, fontSize: 18))),
      );
    }

    final options = List<String>.from(current['options']);
    final framePrefix = current['framePrefix'] as String;
    final frameSuffix = current['frameSuffix'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Level ${widget.level} • Sentence Builder',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Instruction banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over_rounded, color: Color(0xFF2563EB), size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Tap the correct word to complete the sentence.',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: _speakSentence,
                      icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF2563EB), size: 22),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Sentence board with blank slot
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF334155), width: 2),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    if (framePrefix.isNotEmpty)
                      Text(framePrefix,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedWord == null
                            ? const Color(0xFF334155)
                            : (isCorrect == true ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedWord == null ? const Color(0xFF2563EB) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        selectedWord ?? '_____',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                    if (frameSuffix.isNotEmpty)
                      Text(frameSuffix,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Phonetic guide
              Text(
                '/${current['phonetic']}/',
                style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 15, fontWeight: FontWeight.w700),
              ),

              const Spacer(),

              // Option tiles
              ...options.map((word) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFF334155), width: 2),
                        ),
                        elevation: 4,
                      ),
                      onPressed: selectedWord == null ? () => _checkAnswer(word) : null,
                      child: Text(word.toUpperCase(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  STAR REWARD DIALOG
// ─────────────────────────────────────────────────────────
class StarRewardDialog extends StatefulWidget {
  final int level;
  final int xpEarned;
  final VoidCallback onNextLevel;
  final VoidCallback onHome;

  const StarRewardDialog({
    super.key,
    required this.level,
    required this.xpEarned,
    required this.onNextLevel,
    required this.onHome,
  });

  @override
  State<StarRewardDialog> createState() => _StarRewardDialogState();
}

class _StarRewardDialogState extends State<StarRewardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _buildStar({required double size, required double angle}) {
    return Transform.rotate(
      angle: angle,
      child: Icon(Icons.star_rounded, size: size, color: const Color(0xFFF59E0B),
          shadows: const [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF334155), width: 3),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3 stars with tilt
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStar(size: 48, angle: -0.2),
                  const SizedBox(width: 8),
                  _buildStar(size: 64, angle: 0.0),
                  const SizedBox(width: 8),
                  _buildStar(size: 48, angle: 0.2),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'LEVEL ${widget.level} CLEARED!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 26),
                    const SizedBox(width: 8),
                    Text('+${widget.xpEarned} XP',
                        style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w900, fontSize: 20)),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Primary NEXT LEVEL Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Emerald Green
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 6,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onNextLevel();
                  },
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  label: const Text(
                    'NEXT LEVEL',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Secondary MAP / HOME Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onHome();
                  },
                  icon: const Icon(Icons.map_rounded, color: Colors.white70, size: 20),
                  label: const Text(
                    'BACK TO MAP',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
Future<void> launchAnleyLabWebsite() async {
  const url = 'https://www.anleylab.et';
  try {
    const channel = MethodChannel('com.anleylab.kids/url_launcher');
    await channel.invokeMethod('launchUrl', <String, Object>{'url': url});
  } catch (e) {
    if (kDebugMode) {
      print("Error launching URL: $e");
    }
  }
}

void showAboutDeveloperModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Developer Avatar
            const CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFF2563EB),
              child: Icon(Icons.code_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // App & Developer Info
            const Text(
              "Bebsho Kids",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Version 1.0.0 • Offline Speech Engine",
              style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Bio / Mission Statement
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF475569), width: 1.5),
              ),
              child: const Text(
                "Designed and engineered for lightweight, fast, and accessible offline learning for children across all age groups.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),

            // Developer Credentials
            _buildProfileTile(
              icon: Icons.person_outline_rounded,
              title: "Developer & Builder",
              subtitle: "AnleyLab",
            ),
            const SizedBox(height: 10),

            // CLICKABLE WEBSITE TILE -> www.anleylab.et
            InkWell(
              onTap: launchAnleyLabWebsite,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.language_rounded, color: Color(0xFF2563EB), size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Official Website", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("www.anleylab.et", style: TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new_rounded, color: Colors.white54, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            _buildProfileTile(
              icon: Icons.verified_user_outlined,
              title: "Privacy First",
              subtitle: "100% Offline • No data collection",
            ),
            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "CLOSE",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildProfileTile({required IconData icon, required String title, required String subtitle}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF334155),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 24),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ],
    ),
  );
}