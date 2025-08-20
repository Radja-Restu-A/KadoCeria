// lib/widgets/language_card.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book_model.dart';
import '../../provider/language_provider.dart';


class LanguageCardWidget extends StatelessWidget {
  final String description;
  final String language;
  final Language languageEnum;
  final VoidCallback? onTap;
  final double? height;
  final EdgeInsets? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? textColor;

  const LanguageCardWidget({
    Key? key,
    required this.description,
    required this.language,
    required this.languageEnum,
    this.onTap,
    this.height = 200,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.backgroundColor,
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _defaultOnTap(context),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(borderRadius!),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: padding!,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: AutoSizeText(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  minFontSize: 8,
                  maxLines: 4,
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    language,
                    style: TextStyle(
                      fontSize: 18,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _defaultOnTap(BuildContext context) {
    context.read<LanguageProvider>().setLanguage(languageEnum);
  }
}