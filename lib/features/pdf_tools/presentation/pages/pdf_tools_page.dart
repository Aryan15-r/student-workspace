import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/pdf_provider.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Route: /pdf-tools
class PdfToolsPage extends StatelessWidget {
  const PdfToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('PDF Tools', style: AppTextStyles.headlineSmall)),
        body: Consumer<PdfProvider>(
          builder: (context, pdf, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Convert & Process', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 6),
                Text('Select a PDF to get started', style: AppTextStyles.bodySmall),
                const SizedBox(height: 24),

                // Main tool card
                _ToolCard(
                  icon: '📄',
                  title: 'PDF → Text / Word',
                  description: 'Extract text from any PDF file. Download the result as a text file.',
                  onTap: pdf.status == PdfJobStatus.idle || pdf.status == PdfJobStatus.done || pdf.status == PdfJobStatus.error
                      ? () => context.read<PdfProvider>().pickAndProcess()
                      : null,
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 16),

                // Status
                if (pdf.status != PdfJobStatus.idle) _StatusPanel(provider: pdf).animate().fadeIn(),

                const SizedBox(height: 24),
                Text('Coming Soon', style: AppTextStyles.labelLarge),
                const SizedBox(height: 12),

                // Coming soon tools
                ...const [
                  ['🔀', 'Merge PDFs', 'Combine multiple PDFs into one'],
                  ['✂️', 'Split PDF', 'Extract specific pages from a PDF'],
                  ['🗜️', 'Compress PDF', 'Reduce file size for sharing'],
                  ['🖼️', 'PDF → Images', 'Convert each page to an image'],
                  ['📸', 'Images → PDF', 'Combine images into a PDF'],
                ].asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ComingSoonCard(icon: e.value[0], title: e.value[1], desc: e.value[2])
                      .animate().fadeIn(delay: Duration(milliseconds: e.key * 60 + 200)),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String icon, title, description;
  final VoidCallback? onTap;
  const _ToolCard({required this.icon, required this.title, required this.description, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.secondary.withValues(alpha: 0.08)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 4),
            Text(description, style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)), child: const Text('Select PDF', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
          ])),
        ]),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final PdfProvider provider;
  const _StatusPanel({required this.provider});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (provider.fileName != null) Text('📎 ${provider.fileName}', style: AppTextStyles.labelLarge),
        const SizedBox(height: 12),
        _StatusRow(status: provider.status),
        if (provider.result != null) ...[
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          Text(provider.result!, style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),
          Row(children: [
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_rounded, size: 16), label: const Text('Download')),
            const SizedBox(width: 10),
            TextButton(onPressed: () => context.read<PdfProvider>().reset(), child: const Text('Reset')),
          ]),
        ],
        if (provider.error != null) ...[
          const SizedBox(height: 8),
          Text(provider.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          TextButton(onPressed: () => context.read<PdfProvider>().reset(), child: const Text('Try again')),
        ],
      ]),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final PdfJobStatus status;
  const _StatusRow({required this.status});
  @override
  Widget build(BuildContext context) {
    final steps = [PdfJobStatus.picking, PdfJobStatus.uploading, PdfJobStatus.processing, PdfJobStatus.done];
    final labels = ['Selecting', 'Uploading', 'Processing', 'Done'];
    return Row(children: steps.asMap().entries.map((e) {
      final isPast    = steps.indexOf(status) >= e.key;
      final isCurrent = status == e.value;
      return Expanded(child: Row(children: [
        Column(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: isPast ? AppColors.success : AppColors.surface, border: Border.all(color: isPast ? AppColors.success : AppColors.border)), child: isPast ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : (isCurrent ? const Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)) : null)),
          Text(labels[e.key], style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ]),
        if (e.key < steps.length - 1) Expanded(child: Container(height: 1, color: isPast && steps.indexOf(status) > e.key ? AppColors.success : AppColors.border, margin: const EdgeInsets.only(bottom: 14))),
      ]));
    }).toList());
  }
}

class _ComingSoonCard extends StatelessWidget {
  final String icon, title, desc;
  const _ComingSoonCard({required this.icon, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTextStyles.titleMedium),
          Text(desc, style: AppTextStyles.bodySmall),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Text('Soon', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
