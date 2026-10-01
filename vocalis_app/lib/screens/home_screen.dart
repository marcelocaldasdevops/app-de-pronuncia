import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_stats.dart';
import '../models/exercise.dart';
import '../data/exercise_catalog.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'practice_screen.dart';
import 'free_speaking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = StorageService();
  UserStats _stats = UserStats();
  ReviewRecommendation _recommendation =
      const ReviewRecommendation(hasData: false);
  List<String> _customPhrases = [];
  bool _loading = true;
  Difficulty? _selectedDifficulty;
  bool _showAllCatalog = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await _storageService.loadStats();
    final phrases = await _storageService.loadCustomPhrases();
    final recommendation = await _storageService.getReviewRecommendation();
    if (mounted) {
      setState(() {
        _stats = stats;
        _customPhrases = phrases;
        _recommendation = recommendation;
        _loading = false;
      });
    }
  }

  void _openPracticeForReview(String? targetExerciseId) {
    if (targetExerciseId != null && targetExerciseId.isNotEmpty) {
      final match = exerciseCatalog.where((e) => e.id == targetExerciseId);
      if (match.isNotEmpty) {
        _openPracticeWithExercise(match.first);
        return;
      }
    }
    _openPracticeWithExercise(exerciseCatalog.first);
  }

  void _openPracticeWithExercise(Exercise ex) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => PracticeScreen(initialExercise: ex)),
    );
    _loadData();
  }

  void _openPracticeWithCustomPhrase(String phrase) async {
    final customEx = Exercise(
      id: 'custom-${phrase.hashCode}',
      sentence: phrase,
      phoneticIpa: '',
      difficulty: Difficulty.basico,
      category: 'Minhas Frases',
      keyPhonemes: [],
      tip: 'Pratique sua frase personalizada com atenção ao ritmo e clareza.',
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PracticeScreen(
          initialExercise: customEx,
          initialCustomMode: true,
        ),
      ),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.graphic_eq, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Vocalis AI',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warningContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: AppTheme.warning, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${_stats.streakDays} dias',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Greeting & Daily Goal Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4648D4), Color(0xFF32349C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Treino de Pronúncia em Inglês',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ouça, repita e compare sua voz em tempo real.',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _buildBannerPill(Icons.check_circle_outline, '${_stats.sentencesToday} hoje'),
                            const SizedBox(width: 10),
                            _buildBannerPill(
                              Icons.speed,
                              '${_stats.accuracyAvg > 0 ? _stats.accuracyAvg.round() : 0}% precisão',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.edit_note,
                          title: 'Digitar Frase',
                          subtitle: 'Treine qualquer frase livre',
                          color: AppTheme.primary,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => const PracticeScreen(
                                  initialCustomMode: true,
                                ),
                              ),
                            );
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.headphones,
                          title: 'Catálogo',
                          subtitle: '20 frases fonéticas',
                          color: AppTheme.success,
                          onTap: () => _openPracticeWithExercise(exerciseCatalog.first),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Conversação Livre com Emma
                  Card(
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => const FreeSpeakingScreen(),
                          ),
                        );
                        _loadData();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primaryContainer,
                                  child: Text(
                                    'E',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.successContainer,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'CONVERSAÇÃO IA',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.success,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Emma • Nativo US',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Café em Manhattan',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppTheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    size: 16,
                                    color: Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Simulação realista: faça seu pedido, escolha o leite e converse espontaneamente.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (_customPhrases.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Minhas Frases Salvas',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${_customPhrases.length}/20',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._customPhrases.map((phrase) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            phrase,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Color(0xFF94A3B8),
                                ),
                                tooltip: 'Remover frase',
                                onPressed: () async {
                                  await _storageService.removeCustomPhrase(phrase);
                                  _loadData();
                                },
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14),
                            ],
                          ),
                          onTap: () => _openPracticeWithCustomPhrase(phrase),
                        ),
                      );
                    }),
                    const SizedBox(height: 18),
                  ],

                  // Revisão de Dificuldades (Smart Revision)
                  _buildReviewSection(),
                  const SizedBox(height: 24),

                  // Exercise Catalog preview
                  Builder(builder: (context) {
                    final filteredCatalog = _selectedDifficulty == null
                        ? exerciseCatalog
                        : exerciseCatalog
                            .where((e) => e.difficulty == _selectedDifficulty)
                            .toList();

                    final displayedItems = _showAllCatalog
                        ? filteredCatalog
                        : filteredCatalog.take(5).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Frases para Praticar',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${filteredCatalog.length} frases',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Difficulty Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Todas'),
                                selected: _selectedDifficulty == null,
                                onSelected: (_) =>
                                    setState(() => _selectedDifficulty = null),
                              ),
                              const SizedBox(width: 8),
                              ...Difficulty.values.map((diff) {
                                final count = exerciseCatalog
                                    .where((e) => e.difficulty == diff)
                                    .length;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text('${diff.label} ($count)'),
                                    selected: _selectedDifficulty == diff,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedDifficulty =
                                            selected ? diff : null;
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...displayedItems.map((ex) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.mic,
                                    color: AppTheme.primary, size: 20),
                              ),
                              title: Text(
                                ex.sentence,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                ex.phoneticIpa,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ex.difficulty.label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              onTap: () => _openPracticeWithExercise(ex),
                            ),
                          );
                        }),

                        if (filteredCatalog.length > 5) ...[
                          const SizedBox(height: 4),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showAllCatalog = !_showAllCatalog;
                                });
                              },
                              icon: Icon(_showAllCatalog
                                  ? Icons.expand_less
                                  : Icons.expand_more),
                              label: Text(_showAllCatalog
                                  ? 'Mostrar menos'
                                  : 'Ver todas as ${filteredCatalog.length} frases'),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildBannerPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSection() {
    if (!_recommendation.hasData) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        color: const Color(0xFFF8FAFC),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.spellcheck,
                    color: Color(0xFF64748B), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revisão de Dificuldades',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pratique para ver suas dificuldades e fonemas a calibrar.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () =>
                    _openPracticeWithExercise(exerciseCatalog.first),
                child: const Text('Praticar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendation.reviewWord != null ||
        _recommendation.reviewPhoneme != null) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFDE68A)),
        ),
        color: const Color(0xFFFFFBEB),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.spellcheck,
                    color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revisão de Dificuldades',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (_recommendation.reviewWord != null)
                      Text(
                        'Palavra foco: "${_recommendation.reviewWord}" (${_recommendation.count}x)',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    if (_recommendation.reviewPhoneme != null)
                      Text(
                        'Som fonético: ${_recommendation.reviewPhoneme}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () =>
                    _openPracticeForReview(_recommendation.targetExerciseId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Treinar'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFA7F3D0)),
      ),
      color: const Color(0xFFECFDF5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.verified, color: AppTheme.success, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revisão de Dificuldades',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Nenhuma dificuldade recente! Dicção excelente em todas as tentativas.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () =>
                  _openPracticeWithExercise(exerciseCatalog.first),
              child: const Text('Praticar'),
            ),
          ],
        ),
      ),
    );
  }
}
