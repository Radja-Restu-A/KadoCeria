# Fix Book Bugs and Add Download/Delete Features - Walkthrough

I have addressed the reported bugs and implemented the new features for book management.

## Changes Made

### 1. ID 1 & 2 Visibility Fix
- Modified `BookViewModel.loadDashboardCatalog` to include all books from the network, even if their IDs match the bundled books (like ID 1 and 2).
- Network books will now appear in the **"Discover"** section if not yet downloaded, while bundled books remain in **"My Library"**.

### 2. View Count Logic
- Hidden the view count (eye icon) for all network-fetched books in [book_card_widget.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/views/widgets/book_card_widget.dart).
- Disabled the view increment logic for non-bundled books.

### 3. Download Features
- Added a **confirmation popup** before downloading a book, which displays the **file size** (e.g., "Ukuran file: 15 MB").
- Implemented a **non-cancelable loading dialog** that stays on screen during the download and extraction process.

### 4. Delete Feature
- Added a **delete icon** to downloaded network books in the book card.
- Implemented a **delete confirmation popup** to prevent accidental deletions.
- Added logic in `BookService` and `BookViewModel` to physically remove the extracted book files and reset the download status.

### 5. Multi-Source Loading
- Updated `BookService.loadBookById` to support loading books from either bundled assets or the local filesystem.
- Updated `FlipbookViewModel` and `FlipbookScreen` to pass the `isBundled` flag correctly, ensuring images and audio are loaded from the correct source.

## Verification Summary

### Manual Verification Steps
1. **Sync Check**: Verify that books with ID 1 or 2 from the API now show up in "Discover".
2. **View Hide**: Check a network book; the eye icon should be gone.
3. **Download Flow**:
    - Click download -> Confirmation shows with file size.
    - Click confirm -> Loading overlay appears and waits.
    - Finish -> Book moves to "My Library".
4. **Read Flow**: Open a downloaded book; verify all content (images/audio) loads correctly from the device storage.
5. **Delete Flow**:
    - Click delete on a downloaded book -> Confirmation shows.
    - Click confirm -> Book returns to "Discover".
    - Verify files are actually deleted (simulated by checking if it can be downloaded again).

### Syntax & Type Safety
- Checked for syntax errors using `analyze_file` across all modified files.
- Fixed several type mismatch errors in `BookCardWidget` regarding `Language` enum comparisons.
