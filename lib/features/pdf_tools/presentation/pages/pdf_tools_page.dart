import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/pdf_provider.dart';
import '../../models/presentation_slide.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/login_prompt_dialog.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Route: /pdf-tools
class PdfToolsPage extends StatefulWidget {
  const PdfToolsPage({super.key});

  @override
  State<PdfToolsPage> createState() => _PdfToolsPageState();
}

class _PdfToolsPageState extends State<PdfToolsPage> {
  int _currentSlideIndex = 0;

  void _checkGuestGuard(VoidCallback onAuthorized) {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      LoginPromptDialog.show(
        context,
        featureName: 'PDF & Presentation Tools',
        customMessage: 'Guest users cannot generate or convert documents. Please sign in to unlock all PDF & PPT tools!',
      );
      return;
    }
    onAuthorized();
  }

  // 1. Images to PDF Modal
  void _openImagesToPdfDialog() {
    _checkGuestGuard(() async {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: true,
        withData: true,
      );

      if (res == null || res.files.isEmpty) return;
      if (!mounted) return;

      final titleCtrl = TextEditingController(text: 'StudyNotes_Images');

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
            title: Text('Convert ${res.files.length} Images to PDF', style: AppTextStyles.headlineSmall),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${res.files.length} images selected ready for conversion.', style: AppTextStyles.bodySmall),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Document Name',
                    prefixIcon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Format: Standard A4 • Fits each image per page', style: AppTextStyles.caption),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<PdfProvider>().convertImagesToPdf(
                    files: res.files,
                    documentTitle: titleCtrl.text.trim(),
                  );
                },
                child: const Text('Generate & Download PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    });
  }

  // 2. Notes to PDF Modal
  void _openNotesToPdfDialog() {
    _checkGuestGuard(() {
      final titleCtrl = TextEditingController(text: 'Physics Chapter 4 Summary');
      final subjectCtrl = TextEditingController(text: 'Physics');
      final contentCtrl = TextEditingController(
        text: 'Newton\'s Third Law states that for every action, there is an equal and opposite reaction.\n\n'
            'Key Formula:\nF(A on B) = -F(B on A)\n\n'
            'Important Applications:\n'
            '1. Rocket Propulsion: Exhaust gases pushed downward produce upward thrust.\n'
            '2. Walking: Pushing feet backward against the ground generates forward reaction force.\n'
            '3. Recoil of Guns: Bullet accelerated forward generates backward force on gun body.',
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Create Formatted Study Notes PDF', style: AppTextStyles.headlineSmall),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Document Title',
                  prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subjectCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Subject / Course Tag',
                  prefixIcon: const Icon(Icons.bookmark_border_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentCtrl,
                maxLines: 6,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Notes Content (Paragraphs & Formulas)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  label: const Text('Export Formatted PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    await context.read<PdfProvider>().generateNotesPdf(
                      title: titleCtrl.text.trim(),
                      subject: subjectCtrl.text.trim(),
                      notesContent: contentCtrl.text.trim(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // 3. AI Presentation / PPT Generator Modal
  void _openAiPresentationDialog() {
    _checkGuestGuard(() {
      final topicCtrl = TextEditingController(text: 'Quantum Mechanics Basics');

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
          title: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text('AI Presentation Maker', style: AppTextStyles.headlineSmall),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter any academic topic or paste your notes. Gemini AI will generate a 5-slide visual presentation deck with bullet points & speaker notes!', style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),
              TextField(
                controller: topicCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Presentation Topic',
                  hintText: 'e.g., Photosynthesis, Binary Search Trees',
                  prefixIcon: const Icon(Icons.slideshow_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final topic = topicCtrl.text.trim();
                if (topic.isEmpty) return;
                Navigator.pop(ctx);
                setState(() => _currentSlideIndex = 0);
                await context.read<PdfProvider>().generatePresentation(topic);
              },
              child: const Text('Generate Slides', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }

  // 4. Extract text from PDF
  void _openPdfExtractDialog() {
    _checkGuestGuard(() async {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (res == null || res.files.isEmpty) return;
      if (!mounted) return;
      await context.read<PdfProvider>().extractTextFromPdf(res.files.first);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pdf = context.watch<PdfProvider>();

    return AdaptiveScaffold(
      selectedIndex: 6,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('PDF & Presentation Suite', style: AppTextStyles.headlineSmall),
          actions: [
            if (pdf.status != PdfJobStatus.idle)
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
                tooltip: 'Reset',
                onPressed: () => context.read<PdfProvider>().reset(),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Guest mode banner
              if (auth.isGuest)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PDF & Presentation tools require sign in.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => LoginPromptDialog.show(
                          context,
                          featureName: 'PDF & Document Tools',
                          customMessage: 'Sign in to generate, convert, extract, and export PDFs and presentations!',
                        ),
                        child: Text(
                          'Sign In',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Success / Status Banner
              if (pdf.status == PdfJobStatus.processing)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Processing document with high precision...',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )
              else if (pdf.successMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(pdf.successMessage!, style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600))),
                    ],
                  ),
                )
              else if (pdf.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(pdf.error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                    ],
                  ),
                ),

              // Interactive AI Presentation Slide Deck Viewer (when generated)
              if (pdf.generatedSlides.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Presentation: ${pdf.currentPresentationTopic}', style: AppTextStyles.headlineSmall),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                      label: const Text('Export PDF Deck', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => pdf.exportPresentationToPdf(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SlideViewerCard(
                  slide: pdf.generatedSlides[_currentSlideIndex],
                  currentIndex: _currentSlideIndex,
                  totalSlides: pdf.generatedSlides.length,
                  onPrev: _currentSlideIndex > 0 ? () => setState(() => _currentSlideIndex--) : null,
                  onNext: _currentSlideIndex < pdf.generatedSlides.length - 1 ? () => setState(() => _currentSlideIndex++) : null,
                ),
                const SizedBox(height: 28),
              ],

              // Extracted Text View
              if (pdf.extractedText != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Extracted Document Content', style: AppTextStyles.headlineSmall),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: pdf.extractedText!));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Extracted text copied to clipboard!')));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    pdf.extractedText!,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Document Suite Tools Grid
              Text('Document Creation & Conversion', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 6),
              Text('Instant creation, conversion, extraction, and slide generation.', style: AppTextStyles.bodySmall),
              const SizedBox(height: 18),

              LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = constraints.maxWidth > 700 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: crossCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: crossCount == 2 ? 1.6 : 1.8,
                    children: [
                      _ActiveToolCard(
                        icon: '📸',
                        title: 'Images → PDF',
                        description: 'Select photos or diagrams and assemble them into a clean, multi-page PDF document.',
                        buttonLabel: 'Select Images',
                        isLocked: auth.isGuest,
                        gradientColors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                        onTap: _openImagesToPdfDialog,
                      ),
                      _ActiveToolCard(
                        icon: '📝',
                        title: 'Notes → Formatted PDF',
                        description: 'Type or paste your study notes, formulas, and headings to generate a formatted PDF.',
                        buttonLabel: 'Create Notes PDF',
                        isLocked: auth.isGuest,
                        gradientColors: [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
                        onTap: _openNotesToPdfDialog,
                      ),
                      _ActiveToolCard(
                        icon: '📊',
                        title: 'AI Presentation (PPT) Maker',
                        description: 'Enter any topic and AI generates a 5-slide visual presentation deck downloadable as PDF.',
                        buttonLabel: 'Generate Slide Deck',
                        isLocked: auth.isGuest,
                        gradientColors: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
                        onTap: _openAiPresentationDialog,
                      ),
                      _ActiveToolCard(
                        icon: '📄',
                        title: 'PDF → Text & Notes',
                        description: 'Extract raw text, paragraphs, and formulas from any PDF to copy or study.',
                        buttonLabel: 'Extract from PDF',
                        isLocked: auth.isGuest,
                        gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
                        onTap: _openPdfExtractDialog,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveToolCard extends StatelessWidget {
  final String icon, title, description, buttonLabel;
  final List<Color> gradientColors;
  final bool isLocked;
  final VoidCallback onTap;

  const _ActiveToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.gradientColors,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gradientColors.first.withValues(alpha: 0.3)),
          gradient: LinearGradient(
            colors: [
              gradientColors.first.withValues(alpha: 0.12),
              gradientColors.last.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold))),
                          if (isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_rounded, size: 12, color: AppColors.warning),
                                  SizedBox(width: 4),
                                  Text('Sign-in', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(description, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isLocked ? null : LinearGradient(colors: gradientColors),
                  color: isLocked ? AppColors.card : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLocked ? 'Locked (Sign In)' : buttonLabel,
                      style: TextStyle(
                        color: isLocked ? AppColors.textMuted : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isLocked ? Icons.lock_outline_rounded : Icons.arrow_forward_rounded,
                      size: 14,
                      color: isLocked ? AppColors.textMuted : Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideViewerCard extends StatelessWidget {
  final PresentationSlide slide;
  final int currentIndex;
  final int totalSlides;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _SlideViewerCard({
    required this.slide,
    required this.currentIndex,
    required this.totalSlides,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slide Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('Slide ${currentIndex + 1} of $totalSlides', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white70),
                    onPressed: onPrev,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white70),
                    onPressed: onNext,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            slide.title,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (slide.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(slide.subtitle!, style: const TextStyle(color: AppColors.accent, fontSize: 13)),
          ],
          const SizedBox(height: 16),

          // Bullet points
          ...slide.bulletPoints.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 10),
                      child: Icon(Icons.circle, size: 8, color: AppColors.primary),
                    ),
                    Expanded(
                      child: Text(point, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                    ),
                  ],
                ),
              )),

          if (slide.note != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '💡 Speaker Note: ${slide.note}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
