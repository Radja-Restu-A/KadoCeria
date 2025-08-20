import 'package:flutter/material.dart';
import 'package:kado_ceria/provider/teks_provider.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../models/book_model.dart';
import '../../provider/book_views_provider.dart';
import '../../provider/language_provider.dart';
import 'book_description_modal_widget.dart';

class BookCardWidget extends StatefulWidget {
  final BookModel book;
  final VoidCallback onTap;

  const BookCardWidget({
    Key? key,
    required this.book,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BookCardWidget> createState() => _BookCardWidgetState();
}

class _BookCardWidgetState extends State<BookCardWidget> {
  @override
  void initState() {
    super.initState();
    // Initialize views immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookViewsProvider>().initViews(widget.book.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<BookViewsProvider>().incrementViews(widget.book.id);
        widget.onTap();
      },
      child : Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return Container(
            decoration: BoxDecoration(
              color: widget.book.primaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                    children:[
                      Row(
                        children: [
                          Flexible(
                              flex: 2,
                              child: Stack(
                                  children: [
                                    SizedBox(
                                      height: 160,
                                      child:
                                      Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 100,
                                              height: 155,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                color: widget.book.secondaryColor,
                                              ),
                                              child: Stack(
                                                  children: [
                                                    Align(
                                                      alignment: Alignment(0.35, -0.90),
                                                      child: Transform.rotate(
                                                        angle: 0.12,
                                                        child:
                                                        Container(
                                                          width: 80,
                                                          height: 80,
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(20),
                                                            color: widget.book.primaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment: Alignment(0, -0.77),
                                                      child: Container(
                                                        width: 80,
                                                        height: 80,
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(20),
                                                          color: widget.book.primaryColor,
                                                          image: DecorationImage(
                                                            image: AssetImage(widget.book.coverImagePath),
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment: Alignment(-0.58, 0.58),
                                                      child: Container(
                                                        width: 20,
                                                        height: 20,
                                                        decoration: BoxDecoration(
                                                            color: widget.book.primaryColor,
                                                            shape: BoxShape.circle
                                                        ),
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment: Alignment(0.58,0.78),
                                                      child: Container(
                                                        width: 13,
                                                        height: 13,
                                                        decoration: BoxDecoration(
                                                            color: widget.book.primaryColor,
                                                            shape: BoxShape.circle
                                                        ),
                                                      ),
                                                    )
                                                  ]
                                              ),
                                            ),
                                            // SizedBox(height: 8),
                                          ]
                                      ),
                                    )
                                  ]
                              )
                          ),

                          // Book Cover
                          SizedBox(width: 16),
                          // Book Details
                          Flexible(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Replace the existing SizedBox and Text widget for the title with this:
                                SizedBox(
                                  height: 50,
                                  child: AutoSizeText(
                                    widget.book.getTitle(languageProvider.selectedLanguage),
                                    maxLines: 2,
                                    minFontSize: 12,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: widget.book.secondaryColor,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
                                        showDialog(
                                          context: context,
                                          builder: (context) => BookDescriptionModalWidget(
                                            description: widget.book.getDescription(languageProvider.selectedLanguage),
                                            backgroundColor: widget.book.primaryColor,
                                            language: languageProvider.selectedLanguage,
                                            title: "Sinopsis",
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: AutoSizeText(
                                          widget.book.getDescription(languageProvider.selectedLanguage),
                                          textAlign: TextAlign.justify,
                                          maxLines: 5,
                                          minFontSize: 10,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 60,
                        width: double.infinity,
                        child: Stack( // Wrap in Stack to allow Positioned
                          children: [
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: widget.book.primaryColor,
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(0, 12, 0, 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        '${TeksProvider.getString('author', languageProvider.selectedLanguage)}   : ${widget.book.author}',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        )
                                    ),
                                    Text(
                                        'Ilustrator: ${widget.book.illustrator}',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        )
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Consumer<BookViewsProvider>(
                                builder: (context, provider, child) {
                                  return FutureBuilder<int>(
                                    future: provider.viewsFutures[widget.book.id],
                                    builder: (context, snapshot) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.remove_red_eye,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '${snapshot.data ?? 0}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    ]
                )
            ),
          );
        },
      ),
    );
  }
}