import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:page_flip/page_flip.dart';
import '../viewmodels/book_viewmodel.dart';

class FlipbookView extends StatefulWidget {
  final String bookId;

  const FlipbookView({Key? key, required this.bookId}) : super(key: key);

  @override
  _FlipbookViewState createState() => _FlipbookViewState();
}

class _FlipbookViewState extends State<FlipbookView> {
  final GlobalKey<PageFlipWidgetState> _pageFlipKey = GlobalKey<PageFlipWidgetState>();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookViewModel>(
      builder: (context, bookViewModel, child) {
        final book = bookViewModel.getBookById(widget.bookId);

        if (book == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Book Not Found'),
              backgroundColor: Color(0xFF4FC3F7),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Book not found'),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Color(0xFF4FC3F7),
          appBar: AppBar(
            backgroundColor: Color(0xFF4FC3F7),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              book.title + (book.subtitle.isNotEmpty ? ' ${book.subtitle}' : ''),
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.book,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16),
                  child: PageFlipWidget(
                    key: _pageFlipKey,
                    backgroundColor: Colors.white,
                    lastPage: Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Selesai membaca!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    children: book.pages.asMap().entries.map((entry) {
                      int index = entry.key;
                      String pagePath = entry.value;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            pagePath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                        size: 48,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Halaman ${index + 1} tidak ditemukan',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Fitur audio akan segera tersedia'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF81C784),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Dengarkan Seluruh Buku',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _currentPage > 0
                                ? () {
                              setState(() {
                                if (_currentPage > 0) _currentPage--;
                              });
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentPage > 0
                                  ? Color(0xFF81C784)
                                  : Colors.grey[300],
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: CircleBorder(),
                              padding: EdgeInsets.zero,
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              size: 24,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 50,
                            margin: EdgeInsets.symmetric(horizontal: 16),
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Mendengarkan halaman ${_currentPage + 1}'),
                                    backgroundColor: Color(0xFF81C784),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF81C784),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                'Dengarkan Halaman Ini',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _currentPage < book.pages.length - 1
                                ? () {
                              setState(() {
                                if (_currentPage < book.pages.length - 1) _currentPage++;
                              });
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentPage < book.pages.length - 1
                                  ? Color(0xFF81C784)
                                  : Colors.grey[300],
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: CircleBorder(),
                              padding: EdgeInsets.zero,
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
