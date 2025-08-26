import 'package:flutter/material.dart';

class FlipbookAdditionalPages {
  final Color primaryColor;
  final Color secondaryColor;
  final ScrollController senaraiKataScrollController;
  final List<Map<String, String>> kataDataSenarai;

  FlipbookAdditionalPages({
    required this.primaryColor,
    required this.secondaryColor,
    required this.senaraiKataScrollController,
    required this.kataDataSenarai,
  });

  /// Creates the Senarai Kata (Word List) page
  Widget buildSenaraiKataPage() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _SenaraiKataHeader(primaryColor: primaryColor),
          const SizedBox(height: 24),
          Expanded(
            child: _SenaraiKataTable(
              primaryColor: primaryColor,
              scrollController: senaraiKataScrollController,
              kataData: kataDataSenarai,
            ),
          ),
        ],
      ),
    );
  }

  /// Creates the final completion page with logo
  Widget buildLastPage() {
    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final imageSize = (availableHeight * 0.6).clamp(200.0, 400.0);

          return Stack(
            children: [
              _BackgroundDecorations(
                constraints: constraints,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
              ),
              Center(
                child: _LogoContainer(
                  imageSize: imageSize,
                  primaryColor: primaryColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SenaraiKataHeader extends StatelessWidget {
  final Color primaryColor;

  const _SenaraiKataHeader({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'Senarai Kata',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SenaraiKataTable extends StatelessWidget {
  final Color primaryColor;
  final ScrollController scrollController;
  final List<Map<String, String>> kataData;

  const _SenaraiKataTable({
    required this.primaryColor,
    required this.scrollController,
    required this.kataData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: _buildTableContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        border: Border(
          bottom: BorderSide(
            color: primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Bahasa Indonesia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 2,
            height: 20,
            color: primaryColor.withValues(alpha: 0.3),
          ),
          Expanded(
            child: Text(
              'Basa Sunda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableContent() {
    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 8,
      radius: const Radius.circular(4),
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.zero,
        itemCount: kataData.length,
        itemBuilder: (context, index) {
          final kata = kataData[index];
          final isEven = index % 2 == 0;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: isEven
                  ? Colors.white
                  : primaryColor.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: primaryColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    kata['indonesia']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: primaryColor.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: Text(
                    kata['sunda']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BackgroundDecorations extends StatelessWidget {
  final BoxConstraints constraints;
  final Color primaryColor;
  final Color secondaryColor;

  const _BackgroundDecorations({
    required this.constraints,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Decorative circles in corners
        ..._buildCornerCircles(),
        // Subtle pattern dots
        ..._buildPatternDots(),
      ],
    );
  }

  List<Widget> _buildCornerCircles() {
    return [
      Positioned(
        top: -50,
        left: -50,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      Positioned(
        bottom: -50,
        right: -50,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: secondaryColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      Positioned(
        top: constraints.maxHeight * 0.3,
        left: -30,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor.withValues(alpha: 0.05),
          ),
        ),
      ),
      Positioned(
        top: constraints.maxHeight * 0.6,
        right: -30,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: secondaryColor.withValues(alpha: 0.05),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildPatternDots() {
    return List.generate(20, (index) {
      return Positioned(
        top: (constraints.maxHeight * (index * 0.15) % 1),
        left: (constraints.maxWidth * (index * 0.23) % 1),
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor.withValues(alpha: 0.1),
          ),
        ),
      );
    });
  }
}

class _LogoContainer extends StatelessWidget {
  final double imageSize;
  final Color primaryColor;

  const _LogoContainer({
    required this.imageSize,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 10,
            offset: const Offset(-5, -5),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            'assets/logo/badanbahasa.jpg',
            width: imageSize - 16,
            height: imageSize - 16,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.image_not_supported,
                  size: imageSize * 0.3,
                  color: Colors.grey,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}