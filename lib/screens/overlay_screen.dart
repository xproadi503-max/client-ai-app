import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  String _clientMessage = '';
  List<String> _suggestions = [];
  bool _expanded = true;
  int _copiedIndex = -1;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null && data is Map) {
        setState(() {
          _clientMessage = data['message']?.toString() ?? '';
          final rawList = data['suggestions'];
          if (rawList is List) {
            _suggestions = rawList.map((e) => e.toString()).toList();
          }
        });
      }
    });
  }

  void _copyAndClose(String text, int index) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedIndex = index);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _copiedIndex = -1);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1730).withOpacity(0.97),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: 1,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                      bottomLeft:
                          Radius.circular(_expanded ? 0 : 14),
                      bottomRight:
                          Radius.circular(_expanded ? 0 : 14),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('💬',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      const Text('Client AI',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      const Spacer(),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => FlutterOverlayWindow.closeOverlay(),
                        child: const Icon(Icons.close,
                            color: Colors.white70, size: 18),
                      ),
                    ],
                  ),
                ),
              ),

              if (_expanded) ...[
                // Client message
                if (_clientMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📨 "$_clientMessage"',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Suggestions
                if (_suggestions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'WhatsApp/Telegram open karo\nAI automatically reply suggest karega ✨',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...(_suggestions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final reply = entry.value;
                    return GestureDetector(
                      onTap: () => _copyAndClose(reply, i),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _copiedIndex == i
                              ? const Color(0xFF065F46).withOpacity(0.4)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _copiedIndex == i
                                ? const Color(0xFF34D399).withOpacity(0.5)
                                : Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                reply,
                                style: const TextStyle(
                                    color: Color(0xFFE5E7EB),
                                    fontSize: 11,
                                    height: 1.4),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _copiedIndex == i
                                  ? Icons.check_circle
                                  : Icons.copy,
                              color: _copiedIndex == i
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFA78BFA),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  })),

                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
