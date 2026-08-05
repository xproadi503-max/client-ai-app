import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/accessibility_service.dart';
import '../services/groq_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _overlayActive = false;
  bool _accessibilityEnabled = false;
  bool _overlayPermission = false;
  String _lastMessage = '';
  String _activeApp = '';
  List<String> _suggestions = [];
  bool _loading = false;

  // Manual test input
  final TextEditingController _manualController = TextEditingController();
  String _selectedBusiness = 'App Development';
  String _selectedTone = 'Professional';
  String _selectedLang = 'Hinglish';

  final List<String> _businesses = [
    'App Development',
    'Video Editing',
    'Web Development',
    'Graphic Design',
    'Social Media',
    'SEO / Marketing',
    'Photography',
    'Content Writing',
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _listenToMessages();
  }

  void _listenToMessages() {
    AccessibilityService.messageStream.listen((data) {
      setState(() {
        _lastMessage = data['message'] ?? '';
        _activeApp = data['app'] ?? '';
      });
      _autoGenerateSuggestions(data['message'] ?? '');
    });
  }

  Future<void> _autoGenerateSuggestions(String message) async {
    if (message.isEmpty) return;
    setState(() => _loading = true);
    try {
      final replies = await GroqService.generateReplies(
        clientMessage: message,
        businessType: _selectedBusiness,
        tone: _selectedTone,
        language: _selectedLang,
      );
      setState(() => _suggestions = replies);

      // Send to overlay
      if (_overlayActive) {
        await FlutterOverlayWindow.shareData({
          'message': message,
          'suggestions': replies,
          'app': _activeApp,
        });
      }
    } catch (e) {
      _showSnack('Error: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkPermissions() async {
    final accessibility = await AccessibilityService.isAccessibilityEnabled();
    final overlay = await FlutterOverlayWindow.isPermissionGranted();
    setState(() {
      _accessibilityEnabled = accessibility;
      _overlayPermission = overlay ?? false;
    });
  }

  Future<void> _requestOverlayPermission() async {
    await FlutterOverlayWindow.requestPermission();
    await _checkPermissions();
  }

  Future<void> _toggleOverlay() async {
    if (!_overlayPermission) {
      await _requestOverlayPermission();
      return;
    }

    if (_overlayActive) {
      await FlutterOverlayWindow.closeOverlay();
      setState(() => _overlayActive = false);
    } else {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: 'Client AI',
        overlayContent: 'AI Reply Assistant Active',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 420,
        width: 340,
      );
      setState(() => _overlayActive = true);
    }
  }

  Future<void> _manualGenerate() async {
    final msg = _manualController.text.trim();
    if (msg.isEmpty) {
      _showSnack('Message likho pehle!');
      return;
    }
    await _autoGenerateSuggestions(msg);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Text('💬', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Client AI',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Cards
            _buildStatusSection(),
            const SizedBox(height: 20),

            // Overlay Toggle
            _buildOverlayToggle(),
            const SizedBox(height: 20),

            // Settings Row
            _buildSettingsRow(),
            const SizedBox(height: 20),

            // Manual Input
            _buildManualInput(),
            const SizedBox(height: 20),

            // Live Detection
            if (_lastMessage.isNotEmpty) _buildLiveDetection(),

            // Suggestions
            if (_suggestions.isNotEmpty) _buildSuggestions(),

            // Loading
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Row(
      children: [
        Expanded(child: _statusCard('Accessibility', _accessibilityEnabled,
            onTap: () => AccessibilityService.openAccessibilitySettings())),
        const SizedBox(width: 10),
        Expanded(child: _statusCard('Overlay', _overlayPermission,
            onTap: _requestOverlayPermission)),
      ],
    );
  }

  Widget _statusCard(String label, bool enabled, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: enabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF065F46).withOpacity(0.4)
              : const Color(0xFF7F1D1D).withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? const Color(0xFF34D399).withOpacity(0.4)
                : const Color(0xFFF87171).withOpacity(0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(enabled ? '✅' : '❌', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(enabled ? 'Active' : 'Tap to enable',
                style: TextStyle(
                    color: enabled
                        ? const Color(0xFF34D399)
                        : const Color(0xFFF87171),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayToggle() {
    return GestureDetector(
      onTap: _toggleOverlay,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _overlayActive
                ? [const Color(0xFF7C3AED), const Color(0xFFA78BFA)]
                : [const Color(0xFF1F1B4B), const Color(0xFF2D2860)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _overlayActive
              ? [
                  BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2)
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _overlayActive ? '🟢 Overlay Active' : '⚫ Overlay Off',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16),
                ),
                Text(
                  _overlayActive
                      ? 'WhatsApp/Telegram ke upar dikh raha hai'
                      : 'Tap karo activate karne ke liye',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            Switch(
              value: _overlayActive,
              onChanged: (_) => _toggleOverlay(),
              activeColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow() {
    return Column(
      children: [
        _dropdownRow('💼 Business', _selectedBusiness, _businesses,
            (v) => setState(() => _selectedBusiness = v!)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _dropdownRow(
                  '🎭 Tone',
                  _selectedTone,
                  ['Professional', 'Friendly', 'Urgent', 'Confident'],
                  (v) => setState(() => _selectedTone = v!)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dropdownRow(
                  '🌐 Lang',
                  _selectedLang,
                  ['Hinglish', 'English', 'Hindi'],
                  (v) => setState(() => _selectedLang = v!)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dropdownRow(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1F1B4B),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          hint: Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildManualInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('✍️ Manual Test',
            style: TextStyle(
                color: Color(0xFFC4B5FD),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _manualController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Client ka message paste karo ya type karo...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C3AED)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _manualGenerate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _loading ? '⏳ Generate ho raha hai...' : '✨ Reply Generate Karo',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveDetection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📨 Live Detection',
                  style: TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(_activeApp,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(_lastMessage,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('💡 Suggested Replies',
            style: TextStyle(
                color: Color(0xFFC4B5FD),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ..._suggestions.asMap().entries.map((e) => _suggestionCard(e.key, e.value)),
      ],
    );
  }

  Widget _suggestionCard(int index, String reply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Option ${index + 1}',
              style: const TextStyle(
                  color: Color(0xFFA78BFA),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(reply,
              style:
                  const TextStyle(color: Color(0xFFE5E7EB), fontSize: 13, height: 1.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  // Copy to clipboard
                  _showSnack('Copied! ✅');
                },
                icon: const Icon(Icons.copy, size: 14, color: Color(0xFFA78BFA)),
                label: const Text('Copy',
                    style: TextStyle(color: Color(0xFFA78BFA), fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
