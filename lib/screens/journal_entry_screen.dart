import 'package:flutter/material.dart';
import 'dart:ui';

class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveEntry() {
    // TODO: Save entry to storage
    Navigator.pop(context);
  }

  void _goBack() {
    Navigator.pop(context);
  }

  void _insertBulletPoint() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final newText = text.substring(0, selection.start) + '• ' + text.substring(selection.end);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: const Color(0xFF0E0E0E).withOpacity(0.7),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.pop(context),
                color: const Color(0xFFF3F3F3),
              ),
              actions: [
                TextButton(
                  onPressed: _saveEntry,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Color(0xFF4EF4C0),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Full-screen text area
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 80,
                left: 20,
                right: 20,
                bottom: 80,
              ),
              child: TextField(
                controller: _contentController,
                focusNode: _focusNode,
                autofocus: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  color: Color(0xFFF3F3F3),
                  fontSize: 17,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.3,
                ),
                decoration: const InputDecoration(
                  hintText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Color(0xFF0E0E0E),
                ),
                cursorColor: const Color(0xFF4EF4C0),
                cursorWidth: 2,
                scrollPhysics: const BouncingScrollPhysics(),
              ),
            ),
          ),

          // Floating toolbar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0E0E0E).withOpacity(0.95),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildToolbarIcon(Icons.list, _insertBulletPoint),
                  _buildToolbarIcon(Icons.format_bold, () {}),
                  _buildToolbarIcon(Icons.camera_alt_outlined, () {}),
                  _buildToolbarIcon(Icons.flag_outlined, () {}),
                  _buildToolbarIcon(Icons.mic_none_outlined, () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: const Color(0xFFF3F3F3).withOpacity(0.7),
            size: 26,
          ),
        ),
      ),
    );
  }
}
