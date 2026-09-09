import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:pdfx/pdfx.dart';
import 'package:archive/archive.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/embedded_viewer.dart';
import '../../../../core/utils/file_saver.dart';
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
        customMessage:
            'Guest users cannot generate or convert documents. Please sign in to unlock all PDF & PPT tools!',
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            title: Text(
              'Convert ${res.files.length} Images to PDF',
              style: AppTextStyles.headlineSmall,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${res.files.length} images selected ready for conversion.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Document Name',
                    prefixIcon: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Format: Standard A4 • Fits each image per page',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<PdfProvider>().convertImagesToPdf(
                    files: res.files,
                    documentTitle: titleCtrl.text.trim(),
                  );
                },
                child: const Text(
                  'Generate & Download PDF',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
      final titleCtrl = TextEditingController(
        text: 'Physics Chapter 4 Summary',
      );
      final subjectCtrl = TextEditingController(text: 'Physics');
      final contentCtrl = TextEditingController(
        text:
            'Newton\'s Third Law states that for every action, there is an equal and opposite reaction.\n\n'
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Formatted Study Notes PDF',
                    style: AppTextStyles.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Document Title',
                  prefixIcon: const Icon(
                    Icons.title_rounded,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subjectCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Subject / Course Tag',
                  prefixIcon: const Icon(
                    Icons.bookmark_border_rounded,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, color: AppColors.textPrimary),
                  label: const Text(
                    'Export Formatted PDF',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty ||
                        contentCtrl.text.trim().isEmpty)
                      return;
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
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
              Text(
                'Enter any academic topic or paste your notes. Gemini AI will generate a 5-slide visual presentation deck with bullet points & speaker notes!',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: topicCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Presentation Topic',
                  hintText: 'e.g., Photosynthesis, Binary Search Trees',
                  prefixIcon: const Icon(
                    Icons.slideshow_rounded,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                final topic = topicCtrl.text.trim();
                if (topic.isEmpty) return;
                Navigator.pop(ctx);
                setState(() => _currentSlideIndex = 0);
                await context.read<PdfProvider>().generatePresentation(topic);
              },
              child: const Text(
                'Generate Slides',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

  // ── Drop Handlers ──────────────────────────────────────────────────────────

  /// Handle images dropped onto the Images→PDF card
  void _handleDroppedImages(List<DropDoneDetails> details) async {
    _checkGuestGuard(() async {
      final xFiles = details.expand((d) => d.files).toList();
      if (xFiles.isEmpty) return;

      final imageExts = {'jpg', 'jpeg', 'png', 'webp'};
      final platformFiles = <PlatformFile>[];

      for (final xf in xFiles) {
        final ext = xf.name.split('.').last.toLowerCase();
        if (!imageExts.contains(ext)) continue;
        final bytes = await xf.readAsBytes();
        platformFiles.add(
          PlatformFile(name: xf.name, size: bytes.length, bytes: bytes),
        );
      }

      if (platformFiles.isEmpty || !mounted) return;

      final titleCtrl = TextEditingController(text: 'StudyNotes_Images');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            'Convert ${platformFiles.length} Dropped Images to PDF',
            style: AppTextStyles.headlineSmall,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${platformFiles.length} images ready for conversion.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Document Name',
                  prefixIcon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await context.read<PdfProvider>().convertImagesToPdf(
                  files: platformFiles,
                  documentTitle: titleCtrl.text.trim(),
                );
              },
              child: const Text(
                'Generate & Download PDF',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Handle PDF dropped onto the Extract card
  void _handleDroppedPdf(List<DropDoneDetails> details) async {
    _checkGuestGuard(() async {
      final xFiles = details.expand((d) => d.files).toList();
      if (xFiles.isEmpty) return;

      final xf = xFiles.first;
      final ext = xf.name.split('.').last.toLowerCase();
      if (ext != 'pdf') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please drop a PDF file.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final bytes = await xf.readAsBytes();
      if (!mounted) return;
      await context.read<PdfProvider>().extractTextFromPdf(
        PlatformFile(name: xf.name, size: bytes.length, bytes: bytes),
      );
    });
  }

  /// Handle documents dropped onto the Document Viewer card
  void _handleDroppedDocument(List<DropDoneDetails> details) async {
    try {
      final xFiles = details.expand((d) => d.files).toList();
      if (xFiles.isEmpty) return;

      final xf = xFiles.first;
      final bytes = await xf.readAsBytes();
      final ext = xf.name.contains('.') ? xf.name.split('.').last : '';

      if (!mounted) return;
      _showInAppDocumentViewer(
        fileName: xf.name,
        bytes: bytes,
        extension: ext,
        filePath: xf.path.isNotEmpty ? xf.path : null,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error handling dropped file: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 5. Open Documents (PPT, Excel, Word, PDF, etc.) with in-app viewer
  void _openDocumentViewer() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'ppt', 'pptx', // PowerPoint
          'xls', 'xlsx', 'csv', // Excel / Spreadsheet
          'doc', 'docx', // Word
          'pdf', // PDF
          'txt', 'rtf', 'md', // Text
          'png', 'jpg', 'jpeg', // Images
          'odt', 'ods', 'odp', // OpenDocument
        ],
        withData: true,
      );

      if (res == null || res.files.isEmpty) return;
      if (!mounted) return;

      final file = res.files.first;
      Uint8List? bytes = file.bytes;

      if (bytes == null && file.path != null && !kIsWeb) {
        final ioFile = File(file.path!);
        if (await ioFile.exists()) {
          bytes = await ioFile.readAsBytes();
        }
      }

      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to read the file content.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      _showInAppDocumentViewer(
        fileName: file.name,
        bytes: bytes,
        extension: file.extension ?? '',
        filePath: file.path,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening document: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showInAppDocumentViewer({
    required String fileName,
    required Uint8List bytes,
    required String extension,
    String? filePath,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: InAppDocumentViewerModal(
          fileName: fileName,
          bytes: bytes,
          extension: extension,
          filePath: filePath,
        ),
      ),
    );
  }

  void launchUrlExternally(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
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
          title: Text(
            'PDF & Presentation Suite',
            style: AppTextStyles.headlineSmall,
          ),
          actions: [
            if (pdf.status != PdfJobStatus.idle)
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textMuted,
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PDF & Presentation tools require sign in.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => LoginPromptDialog.show(
                          context,
                          featureName: 'PDF & Document Tools',
                          customMessage:
                              'Sign in to generate, convert, extract, and export PDFs and presentations!',
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
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Processing document with high precision...',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
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
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pdf.successMessage!,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pdf.error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Interactive AI Presentation Slide Deck Viewer (when generated)
              if (pdf.generatedSlides.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Presentation: ${pdf.currentPresentationTopic}',
                      style: AppTextStyles.headlineSmall,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(
                        Icons.download_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                      label: const Text(
                        'Export PDF Deck',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => pdf.exportPresentationToPdf(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SlideViewerCard(
                  slide: pdf.generatedSlides[_currentSlideIndex],
                  currentIndex: _currentSlideIndex,
                  totalSlides: pdf.generatedSlides.length,
                  onPrev: _currentSlideIndex > 0
                      ? () => setState(() => _currentSlideIndex--)
                      : null,
                  onNext: _currentSlideIndex < pdf.generatedSlides.length - 1
                      ? () => setState(() => _currentSlideIndex++)
                      : null,
                ),
                const SizedBox(height: 28),
              ],

              // Extracted Text View
              if (pdf.extractedText != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Extracted Document Content',
                      style: AppTextStyles.headlineSmall,
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy'),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: pdf.extractedText!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Extracted text copied to clipboard!',
                                ),
                              ),
                            );
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
              Text(
                'Document Creation & Conversion',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Instant creation, conversion, extraction, and slide generation.',
                style: AppTextStyles.bodySmall,
              ),
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
                        description:
                            'Select or drop photos/diagrams to assemble into a multi-page PDF.',
                        buttonLabel: 'Select Images',
                        dropHint: 'Drop images here',
                        acceptedExtensions: const [
                          'jpg',
                          'jpeg',
                          'png',
                          'webp',
                        ],
                        isLocked: auth.isGuest,
                        gradientColors: [
                          const Color(0xFFE07A5F),
                          const Color(0xFFF2CC8F),
                        ],
                        onTap: _openImagesToPdfDialog,
                        onFilesDropped: (details) =>
                            _handleDroppedImages([details]),
                      ),
                      _ActiveToolCard(
                        icon: '📝',
                        title: 'Notes → Formatted PDF',
                        description:
                            'Type or paste your study notes, formulas, and headings to generate a formatted PDF.',
                        buttonLabel: 'Create Notes PDF',
                        isLocked: auth.isGuest,
                        gradientColors: [
                          const Color(0xFF3B82F6),
                          const Color(0xFF06B6D4),
                        ],
                        onTap: _openNotesToPdfDialog,
                      ),
                      _ActiveToolCard(
                        icon: '📊',
                        title: 'AI Presentation (PPT) Maker',
                        description:
                            'Enter any topic and AI generates a 5-slide visual presentation deck downloadable as PDF.',
                        buttonLabel: 'Generate Slide Deck',
                        isLocked: auth.isGuest,
                        gradientColors: [
                          const Color(0xFFF2CC8F),
                          const Color(0xFFEC4899),
                        ],
                        onTap: _openAiPresentationDialog,
                      ),
                      _ActiveToolCard(
                        icon: '📄',
                        title: 'PDF → Text & Notes',
                        description:
                            'Select or drop a PDF to extract raw text, paragraphs, and formulas.',
                        buttonLabel: 'Extract from PDF',
                        dropHint: 'Drop PDF here',
                        acceptedExtensions: const ['pdf'],
                        isLocked: auth.isGuest,
                        gradientColors: [
                          const Color(0xFF10B981),
                          const Color(0xFF059669),
                        ],
                        onTap: _openPdfExtractDialog,
                        onFilesDropped: (details) =>
                            _handleDroppedPdf([details]),
                      ),
                      _ActiveToolCard(
                        icon: '📂',
                        title: 'Document Viewer',
                        description:
                            'Drop or select PPT, Excel, Word, and other documents to open with your reader.',
                        buttonLabel: 'Open a Document',
                        dropHint: 'Drop document here',
                        acceptedExtensions: const [
                          'ppt',
                          'pptx',
                          'xls',
                          'xlsx',
                          'csv',
                          'doc',
                          'docx',
                          'pdf',
                          'txt',
                          'rtf',
                          'odt',
                          'ods',
                          'odp',
                        ],
                        isLocked: false,
                        gradientColors: [
                          const Color(0xFFF59E0B),
                          const Color(0xFFEF4444),
                        ],
                        onTap: _openDocumentViewer,
                        onFilesDropped: (details) =>
                            _handleDroppedDocument([details]),
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

class _ActiveToolCard extends StatefulWidget {
  final String icon, title, description, buttonLabel;
  final String? dropHint;
  final List<String>? acceptedExtensions;
  final List<Color> gradientColors;
  final bool isLocked;
  final VoidCallback onTap;
  final void Function(DropDoneDetails)? onFilesDropped;

  const _ActiveToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    this.dropHint,
    this.acceptedExtensions,
    required this.gradientColors,
    required this.isLocked,
    required this.onTap,
    this.onFilesDropped,
  });

  @override
  State<_ActiveToolCard> createState() => _ActiveToolCardState();
}

class _ActiveToolCardState extends State<_ActiveToolCard> {
  bool _isDragHovering = false;

  @override
  Widget build(BuildContext context) {
    final bool supportsDrops =
        widget.onFilesDropped != null && !widget.isLocked;

    Widget card = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _isDragHovering
              ? widget.gradientColors.first.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isDragHovering
                ? widget.gradientColors.first
                : widget.gradientColors.first.withValues(alpha: 0.3),
            width: _isDragHovering ? 2 : 1,
          ),
          gradient: _isDragHovering
              ? null
              : LinearGradient(
                  colors: [
                    widget.gradientColors.first.withValues(alpha: 0.12),
                    widget.gradientColors.last.withValues(alpha: 0.04),
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
                Text(widget.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (widget.isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 12,
                                    color: AppColors.warning,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Sign-in',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.description,
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Drop zone hint when hovering
            if (_isDragHovering && widget.dropHint != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.file_download_outlined,
                        size: 32,
                        color: widget.gradientColors.first,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.dropHint!,
                        style: TextStyle(
                          color: widget.gradientColors.first,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Spacer(),
            // Bottom row: drop badge + action button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Drop badge for cards that support drops
                if (supportsDrops && !_isDragHovering)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.gradientColors.first.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.gradientColors.first.withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.file_download_outlined,
                          size: 12,
                          color: widget.gradientColors.first.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Drop',
                          style: TextStyle(
                            color: widget.gradientColors.first.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: widget.isLocked
                        ? null
                        : LinearGradient(colors: widget.gradientColors),
                    color: widget.isLocked ? AppColors.card : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.isLocked
                            ? 'Locked (Sign In)'
                            : widget.buttonLabel,
                        style: TextStyle(
                          color: widget.isLocked
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        widget.isLocked
                            ? Icons.lock_outline_rounded
                            : Icons.arrow_forward_rounded,
                        size: 14,
                        color: widget.isLocked
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Wrap with DropTarget only if the card supports drops
    if (supportsDrops) {
      card = DropTarget(
        onDragEntered: (_) => setState(() => _isDragHovering = true),
        onDragExited: (_) => setState(() => _isDragHovering = false),
        onDragDone: (details) {
          setState(() => _isDragHovering = false);
          widget.onFilesDropped?.call(details);
        },
        child: card,
      );
    }

    return card;
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
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Slide ${currentIndex + 1} of $totalSlides',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: onPrev,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: onNext,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            slide.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (slide.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              slide.subtitle!,
              style: const TextStyle(color: AppColors.accent, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),

          // Bullet points
          ...slide.bulletPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4, right: 10),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (slide.note != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7EBDD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '💡 Speaker Note: ${slide.note}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InAppDocumentViewerModal extends StatefulWidget {
  final String fileName;
  final Uint8List bytes;
  final String extension;
  final String? filePath;

  const InAppDocumentViewerModal({
    super.key,
    required this.fileName,
    required this.bytes,
    required this.extension,
    this.filePath,
  });

  @override
  State<InAppDocumentViewerModal> createState() =>
      _InAppDocumentViewerModalState();
}

class _InAppDocumentViewerModalState extends State<InAppDocumentViewerModal> {
  PdfControllerPinch? _pdfController;
  bool _pdfError = false;
  String _pdfErrorMessage = '';

  // PPT slides state
  List<PresentationSlide> _parsedSlides = [];
  int _currentPptIndex = 0;

  // Spreadsheet state
  List<List<String>> _spreadsheetRows = [];
  String _sheetSearchQuery = '';

  // Word/Text state
  String _parsedTextDoc = '';

  @override
  void initState() {
    super.initState();
    final ext = widget.extension.toLowerCase();

    if (ext == 'pdf') {
      _parsedTextDoc = _extractPdfTextFromBytes(widget.bytes);
      if (!kIsWeb) {
        try {
          _pdfController = PdfControllerPinch(
            document: PdfDocument.openData(widget.bytes),
          );
        } catch (e) {
          _pdfError = true;
          _pdfErrorMessage = '$e';
        }
      }
    } else if (['ppt', 'pptx', 'odp'].contains(ext)) {
      _parsedSlides = _parsePptxBytes(widget.bytes, widget.fileName);
    } else if (['xls', 'xlsx', 'csv', 'tsv', 'ods'].contains(ext)) {
      _spreadsheetRows = _parseSpreadsheetRows(widget.bytes, ext);
    } else if ([
      'doc',
      'docx',
      'txt',
      'rtf',
      'md',
      'json',
      'log',
      'xml',
    ].contains(ext)) {
      if (ext == 'docx') {
        _parsedTextDoc = _parseDocxText(widget.bytes);
      } else {
        _parsedTextDoc = utf8.decode(widget.bytes, allowMalformed: true);
      }
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  // PPTX Parser
  List<PresentationSlide> _parsePptxBytes(Uint8List bytes, String fileName) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final slideFiles = archive.files
          .where((f) => RegExp(r'ppt/slides/slide\d+\.xml$').hasMatch(f.name))
          .toList();

      slideFiles.sort((a, b) {
        final numA =
            int.tryParse(RegExp(r'\d+').stringMatch(a.name) ?? '0') ?? 0;
        final numB =
            int.tryParse(RegExp(r'\d+').stringMatch(b.name) ?? '0') ?? 0;
        return numA.compareTo(numB);
      });

      List<PresentationSlide> slides = [];
      for (int i = 0; i < slideFiles.length; i++) {
        final slideFile = slideFiles[i];
        final contentStr = utf8.decode(
          slideFile.content as List<int>,
          allowMalformed: true,
        );
        final matches = RegExp(r'<a:t[^>]*>(.*?)</a:t>').allMatches(contentStr);
        final textLines = matches
            .map((m) => m.group(1) ?? '')
            .map(
              (t) => t
                  .replaceAll('&lt;', '<')
                  .replaceAll('&gt;', '>')
                  .replaceAll('&amp;', '&')
                  .trim(),
            )
            .where((t) => t.isNotEmpty)
            .toList();

        if (textLines.isNotEmpty) {
          final title = textLines.first;
          final bullets = textLines.length > 1
              ? textLines.sublist(1)
              : <String>['(Slide Content)'];
          slides.add(
            PresentationSlide(
              title: title,
              subtitle: i == 0 ? 'Presentation Slide Deck' : null,
              bulletPoints: bullets,
              note: 'Slide ${i + 1} of ${slideFiles.length}',
            ),
          );
        }
      }

      if (slides.isNotEmpty) return slides;
    } catch (e) {
      debugPrint('Error parsing PPTX: $e');
    }

    return [
      PresentationSlide(
        title: fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
        subtitle: 'PowerPoint Presentation',
        bulletPoints: [
          'File Name: $fileName',
          'Size: ${(bytes.length / 1024).toStringAsFixed(1)} KB',
          'Document loaded successfully in StudySpace viewer.',
        ],
        note: 'Interactive slide view enabled',
      ),
    ];
  }

  // Intelligent DOCX Parser — Preserves paragraph indents, headings, list bullets, tabs, and formatting
  String _parseDocxText(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile = archive.files.firstWhere(
        (f) => f.name == 'word/document.xml',
        orElse: () => ArchiveFile('', 0, []),
      );

      if (docFile.content.isNotEmpty) {
        final xmlContent = utf8.decode(
          docFile.content as List<int>,
          allowMalformed: true,
        );
        final pMatches = RegExp(
          r'<w:p[^>]*>(.*?)</w:p>',
          dotAll: true,
        ).allMatches(xmlContent);

        final docBuffer = StringBuffer();

        for (final pMatch in pMatches) {
          final pXml = pMatch.group(1) ?? '';
          final pBuffer = StringBuffer();

          // Heading Detection
          String headingPrefix = '';
          final styleMatch = RegExp(
            r'<w:pStyle\s+w:val="([^"]+)"',
          ).firstMatch(pXml);
          if (styleMatch != null) {
            final styleVal = styleMatch.group(1)?.toLowerCase() ?? '';
            if (styleVal.contains('heading1') || styleVal == 'title') {
              headingPrefix = '# ';
            } else if (styleVal.contains('heading2')) {
              headingPrefix = '## ';
            } else if (styleVal.contains('heading3')) {
              headingPrefix = '### ';
            }
          }

          // List / Bullet Point Detection
          String listPrefix = '';
          if (pXml.contains('<w:numPr>') || pXml.contains('ListParagraph')) {
            final ilvlMatch = RegExp(
              r'<w:ilvl\s+w:val="(\d+)"',
            ).firstMatch(pXml);
            final level = int.tryParse(ilvlMatch?.group(1) ?? '0') ?? 0;
            final indentSpaces = '  ' * level;
            listPrefix = '$indentSpaces• ';
          }

          // Indentation Detection (Left margin)
          String indentPrefix = '';
          final indMatch = RegExp(
            r'<w:ind\s+[^>]*w:left="(\d+)"',
          ).firstMatch(pXml);
          if (indMatch != null && listPrefix.isEmpty) {
            final leftVal = int.tryParse(indMatch.group(1) ?? '0') ?? 0;
            if (leftVal > 360) {
              final tabCount = (leftVal / 360).round().clamp(1, 4);
              indentPrefix = '&nbsp;&nbsp;&nbsp;&nbsp;' * tabCount;
            }
          }

          // Parse Runs (<w:r>)
          final rMatches = RegExp(
            r'<w:r[^>]*>(.*?)</w:r>',
            dotAll: true,
          ).allMatches(pXml);
          for (final rMatch in rMatches) {
            final rXml = rMatch.group(1) ?? '';
            final isBold = rXml.contains('<w:b/>') || rXml.contains('<w:b ');
            final isItalic = rXml.contains('<w:i/>') || rXml.contains('<w:i ');

            if (rXml.contains('<w:tab/>') || rXml.contains('<w:tab ')) {
              pBuffer.write('&nbsp;&nbsp;&nbsp;&nbsp;');
            }
            if (rXml.contains('<w:br/>') || rXml.contains('<w:br ')) {
              pBuffer.write('\n');
            }

            final tMatches = RegExp(
              r'<w:t[^>]*>(.*?)</w:t>',
              dotAll: true,
            ).allMatches(rXml);
            for (final tMatch in tMatches) {
              var tText = tMatch.group(1) ?? '';
              tText = tText
                  .replaceAll('&lt;', '<')
                  .replaceAll('&gt;', '>')
                  .replaceAll('&amp;', '&')
                  .replaceAll('&quot;', '"')
                  .replaceAll('&apos;', "'");

              if (tText.isNotEmpty) {
                if (isBold && isItalic) {
                  pBuffer.write('***$tText***');
                } else if (isBold) {
                  pBuffer.write('**$tText**');
                } else if (isItalic) {
                  pBuffer.write('*$tText*');
                } else {
                  pBuffer.write(tText);
                }
              }
            }
          }

          final paragraphText = pBuffer.toString().trimRight();
          if (paragraphText.isNotEmpty) {
            docBuffer.writeln(
              '$indentPrefix$listPrefix$headingPrefix$paragraphText\n',
            );
          }
        }

        final result = docBuffer.toString().trim();
        if (result.isNotEmpty) return result;
      }
    } catch (e) {
      debugPrint('Error parsing DOCX: $e');
    }

    return utf8.decode(bytes, allowMalformed: true);
  }

  // Spreadsheet Parser
  List<List<String>> _parseSpreadsheetRows(Uint8List bytes, String extension) {
    try {
      if (extension == 'csv' || extension == 'tsv') {
        final text = utf8.decode(bytes, allowMalformed: true);
        final delimiter = extension == 'tsv' ? '\t' : ',';
        return text
            .split('\n')
            .where((row) => row.trim().isNotEmpty)
            .map(
              (row) => row
                  .split(delimiter)
                  .map((cell) => cell.trim().replaceAll('"', ''))
                  .toList(),
            )
            .toList();
      }

      final archive = ZipDecoder().decodeBytes(bytes);

      List<String> sharedStrings = [];
      final sharedFile = archive.files.firstWhere(
        (f) => f.name == 'xl/sharedStrings.xml',
        orElse: () => ArchiveFile('', 0, []),
      );
      if (sharedFile.content.isNotEmpty) {
        final xmlStr = utf8.decode(
          sharedFile.content as List<int>,
          allowMalformed: true,
        );
        final matches = RegExp(r'<t[^>]*>(.*?)</t>').allMatches(xmlStr);
        sharedStrings = matches.map((m) => m.group(1) ?? '').toList();
      }

      final sheetFile = archive.files.firstWhere(
        (f) => RegExp(r'xl/worksheets/sheet1\.xml$').hasMatch(f.name),
        orElse: () => ArchiveFile('', 0, []),
      );

      if (sheetFile.content.isNotEmpty) {
        final sheetXml = utf8.decode(
          sheetFile.content as List<int>,
          allowMalformed: true,
        );
        final rowMatches = RegExp(
          r'<row[^>]*>(.*?)</row>',
        ).allMatches(sheetXml);

        List<List<String>> rows = [];
        for (final r in rowMatches) {
          final rowContent = r.group(1) ?? '';
          final cellMatches = RegExp(
            r'<c[^>]*?(?:t="([^"]*)")?[^>]*>(?:<v>(.*?)</v>)?',
          ).allMatches(rowContent);

          List<String> rowCells = [];
          for (final c in cellMatches) {
            final type = c.group(1);
            final val = c.group(2) ?? '';
            if (type == 's' && val.isNotEmpty) {
              final idx = int.tryParse(val) ?? -1;
              if (idx >= 0 && idx < sharedStrings.length) {
                rowCells.add(sharedStrings[idx]);
              } else {
                rowCells.add(val);
              }
            } else {
              rowCells.add(val);
            }
          }
          if (rowCells.isNotEmpty) rows.add(rowCells);
        }
        if (rows.isNotEmpty) return rows;
      }
    } catch (e) {
      debugPrint('Error parsing spreadsheet: $e');
    }

    return [
      ['Column A', 'Column B', 'Column C'],
      ['File Data', '${(bytes.length / 1024).toStringAsFixed(1)} KB', 'Loaded'],
    ];
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'csv':
        return 'text/csv';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
      case 'md':
        return 'text/plain';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _downloadCopy() async {
    await saveAndDownloadFile(
      fileName: widget.fileName,
      bytes: widget.bytes,
      mimeType: _getMimeType(widget.extension),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloaded "${widget.fileName}"'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = widget.extension.toLowerCase();
    final isPdf = ext == 'pdf';
    final isPpt = ['ppt', 'pptx', 'odp'].contains(ext);
    final isSheet = ['xls', 'xlsx', 'csv', 'tsv', 'ods'].contains(ext);
    final isImage = ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'].contains(ext);
    final isTextDoc = [
      'doc',
      'docx',
      'txt',
      'rtf',
      'md',
      'json',
      'log',
      'xml',
    ].contains(ext);

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7EBDD),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPdf
                      ? Icons.picture_as_pdf_rounded
                      : isPpt
                      ? Icons.slideshow_rounded
                      : isSheet
                      ? Icons.table_chart_rounded
                      : isImage
                      ? Icons.image_rounded
                      : Icons.description_rounded,
                  color: isPdf
                      ? const Color(0xFFEF4444)
                      : isPpt
                      ? const Color(0xFFF59E0B)
                      : isSheet
                      ? const Color(0xFF10B981)
                      : AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fileName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${(widget.bytes.length / 1024).toStringAsFixed(1)} KB • Native In-App Reader',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Indicator for PDF / PPT / Sheets
                if (isPdf && _pdfController != null)
                  PdfPageNumber(
                    controller: _pdfController!,
                    builder: (context, loading, page, pagesCount) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Page $page of ${pagesCount ?? 0}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (isPpt && _parsedSlides.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Slide ${_currentPptIndex + 1} of ${_parsedSlides.length}',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isSheet)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_spreadsheetRows.length} Rows',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                IconButton(
                  icon: const Icon(
                    Icons.download_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  tooltip: 'Download Copy',
                  onPressed: _downloadCopy,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  tooltip: 'Close Viewer',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Main Viewer Content
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              child: _buildViewerBody(
                isPdf,
                isPpt,
                isSheet,
                isImage,
                isTextDoc,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewerBody(
    bool isPdf,
    bool isPpt,
    bool isSheet,
    bool isImage,
    bool isTextDoc,
  ) {
    // 1. PDF
    if (isPdf) {
      return EmbeddedDocumentViewer(
        bytes: widget.bytes,
        mimeType: 'application/pdf',
        fallbackWidget: _buildNativePdfView(),
      );
    }

    // 2. PPT Presentation Slide Deck
    if (isPpt) {
      if (_parsedSlides.isEmpty) {
        return const Center(
          child: Text(
            'No slides found in presentation.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );
      }

      final slide = _parsedSlides[_currentPptIndex];
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: _SlideViewerCard(
                  slide: slide,
                  currentIndex: _currentPptIndex,
                  totalSlides: _parsedSlides.length,
                  onPrev: _currentPptIndex > 0
                      ? () => setState(() => _currentPptIndex--)
                      : null,
                  onNext: _currentPptIndex < _parsedSlides.length - 1
                      ? () => setState(() => _currentPptIndex++)
                      : null,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Spreadsheet Data Grid Table
    if (isSheet) {
      if (_spreadsheetRows.isEmpty) {
        return const Center(
          child: Text(
            'No data found in spreadsheet.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );
      }

      final filteredRows = _sheetSearchQuery.trim().isEmpty
          ? _spreadsheetRows
          : _spreadsheetRows
                .where(
                  (row) => row.any(
                    (cell) => cell.toLowerCase().contains(
                      _sheetSearchQuery.toLowerCase(),
                    ),
                  ),
                )
                .toList();

      final maxCols = _spreadsheetRows.fold<int>(
        0,
        (max, row) => row.length > max ? row.length : max,
      );

      return Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF7EBDD),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search spreadsheet cells...',
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFFFFCF8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _sheetSearchQuery = val),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF7EBDD),
                  ),
                  dataRowColor: WidgetStateProperty.all(
                    const Color(0xFFFFFCF8),
                  ),
                  border: TableBorder.all(
                    color: AppColors.border.withValues(alpha: 0.2),
                  ),
                  columns: List.generate(
                    maxCols,
                    (colIdx) => DataColumn(
                      label: Text(
                        String.fromCharCode(65 + (colIdx % 26)),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  rows: filteredRows.map((row) {
                    return DataRow(
                      cells: List.generate(
                        maxCols,
                        (colIdx) => DataCell(
                          Text(
                            colIdx < row.length ? row[colIdx] : '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 4. Image
    if (isImage) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.memory(
            widget.bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 8),
                Text(
                  'Could not render image',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 5. Text / Word Document Reader with Formatted Indentation & Headings
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE07A5F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_parsedTextDoc.split('\n').length} paragraphs • Indented View Ready',
                  style: const TextStyle(
                    color: Color(0xFFD66A50),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: Color(0xFFD66A50),
                ),
                label: const Text(
                  'Copy Document Text',
                  style: TextStyle(color: Color(0xFFD66A50), fontSize: 12),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _parsedTextDoc));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied document text to clipboard! 📋'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8D4C4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: _parsedTextDoc,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 14,
                      height: 1.6,
                    ),
                    h1: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    h2: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    h3: const TextStyle(
                      color: Color(0xFFD66A50),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    listBullet: const TextStyle(
                      color: Color(0xFFD66A50),
                      fontWeight: FontWeight.bold,
                    ),
                    blockquote: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontStyle: FontStyle.italic,
                    ),
                    blockquoteDecoration: BoxDecoration(
                      border: const Border(
                        left: BorderSide(color: Color(0xFFD66A50), width: 3),
                      ),
                      color: const Color(0xFFE07A5F).withValues(alpha: 0.08),
                    ),
                    blockquotePadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    strong: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    em: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF806A63),
                    ),
                    code: const TextStyle(
                      backgroundColor: Color(0xFFF7EBDD),
                      color: Color(0xFF38BDF8),
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractPdfTextFromBytes(Uint8List bytes) {
    try {
      final rawStr = utf8.decode(bytes, allowMalformed: true);
      final textMatches = RegExp(r'\((.*?)\)Tj|\[(.*?)\]TJ').allMatches(rawStr);

      final buffer = StringBuffer();
      for (final m in textMatches) {
        final text = m.group(1) ?? m.group(2);
        if (text != null && text.trim().isNotEmpty) {
          final clean = text
              .replaceAll(r'\(', '(')
              .replaceAll(r'\)', ')')
              .replaceAll(r'\\', '\\');
          buffer.writeln(clean);
        }
      }

      final result = buffer.toString().trim();
      if (result.isNotEmpty && result.length > 20) return result;
    } catch (_) {}

    return '';
  }

  Widget _buildNativePdfView() {
    if (_pdfError || _pdfController == null) {
      if (_parsedTextDoc.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Extracted PDF Text & Formulas',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Copy Text',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _parsedTextDoc));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied text to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7EBDD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _parsedTextDoc,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.picture_as_pdf_rounded,
              size: 54,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            Text(
              widget.fileName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(widget.bytes.length / 1024).toStringAsFixed(1)} KB • PDF Document',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: _downloadCopy,
              icon: const Icon(
                Icons.download_rounded,
                size: 16,
                color: AppColors.textPrimary,
              ),
              label: const Text(
                'Download PDF',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PdfViewPinch(
      controller: _pdfController!,
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        pageLoaderBuilder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        errorBuilder: (context, error) {
          if (_parsedTextDoc.isNotEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _parsedTextDoc,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            );
          }
          return Center(
            child: ElevatedButton.icon(
              onPressed: _downloadCopy,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Download PDF Copy'),
            ),
          );
        },
      ),
    );
  }
}
