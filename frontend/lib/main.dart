import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roast My Resume',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const RoastPage(),
    );
  }
}

class RoastPage extends StatefulWidget {
  const RoastPage({super.key});

  @override
  State<RoastPage> createState() => _RoastPageState();
}

class _RoastPageState extends State<RoastPage> with SingleTickerProviderStateMixin {
  String _selectedMode = AppConfig.modeNormal;
  Map<String, dynamic>? _roastResult;
  String? _resultId;
  bool _isLoading = false;
  String? _fileName;
  int _totalRoasted = 0;
  final TextEditingController _targetRoleController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _loadStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _targetRoleController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final res = await http.get(Uri.parse(AppConfig.statsUrl));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          setState(() => _totalRoasted = data['total_roasted'] ?? 0);
        }
      }
    } catch (_) {}
  }

  Future<void> _pickAndRoastResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;

    setState(() {
      _isLoading = true;
      _fileName = result.files.single.name;
      _roastResult = null;
      _resultId = null;
      _animationController.reset();
    });

    try {
      final bytes = result.files.single.bytes;
      if (bytes == null) throw Exception('Could not read file');

      final targetRole = _selectedMode == AppConfig.modeRecruiter
          ? _targetRoleController.text.trim()
          : null;
      final uri = Uri.parse(AppConfig.roastUrl(_selectedMode, targetRole: targetRole));
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: result.files.single.name,
      ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _roastResult = data['result'];
          _resultId = data['id'];
          _totalRoasted += 1;
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        final err = json.decode(response.body);
        throw Exception(err['detail'] ?? 'Server error ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red[700]),
        );
      }
    }
  }

  void _copyRoast() {
    final roast = _roastResult?['roast'] ?? '';
    Clipboard.setData(ClipboardData(text: roast));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Roast copied to clipboard!'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFFFF6B35),
      ),
    );
  }

  void _shareResult() {
    if (_resultId == null) return;
    final link = '${AppConfig.baseUrl}/result/$_resultId';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied! Share it with a friend.'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFFFF6B35),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B35), Color(0xFFF7931E), Color(0xFFFDC830)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (_totalRoasted > 0) _buildStatsCounter(),
                  const SizedBox(height: 24),
                  _buildModeSelector(),
                  if (_selectedMode == AppConfig.modeRecruiter) ...[
                    const SizedBox(height: 20),
                    _buildTargetRoleInput(),
                  ],
                  const SizedBox(height: 32),
                  _buildUploadButton(),
                  if (_fileName != null) ...[
                    const SizedBox(height: 16),
                    _buildFileChip(),
                  ],
                  const SizedBox(height: 32),
                  if (_isLoading)
                    _buildLoadingCard()
                  else if (_roastResult != null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildResultCard(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: const Column(
        children: [
          Text('🔥', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text(
            'Roast My Resume',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
          ),
          SizedBox(height: 8),
          Text(
            'Get brutally roasted by AI',
            style: TextStyle(fontSize: 16, color: Colors.black54, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$_totalRoasted resumes roasted and counting',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AppConfig.modeLabels.entries.map((entry) {
          final selected = _selectedMode == entry.key;
          return GestureDetector(
            onTap: () => setState(() => _selectedMode = entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: selected
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  color: selected ? const Color(0xFFFF6B35) : Colors.white,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTargetRoleInput() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _targetRoleController,
        decoration: const InputDecoration(
          hintText: 'Target role — e.g. Product Manager, SDE-2 (optional)',
          hintStyle: TextStyle(fontSize: 14, color: Colors.black38),
          border: InputBorder.none,
          icon: Icon(Icons.work_outline, color: Color(0xFFFF6B35), size: 20),
        ),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _isLoading ? null : _pickAndRoastResume,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isLoading
                  ? [Colors.grey[400]!, Colors.grey[400]!]
                  : [const Color(0xFFFF6B35), const Color(0xFFFF8E53)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.upload_file, color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Text(
                _isLoading ? 'Roasting...' : 'Upload Resume',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description, color: Color(0xFFFF6B35), size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _fileName!,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
          ),
          SizedBox(height: 20),
          Text('AI is cooking up your roast...', style: TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _roastResult!;
    final score = result['score'] as int;
    final grade = result['grade'] as String;
    final summary = result['summary'] as String;
    final roast = result['roast'] as String;
    final verdict = result['verdict'] as String;
    final sections = result['sections'] as Map<String, dynamic>;

    return Container(
      constraints: const BoxConstraints(maxWidth: 720),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3EE),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your Roast — ${AppConfig.modeLabels[_selectedMode]} Mode',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                  ),
                ),
                _buildScoreBadge(score, grade),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                Text(summary, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6)),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 20),

                // Main roast
                const Text('The Roast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                SelectableText(roast, style: const TextStyle(fontSize: 16, height: 1.7, color: Colors.black87)),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 20),

                // Section scores
                const Text('Section Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 14),
                ...['experience', 'skills', 'education', 'presentation'].map((key) {
                  final s = sections[key] as Map<String, dynamic>;
                  return _buildSectionRow(key, s['score'] as int, s['comment'] as String);
                }),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Verdict
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"$verdict"',
                    style: const TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFFF6B35),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Recruiter-only sections
                if (_selectedMode == AppConfig.modeRecruiter) ...[
                  _buildRecruiterSections(result),
                  const SizedBox(height: 24),
                ],

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyRoast,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy Roast'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF6B35),
                          side: const BorderSide(color: Color(0xFFFF6B35)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareResult,
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share Link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecruiterSections(Map<String, dynamic> result) {
    final level = result['candidate_level'] as String?;
    final targetRole = result['detected_target_role'] as String?;
    final fitAssessment = result['role_fit_assessment'] as String?;
    final tips = (result['tips'] as List<dynamic>?)?.cast<String>();
    final suggestions = result['role_suggestions'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),

        // Candidate level + detected role
        if (level != null || targetRole != null) ...[
          Row(
            children: [
              if (level != null)
                _buildLevelChip(level),
              if (level != null && targetRole != null)
                const SizedBox(width: 10),
              if (targetRole != null)
                Expanded(
                  child: Text(
                    'Targeting: $targetRole',
                    style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],

        // Role fit assessment
        if (fitAssessment != null) ...[
          const Text('Fit Assessment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(fitAssessment, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6)),
          const SizedBox(height: 20),
        ],

        // Tips
        if (tips != null && tips.isNotEmpty) ...[
          const Text('What to Fix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          ...tips.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 10, top: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(e.value, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 20),
        ],

        // Role suggestions
        if (suggestions != null && suggestions.isNotEmpty) ...[
          const Text('You Might Also Fit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          ...suggestions.map((s) {
            final suggestion = s as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFFFF6B35)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion['role'] as String,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          suggestion['reason'] as String,
                          style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildLevelChip(String level) {
    final colors = {
      'junior': const Color(0xFF1565C0),
      'mid': const Color(0xFF2E7D32),
      'senior': const Color(0xFF6A1B9A),
    };
    final color = colors[level.toLowerCase()] ?? Colors.grey[700]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        level[0].toUpperCase() + level.substring(1),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildScoreBadge(int score, String grade) {
    final color = score >= 70
        ? Colors.green[700]!
        : score >= 50
            ? Colors.orange[700]!
            : Colors.red[700]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text('$score/100', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(grade, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildSectionRow(String key, int score, String comment) {
    final label = key[0].toUpperCase() + key.substring(1);
    final color = score >= 70
        ? const Color(0xFF2E7D32)
        : score >= 50
            ? const Color(0xFFE65100)
            : const Color(0xFFC62828);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 32,
                child: Text('$score', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 100),
            child: Text(comment, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
