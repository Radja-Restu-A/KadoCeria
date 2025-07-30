import 'package:flutter/material.dart';
import 'package:kado_ceria/provider/teks_provider.dart';
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../provider/language_provider.dart';

class BookCardWidget extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;

  const BookCardWidget({
    Key? key,
    required this.book,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child : Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return Container(
            decoration: BoxDecoration(
              color: book.primaryColor,
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
                                              height: 135,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                color: book.secondaryColor,
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
                                                            color: book.primaryColor,
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
                                                          color: book.primaryColor,
                                                          image: DecorationImage(
                                                            image: AssetImage(book.coverImagePath),
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
                                                            color: book.primaryColor,
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
                                                            color: book.primaryColor,
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
                                SizedBox(
                                  height: 50,
                                  child: Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Text(
                                        book.getTitle(languageProvider.selectedLanguage),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: book.secondaryColor,
                                  ),
                                  child:Padding(
                                      padding: EdgeInsets.all(8),
                                      child: SingleChildScrollView(
                                          child:
                                          RichText(
                                            textAlign: TextAlign.justify,
                                            text: TextSpan(
                                              children: [
                                                WidgetSpan(child: SizedBox(width: 20)), // indentasi
                                                TextSpan(
                                                  text: book.getDescription(languageProvider.selectedLanguage),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                      )
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
                          child:Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: book.primaryColor,
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(0,12,0,4),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        '${TeksProvider.getString('author', languageProvider.selectedLanguage)}   : ${book.author}',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        )
                                    ),
                                    Text(
                                        'Ilustrator: ${book.illustrator}',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        )
                                    ),
                                  ]
                              ),
                            ),
                          )
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