# Fix: Downloaded Books Not Appearing Offline

The issue is that `BookViewModel` only populates the catalog from bundled assets and the network API. When offline, the network API fails, and only bundled books are shown. Downloaded books, which are stored in the application's documents directory, are not automatically scanned and added to the catalog when the network is unavailable. Additionally, the `BookCardWidget` does not support displaying cover images from local file paths.

## User Review Required

- **Data Consistency**: The metadata for downloaded books will be read from the `data.json` file inside each book's folder. I've mapped the keys based on `BookModelBundle.fromJson`.
- **Duplicate Handling**: I will use book IDs for deduplication to ensure books don't appear twice if they are both in the local storage and returned by the (eventually successful) network call.

## Proposed Changes

### [Book Service]

Add a method to scan the local storage for downloaded books and reconstruct their summary metadata.

#### [book_service.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/services/book_service.dart)

- Add `fetchDownloadedBooksMetadata()` to scan `${appDocDir}/books/` and read `data.json` for each folder.
- Ensure it returns a `List<BookSummaryModel>`.

### [Book ViewModel]

Update the catalog loading logic to include downloaded books.

#### [book_viewmodel.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/viewmodels/book_viewmodel.dart)

- In `loadDashboardCatalog()`, call `_bookService.fetchDownloadedBooksMetadata()`.
- Merge the results into the `_books` list, ensuring no duplicates (using `idBuku`).

### [Book Card Widget]

Support displaying cover images from local absolute file paths.

#### [book_card_widget.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/views/widgets/book_card_widget.dart)

- Import `dart:io`.
- Update `DecorationImage` to check if `coverImagePath` is an absolute local path (e.g., starts with `/`) and use `FileImage` if so.

---

## Verification Plan

### Manual Verification
- **Test 1: Offline Catalog**:
    1. Download a book while online.
    2. Turn off internet.
    3. Restart the app.
    4. Verify that the downloaded book still appears in the catalog.
- **Test 2: Offline Reading**:
    1. Click "BACA" on the downloaded book while offline.
    2. Verify the book opens and images/audio load correctly (already supported but good to double check).
- **Test 3: Cover Image**:
    1. Verify the cover image for the downloaded book is displayed correctly while offline.
