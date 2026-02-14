import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:math';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  bool showOnboarding = prefs.getBool('showOnboarding') ?? true;

  runApp(ZenSudokuPro(showOnboarding: showOnboarding));
}

class ZenSudokuPro extends StatelessWidget {
  final bool showOnboarding;
  const ZenSudokuPro({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zen Sudoku',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020617),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      ),
      home: SplashScreen(
        nextScreen: showOnboarding ? const OnboardingScreen() : const MainNavigation(),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// STORAGE
// ────────────────────────────────────────────────

class GameStorage {
  static Future<void> saveRecord(String diff, int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    int wins = prefs.getInt('${diff}_wins') ?? 0;
    int? best = prefs.getInt('${diff}_best');

    await prefs.setInt('${diff}_wins', wins + 1);
    if (best == null || seconds < best) {
      await prefs.setInt('${diff}_best', seconds);
    }
  }

  static Future<Map<String, dynamic>> getStats(String diff) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'wins': prefs.getInt('${diff}_wins') ?? 0,
      'best': prefs.getInt('${diff}_best'),
    };
  }
}

// ────────────────────────────────────────────────
// SPLASH SCREEN
// ────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scale;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    scale = CurvedAnimation(parent: controller, curve: Curves.elasticOut);
    controller.forward();

    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => widget.nextScreen,
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ScaleTransition(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(FeatherIcons.grid, size: 80, color: Color(0xFF6366F1)),
              const SizedBox(height: 20),
              Text(
                "ZEN",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// ONBOARDING
// ────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardState();
}

class _OnboardState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;

  final data = [
    {"t": "Sharpen Mind", "d": "Classic sudoku puzzles for mental clarity."},
    {"t": "Zen Experience", "d": "Minimal design. No distraction."},
    {"t": "Track Progress", "d": "Beat your best time."},
  ];

  Future<void> finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: controller,
            onPageChanged: (i) => setState(() => page = i),
            itemCount: data.length,
            itemBuilder: (_, i) {
              return Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FeatherIcons.zap, size: 100, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 60),
                    Text(
                      data[i]["t"]!,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      data[i]["d"]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    data.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      width: page == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: page == i ? const Color(0xFF6366F1) : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                FloatingActionButton(
                  backgroundColor: const Color(0xFF6366F1),
                  child: Icon(page == data.length - 1 ? FeatherIcons.check : FeatherIcons.arrowRight),
                  onPressed: () {
                    if (page < data.length - 1) {
                      controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease);
                    } else {
                      finish();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
// MAIN NAVIGATION
// ────────────────────────────────────────────────

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _NavState();
}

class _NavState extends State<MainNavigation> {
  int idx = 0;

  final screens = [
    const PlayTab(),
    const StatsTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, primary, secondary) => FadeThroughTransition(
          animation: primary,
          secondaryAnimation: secondary,
          child: child,
        ),
        child: screens[idx],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => setState(() => idx = i),
        selectedItemColor: const Color(0xFF6366F1),
        backgroundColor: const Color(0xFF020617),
        unselectedItemColor: Colors.white24,
        items: const [
          BottomNavigationBarItem(icon: Icon(FeatherIcons.play), label: "Play"),
          BottomNavigationBarItem(icon: Icon(FeatherIcons.barChart2), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(FeatherIcons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
// PLAY TAB – IMPROVED MODERN HOME SCREEN
// ────────────────────────────────────────────────

class PlayTab extends StatelessWidget {
  const PlayTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 44, 28, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Zen Sessions",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Find your flow. Sharpen your mind.",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white.withOpacity(0.58),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              sliver: AnimationLimiter(
                child: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 12),
                    _buildDifficultyCard(
                      context,
                      title: "Novice",
                      subtitle: "Easy • Generous clues",
                      icon: FeatherIcons.feather,
                      gradient: [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
                      difficulty: "Easy",
                      delay: 100,
                    ),
                    const SizedBox(height: 24),
                    _buildDifficultyCard(
                      context,
                      title: "Adept",
                      subtitle: "Medium • Balanced challenge",
                      icon: FeatherIcons.activity,
                      gradient: [const Color(0xFF9A3412), const Color(0xFFF97316)],
                      difficulty: "Medium",
                      delay: 200,
                    ),
                    const SizedBox(height: 24),
                    _buildDifficultyCard(
                      context,
                      title: "Master",
                      subtitle: "Hard • True test of focus",
                      icon: FeatherIcons.zap,
                      gradient: [const Color(0xFFB91C1C), const Color(0xFFEF4444)],
                      difficulty: "Hard",
                      delay: 300,
                    ),
                    const SizedBox(height: 60),
                  ]),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Opacity(
                    opacity: 0.45,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FeatherIcons.wind, size: 16, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          "One move at a time",
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required String difficulty,
    required int delay,
  }) {
    return AnimationConfiguration.staggeredList(
      position: delay ~/ 100,
      duration: const Duration(milliseconds: 680),
      child: SlideAnimation(
        verticalOffset: 40,
        child: FadeInAnimation(
          child: OpenContainer(
            tappable: true,
            closedElevation: 0,
            closedColor: Colors.transparent,
            openColor: const Color(0xFF020617),
            transitionDuration: const Duration(milliseconds: 480),
            closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            closedBuilder: (context, openContainer) {
              return GestureDetector(
                onTap: openContainer,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.last.withOpacity(0.38),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -40,
                        right: -60,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Colors.white.withOpacity(0.18), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(icon, size: 48, color: Colors.white.withOpacity(0.92)),
                            const Spacer(),
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.0,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.88),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 28,
                        right: 28,
                        child: Icon(
                          FeatherIcons.arrowRight,
                          color: Colors.white.withOpacity(0.75),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            openBuilder: (context, _) => GameScreen(difficulty),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// GAME SCREEN
// ────────────────────────────────────────────────


class GameScreen extends StatefulWidget {
  final String difficulty;
  const GameScreen(this.difficulty, {super.key});

  @override
  State<GameScreen> createState() => _GameState();
}

class _GameState extends State<GameScreen> {
  late List<List<int>> board;
  late List<List<int>> solution;
  late List<List<bool>> fixed;
  late List<List<int>> mistakes;

  int? rSel, cSel;
  int seconds = 0;
  Timer? timer;

  Map<int, int> remaining = {for (int i = 1; i <= 9; i++) i: 9};

  @override
  void initState() {
    super.initState();
    newGame();
  }

  void newGame() {
    timer?.cancel();
    seconds = 0;
    generate();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => seconds++);
    });
  }

  void generate() {
    solution = List.generate(9, (_) => List.generate(9, (_) => 0));
    solve(solution);

    board = solution.map((r) => [...r]).toList();

    int clues = widget.difficulty == "Easy"
        ? 36
        : widget.difficulty == "Medium"
            ? 30
            : 24;

    Random rng = Random();
    int remove = 81 - clues;

    while (remove > 0) {
      int r = rng.nextInt(9);
      int c = rng.nextInt(9);
      if (board[r][c] != 0) {
        board[r][c] = 0;
        remove--;
      }
    }

    fixed = List.generate(9, (r) => List.generate(9, (c) => board[r][c] != 0));
    mistakes = List.generate(9, (_) => List.generate(9, (_) => 0));
    updateRemaining();
  }

  bool solve(List<List<int>> g) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (g[r][c] == 0) {
          var nums = List.generate(9, (i) => i + 1)..shuffle();
          for (int n in nums) {
            if (isSafe(g, r, c, n)) {
              g[r][c] = n;
              if (solve(g)) return true;
              g[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  bool isSafe(List<List<int>> g, int r, int c, int n) {
    for (int i = 0; i < 9; i++) {
      if (g[r][i] == n || g[i][c] == n) return false;
    }
    int br = r ~/ 3 * 3;
    int bc = c ~/ 3 * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (g[br + i][bc + j] == n) return false;
      }
    }
    return true;
  }

  bool cellIsSafe(int row, int col, int num) {
    if (num == 0) return true;
    for (int c = 0; c < 9; c++) if (c != col && board[row][c] == num) return false;
    for (int r = 0; r < 9; r++) if (r != row && board[r][col] == num) return false;

    int br = row ~/ 3 * 3;
    int bc = col ~/ 3 * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int tr = br + i;
        int tc = bc + j;
        if ((tr != row || tc != col) && board[tr][tc] == num) return false;
      }
    }
    return true;
  }

  void input(int n) {
    if (rSel == null || cSel == null || fixed[rSel!][cSel!]) return;

    int row = rSel!;
    int col = cSel!;

    setState(() {
      mistakes[row][col] = 0;
      if (n != 0 && !cellIsSafe(row, col, n)) {
        mistakes[row][col] = 1;
      }
      board[row][col] = n;
      updateRemaining();
    });

    checkWin();
  }

  void updateRemaining() {
    remaining = {for (int i = 1; i <= 9; i++) i: 0};
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        int val = board[r][c];
        if (val >= 1 && val <= 9) remaining[val] = remaining[val]! + 1;
      }
    }
  }

  void checkWin() {
    bool won = true;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] != solution[r][c]) {
          won = false;
          break;
        }
      }
      if (!won) break;
    }

    if (won) {
      timer?.cancel();
      GameStorage.saveRecord(widget.difficulty, seconds);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Completed!"),
          content: Text("Time: $seconds seconds"),
          actions: [
            TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text("Menu"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                newGame();
              },
              child: const Text("New Game"),
            ),
          ],
        ),
      );
    }
  }

  bool highlight(int r, int c) {
    if (rSel == null || cSel == null) return false;
    return r == rSel || c == cSel;
  }

  bool boxHighlight(int r, int c) {
    if (rSel == null || cSel == null) return false;
    return r ~/ 3 == rSel! ~/ 3 && c ~/ 3 == cSel! ~/ 3;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double gridSize = MediaQuery.of(context).size.width - 32;

    return Scaffold(
      body: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Text(
                  widget.difficulty,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  "$seconds s",
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // BOARD
          Container(
            width: gridSize,
            height: gridSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white12),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 81,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
              itemBuilder: (_, i) {
                int r = i ~/ 9;
                int c = i % 9;

                bool selected = rSel == r && cSel == c;
                bool line = highlight(r, c);
                bool box = boxHighlight(r, c);

                return GestureDetector(
                  onTap: () => setState(() {
                    rSel = r;
                    cSel = c;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.indigo.withOpacity(.45)
                          : line
                              ? Colors.indigo.withOpacity(.18)
                              : box
                                  ? Colors.indigo.withOpacity(.12)
                                  : null,
                      border: Border.all(color: Colors.white12, width: .6),
                    ),
                    child: Center(
                      child: Text(
                        board[r][c] == 0 ? "" : "${board[r][c]}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: fixed[r][c] ? FontWeight.bold : FontWeight.w600,
                          color: fixed[r][c]
                              ? Colors.white
                              : mistakes[r][c] == 1
                                  ? Colors.redAccent
                                  : const Color(0xFFc7d2fe),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // REMAINING COUNTER
          Wrap(
            spacing: 10,
            children: [
              for (int i = 1; i <= 9; i++)
                Chip(
                  label: Text("$i : ${9 - remaining[i]!}"),
                  backgroundColor: Colors.white.withOpacity(.05),
                )
            ],
          ),

          const Spacer(),

          // KEYPAD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (int i = 1; i <= 9; i++) keyBtn("$i", () => input(i)),
                keyBtn("⌫", () => input(0), danger: true),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget keyBtn(String t, VoidCallback onTap, {bool danger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: danger
                ? [Colors.redAccent, Colors.red]
                : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.5),
              blurRadius: 10,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Center(
          child: Text(
            t,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// STATS TAB
// ────────────────────────────────────────────────

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  Widget statBox(String diff) {
    return FutureBuilder(
      future: GameStorage.getStats(diff),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 80);
        final data = snapshot.data as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
            color: Colors.white.withOpacity(0.03),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(diff, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Wins: ${data['wins']}", style: const TextStyle(color: Colors.white54)),
                  Text(
                    "Best: ${data['best'] ?? '--'} s",
                    style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Statistics", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            statBox("Easy"),
            statBox("Medium"),
            statBox("Hard"),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// SETTINGS TAB
// ────────────────────────────────────────────────

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SetState();
}

class _SetState extends State<SettingsTab> {
  bool notif = true;
  bool sound = true;
  bool haptic = true;

  Widget settingTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title),
      trailing: Switch(
        value: value,
        activeColor: const Color(0xFF6366F1),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Settings", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            settingTile(FeatherIcons.bell, "Notifications", notif, (v) => setState(() => notif = v)),
            settingTile(FeatherIcons.volume2, "Sound Effects", sound, (v) => setState(() => sound = v)),
            settingTile(FeatherIcons.smartphone, "Haptic Feedback", haptic, (v) => setState(() => haptic = v)),
            const Spacer(),
            const Center(
              child: Text("Zen Sudoku v1.1 • 2025", style: TextStyle(color: Colors.white30)),
            ),
          ],
        ),
      ),
    );
  }
}