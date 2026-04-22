import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentDashboardHub extends StatelessWidget {
  final double moduleProgress; // 0.0 to 1.0 or 0 to 100
  final String currentModuleName;
  final int studentRank;
  final int pointsBehind;
  final String bestSkill;
  final String weakestSkill;
  final String? userAvatarUrl;
  final String userInitials;
  final bool isOnline;
  final String lastLessonTitle;
  final String lastModuleName;
  final double lastLessonProgress; // 0.0 to 1.0
  final VoidCallback onContinuePressed;

  const StudentDashboardHub({
    super.key,
    required this.moduleProgress,
    required this.currentModuleName,
    required this.studentRank,
    required this.pointsBehind,
    required this.bestSkill,
    required this.weakestSkill,
    required this.userInitials,
    required this.isOnline,
    required this.lastLessonTitle,
    required this.lastModuleName,
    required this.lastLessonProgress,
    required this.onContinuePressed,
    this.userAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // We'll use a fixed internal coordinate system (like the 390x844 mobile canvas)
        // and scale everything relative to the parent constraints.
        const double baseWidth = 390;
        const double baseHeight = 600; // Adjusted for the hub portion
        final double scale = constraints.maxWidth / baseWidth;

        return Container(
          width: constraints.maxWidth,
          height: baseHeight * scale,
          color: const Color(0xFFF4EFEB),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Module Progress Card (Top Left)
              Positioned(
                left: 20 * scale,
                top: 40 * scale,
                child: _StatCard(
                  title: 'MODULE PROGRESS',
                  value: '${(moduleProgress * 100).toInt()}%',
                  subtext: currentModuleName,
                  icon: Icons.bar_chart,
                  color: const Color(0xFF0F6E56),
                  backgroundColor: const Color(0xFFE1F5EE),
                  progress: moduleProgress,
                  scale: scale,
                ),
              ),

              // 2. Your Rank Card (Top Right)
              Positioned(
                right: 20 * scale,
                top: 20 * scale,
                child: _StatCard(
                  title: 'YOUR RANK',
                  value: '#$studentRank',
                  subtext: '$pointsBehind pts behind #${studentRank - 1}',
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF3C3489),
                  backgroundColor: const Color(0xFFEEEDFE),
                  scale: scale,
                ),
              ),

              // 3. Best Skill Card (Middle Right)
              Positioned(
                right: 15 * scale,
                top: 220 * scale,
                child: _StatCard(
                  title: 'BEST SKILL',
                  value: bestSkill,
                  subtext: 'Keep it sharp',
                  icon: Icons.lightbulb_outline,
                  color: const Color(0xFF854F0B),
                  backgroundColor: const Color(0xFFFAEEDA),
                  scale: scale,
                ),
              ),

              // 4. Weakest Skill Card (Bottom Left)
              Positioned(
                left: 15 * scale,
                top: 250 * scale,
                child: _StatCard(
                  title: 'WEAKEST SKILL',
                  value: weakestSkill,
                  subtext: 'Needs practice',
                  icon: Icons.flash_on_outlined,
                  color: const Color(0xFF993C1D),
                  backgroundColor: const Color(0xFFFAECE7),
                  scale: scale,
                ),
              ),

              // 5. Center Avatar
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 140 * scale,
                  height: 140 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 8 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20 * scale,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 70 * scale,
                        backgroundColor: const Color(0xFFE5E7EB),
                        backgroundImage: userAvatarUrl != null ? NetworkImage(userAvatarUrl!) : null,
                        child: userAvatarUrl == null
                            ? Text(
                                userInitials,
                                style: GoogleFonts.inter(
                                  fontSize: 32 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6A7282),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 4 * scale,
                        right: 4 * scale,
                        child: _OnlineIndicator(isOnline: isOnline, scale: scale),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Blue Bottom Section
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onContinuePressed,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 20 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFF213F95),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40 * scale),
                        topRight: Radius.circular(40 * scale),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continue where you left off',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lastLessonTitle,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 18 * scale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    lastModuleName,
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 14 * scale,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white),
                          ],
                        ),
                        SizedBox(height: 16 * scale),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2 * scale),
                          child: LinearProgressIndicator(
                            value: lastLessonProgress,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 4 * scale,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double? progress;
  final double scale;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.scale,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155 * scale,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10 * scale,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8 * scale),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: Icon(icon, color: color, size: 20 * scale),
          ),
          SizedBox(height: 16 * scale),
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF6A7282),
              fontSize: 10 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 24 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            subtext,
            style: GoogleFonts.inter(
              color: const Color(0xFF99A1AF),
              fontSize: 11 * scale,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (progress != null) ...[
            SizedBox(height: 12 * scale),
            ClipRRect(
              borderRadius: BorderRadius.circular(4 * scale),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6 * scale,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnlineIndicator extends StatefulWidget {
  final bool isOnline;
  final double scale;

  const _OnlineIndicator({required this.isOnline, required this.scale});

  @override
  State<_OnlineIndicator> createState() => _OnlineIndicatorState();
}

class _OnlineIndicatorState extends State<_OnlineIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.isOnline)
          ScaleTransition(
            scale: _animation,
            child: Container(
              width: 16 * widget.scale,
              height: 16 * widget.scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1D9F76).withOpacity(0.3),
              ),
            ),
          ),
        Container(
          width: 12 * widget.scale,
          height: 12 * widget.scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isOnline ? const Color(0xFF1D9F76) : Colors.red,
            border: Border.all(color: Colors.white, width: 2 * widget.scale),
          ),
        ),
      ],
    );
  }
}
