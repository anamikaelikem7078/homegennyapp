import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/extensions/context_extensions.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';
import '../../widgets/staff_scaffold.dart';

/// Training courses list.
class StaffTrainingScreen extends ConsumerWidget {
  const StaffTrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(staffTrainingCoursesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF1A56FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF475569)),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=400'),
            ),
          )
        ],
      ),
      body: courses.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => DsErrorState(
          title: 'Error',
          onRetry: () => ref.invalidate(staffTrainingCoursesProvider),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(staffTrainingCoursesProvider),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              Text(
                'Mandatory Training',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Stay compliant and up to date with your\ncore certifications. Your progress is tracked\nautomatically.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ...list.map((course) => _CourseTile(course: course)),
              const SizedBox(height: 16),
              
              // Professional Growth Footer
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF1A56FF), size: 24),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Professional Growth',
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Completion of these modules unlocks the\nSenior Household Liaison certificate path.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Stack(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.45,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A56FF),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '45% TOWARDS BADGE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A56FF),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Optional skill image card
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1556761175-5973dc0f32e7?auto=format&fit=crop&q=80&w=800'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OPTIONAL SKILL',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Advanced Concierge\nEtiquette',
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.course});
  final TrainingCourse course;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getCategoryLabel(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            course.title,
            style: GoogleFonts.libreCaslonText(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                course.duration,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Circular progress or checkmark
              SizedBox(
                width: 48,
                height: 48,
                child: course.progress >= 1.0
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1A56FF), width: 2),
                      ),
                      child: const Icon(Icons.check, color: Color(0xFF1A56FF), size: 24),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: course.progress,
                          strokeWidth: 3,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A56FF)),
                        ),
                        Text(
                          '${(course.progress * 100).round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A56FF),
                          ),
                        ),
                      ],
                    ),
              ),
              _buildActionButton(context),
            ],
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel() {
    return switch (course.type) {
      'video' => 'VIDEO MODULE',
      'pdf' => 'READING MODULE',
      'quiz' => 'QUIZ',
      _ => 'MODULE',
    };
  }

  Widget _buildActionButton(BuildContext context) {
    String label;
    bool isFilled = false;

    if (course.progress >= 1.0) {
      return GestureDetector(
        onTap: () => _openCourse(context, course),
        child: Text(
          'Review',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      );
    } else if (course.progress > 0) {
      label = 'Resume';
      isFilled = false;
    } else {
      label = course.type == 'quiz' ? 'Start Quiz' : 'Continue';
      isFilled = course.type != 'quiz';
    }

    // specific case for the image
    if (course.title.contains('Fire Safety')) {
      label = 'Continue';
      isFilled = true;
    }

    if (isFilled) {
      return ElevatedButton(
        onPressed: () => _openCourse(context, course),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56FF),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          minimumSize: const Size(0, 36),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => _openCourse(context, course),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      );
    }
  }

  void _openCourse(BuildContext context, TrainingCourse c) {
    switch (c.type) {
      case 'video':
        context.push(StaffRoutes.trainingVideo(c.id));
      case 'pdf':
        context.push(StaffRoutes.trainingPdf(c.id));
      case 'quiz':
        context.push(StaffRoutes.trainingQuiz(c.id));
      default:
        context.push(StaffRoutes.trainingVideo(c.id));
    }
  }
}

/// Training categories screen.
class StaffTrainingCategoriesScreen extends ConsumerWidget {
  const StaffTrainingCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(staffTrainingCategoriesProvider);

    return StaffPageScaffold(
      title: 'Training Categories',
      body: categories.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final cat = list[i];
            return StaffMenuTile(
              icon: Icons.folder_special_outlined,
              title: cat.name,
              subtitle: '${cat.courseCount} courses',
              onTap: () => context.push(StaffRoutes.training),
            );
          },
        ),
      ),
    );
  }
}

/// Video player placeholder screen.
class StaffVideoPlayerScreen extends ConsumerWidget {
  const StaffVideoPlayerScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(staffTrainingCourseProvider(courseId));

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: Text(
          'Video Training',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF1A56FF),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF475569)),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=400'),
            ),
          )
        ],
      ),
      body: course.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (c) => Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // Video Player Placeholder
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      image: DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1552664730-d307ca884978?auto=format&fit=crop&q=80&w=800'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A56FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                      ),
                    ),
                  ),
                  
                  // Content Module
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'MODULE 04',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFFCBD5E1),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Communication\nSeries',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Client\nCommunication',
                          style: GoogleFonts.libreCaslonText(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Master the art of high-impact professional correspondence. This session covers tone modulation, active listening strategies, and managing stakeholder expectations in luxury service environments.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF475569),
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.access_time_outlined, color: Color(0xFF64748B), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Duration: ${c.duration}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Status & Prerequisites Cards
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STATUS',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1A56FF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'In Progress',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A56FF),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PREREQUISITES',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ethics 101, Workplace Basics',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Learning Resources
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Learning Resources',
                          style: GoogleFonts.libreCaslonText(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A56FF),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.description_outlined, color: Color(0xFF1A56FF), size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Study Guide PDF',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Summary of key\ncommunication tactics',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.file_download_outlined, color: Color(0xFF94A3B8), size: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.quiz_outlined, color: Color(0xFF475569), size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Knowledge Check',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '5-minute quiz available after\nvideo',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_outlined, color: Color(0xFF94A3B8), size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Footer Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF9F8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.showDsSnackBar('Video completed', type: DsSnackBarType.success);
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'MARK COMPLETE',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
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
}

