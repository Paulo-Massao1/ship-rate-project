import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../controllers/suggestion_controller.dart';

/// Screen for submitting user suggestions and feedback.
///
/// Allows users to send:
/// - Suggestions for improvements
/// - Complaints about issues
/// - Compliments and positive feedback
class SuggestionPage extends StatefulWidget {
  const SuggestionPage({super.key});

  @override
  State<SuggestionPage> createState() => _SuggestionPageState();
}

class _SuggestionPageState extends State<SuggestionPage> {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const _feedbackTypes = [
    _FeedbackType(
      value: 'Sugestão',
      icon: Icons.lightbulb_outline,
      label: 'Sugestão',
    ),
    _FeedbackType(
      value: 'Crítica',
      icon: Icons.feedback_outlined,
      label: 'Crítica',
    ),
    _FeedbackType(
      value: 'Elogio',
      icon: Icons.favorite_outline,
      label: 'Elogio',
    ),
  ];

  // ===========================================================================
  // CONTROLLER & STATE
  // ===========================================================================

  final _controller = SuggestionController();
  final _messageController = TextEditingController();

  String _selectedType = 'Sugestão';
  bool _isLoading = false;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _submitSuggestion() async {
    final message = _messageController.text;

    // Validate using controller
    final validationError = _controller.validateMessage(message);
    if (validationError != null) {
      _showSnackBar(validationError, backgroundColor: Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    // Submit using controller
    final success = await _controller.submitSuggestion(
      type: _selectedType,
      message: message,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      _showSnackBar(l10n.messageSentSuccess, backgroundColor: Colors.green);
      Navigator.pop(context);
    } else {
      _showSnackBar(l10n.errorSendingMessage, backgroundColor: Colors.red);
    }
  }

  void _showSnackBar(String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  String _feedbackLabel(String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'Sugestão': return l10n.suggestionType;
      case 'Crítica': return l10n.complaintType;
      case 'Elogio': return l10n.complimentType;
      default: return value;
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.sendSuggestionTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFeedbackTypeDropdown(),
            const SizedBox(height: 16),
            _buildMessageField(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.yourOpinionMatters,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.helpImproveApp,
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildFeedbackTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: _feedbackTypes
              .map((type) => DropdownMenuItem(
                    value: type.value,
                    child: Row(
                      children: [
                        Icon(type.icon, size: 20),
                        const SizedBox(width: 12),
                        Text(_feedbackLabel(type.value)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedType = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMessageField() {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _messageController,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: l10n.messageLabel,
        prefixIcon: const Icon(Icons.message_outlined),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitSuggestion,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                l10n.sendButton,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

// =============================================================================
// PRIVATE DATA CLASS
// =============================================================================

class _FeedbackType {
  final String value;
  final IconData icon;
  final String label;

  const _FeedbackType({
    required this.value,
    required this.icon,
    required this.label,
  });
}