/// PDF reader placeholder screen.
class StaffPdfReaderScreen extends ConsumerWidget {
  const StaffPdfReaderScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(staffTrainingCourseProvider(courseId));

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A56FF), size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: Text(
          'PDF Reader',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF475569), size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF475569), size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: course.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (c) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF2F2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf,
                          size: 64,
                          color: Color(0xFFDC2626), // Red
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        'Fire Safety\nGuidelines',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Complete reading to ensure\nsafety compliance and\nemergency preparedness.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF475569),
                          height: 1.6,
                        ),
                      ),
                      const Spacer(),
                      
                      // Progress Bar
                      Container(
                        width: 120,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A56FF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Page 1 of 12',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SAFETY PROTOCOL',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '100% READ',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A56FF),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  label: Text(
                    'FINISH READING',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Training quiz screen.
class StaffQuizScreen extends ConsumerStatefulWidget {
  const StaffQuizScreen({super.key, required this.courseId});
  final String courseId;

  @override
  ConsumerState<StaffQuizScreen> createState() => _StaffQuizScreenState();
}

class _StaffQuizScreenState extends ConsumerState<StaffQuizScreen> {
  final _answers = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(staffQuizProvider(widget.courseId));

    return StaffPageScaffold(
      title: 'Quiz',
      body: quiz.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (questions) => Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (_, i) {
                  final q = questions[i];
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}. ${q.question}',
                            style: Theme.of(context).textTheme.titleSmall),
                        ...List.generate(q.options.length, (oi) {
                          return RadioListTile<int>(
                            title: Text(q.options[oi]),
                            value: oi,
                            groupValue: _answers[q.id],
                            onChanged: (v) =>
                                setState(() => _answers[q.id] = v!),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            DsPrimaryButton(
              label: 'Submit Quiz',
              onPressed: _answers.length == questions.length
                  ? () async {
                      final result = await ref
                          .read(staffRepositoryProvider)
                          .submitQuiz(widget.courseId, _answers);
                      if (!context.mounted) return;
                      result.fold(
                        onSuccess: (r) => context.pushReplacement(
                          StaffRoutes.trainingResult(widget.courseId),
                          extra: r,
                        ),
                        onError: (f) => context.showDsSnackBar(f.message,
                            type: DsSnackBarType.error),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Training quiz result screen.
class StaffTrainingResultScreen extends StatelessWidget {
  const StaffTrainingResultScreen({super.key, required this.courseId, this.result});
  final String courseId;
  final QuizResult? result;

  @override
  Widget build(BuildContext context) {
    final r = result ?? const QuizResult(score: 2, total: 3, passed: true);

    return StaffPageScaffold(
      title: 'Training Result',
      showBack: false,
      body: Column(
        children: [
          Icon(
            r.passed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied,
            size: 80,
            color: r.passed ? AppColors.success : AppColors.error,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            r.passed ? 'Congratulations!' : 'Try Again',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text('Score: ${r.score}/${r.total}'),
          const Spacer(),
          if (r.passed)
            DsGradientButton(
              label: 'View Certificate',
              onPressed: () =>
                  context.push(StaffRoutes.trainingCertificate(courseId)),
            ),
          SizedBox(height: AppSpacing.sm),
          DsOutlineButton(
            label: 'Back to Training',
            onPressed: () => context.go(StaffRoutes.training),
          ),
        ],
      ),
    );
  }
}

/// Training certificate screen.
class StaffCertificateScreen extends ConsumerWidget {
  const StaffCertificateScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(staffTrainingCourseProvider(courseId));

    return StaffPageScaffold(
      title: 'Certificate',
      body: course.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (c) => Column(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: AppRadius.xlAll,
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                children: [
                  Icon(Icons.verified_rounded,
                      size: 64, color: AppColors.primary),
                  SizedBox(height: AppSpacing.md),
                  Text('Certificate of Completion',
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: AppSpacing.sm),
                  Text(c.title, textAlign: TextAlign.center),
                  SizedBox(height: AppSpacing.lg),
                  Text('HomeGenny Training Program'),
                ],
              ),
            ),
            const Spacer(),
            DsOutlineButton(
              label: 'Download PDF',
              icon: Icons.download_rounded,
              onPressed: () => context.showDsSnackBar('Download started'),
            ),
          ],
        ),
      ),
    );
  }
}
