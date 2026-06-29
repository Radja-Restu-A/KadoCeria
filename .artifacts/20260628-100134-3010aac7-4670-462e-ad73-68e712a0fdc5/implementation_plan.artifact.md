# Fix Book Bugs and Add Download/Delete Features

This plan addresses several bugs and feature requests related to book management in the KadoCeria app, including book visibility issues, view count logic, download confirmations with file size, loading indicators, and a delete option.

## User Review Required

- **ID 1 & 2 Conflict**: Books with ID 1 or 2 from the network will now appear separately from the bundled ones (if they differ). They will show up in the "Discover" section if not downloaded.
- **View Count**: View counts will be hidden and not incremented for network books as requested.
- **Loading Popup**: A non-cancelable loading dialog will be shown during the download process.

## Proposed Changes

### Models

#### [book_model_bundle.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/models/book_model_bundle.dart)
- No major changes needed, but ensure `BookSummaryModel` can be identified as bundled via `fileSize == 'Bundled'`.

---

### Services

#### [book_service.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/services/book_service.dart)
- Update `loadBookById` and `getBook` to accept an `isBundled` parameter to load from either assets or filesystem.
- Add `deleteBook` method to remove extracted book files.

#### [local_storage_service.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/services/local_storage_service.dart)
- Fix the `isBookDownloaded` method to remove the hardcoded ID checks that might conflict with new logic.

---

### ViewModels

#### [book_viewmodel.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/viewmodels/book_viewmodel.dart)
- Update `loadDashboardCatalog` to:
    - Include all books from the network even if IDs match bundled ones.
    - Resolve status based on `fileSize == 'Bundled'`.
- Add `getBookState` helper.
- Add `deleteDownloadedBook` method.

#### [flipbook_viewmodel.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/viewmodels/flipbook_viewmodel.dart)
- Update `loadStory` to accept and pass `isBundled` to the repository.

---

### Repositories

#### [story_repository.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/repositories/story_repository.dart)
- Update `getStory` and `getBookById` to accept `isBundled`.

---

### Views & Widgets

#### [dashboard_screen.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/views/screens/dashboard_screen.dart)
- Implement download confirmation dialog with file size.
- Implement loading dialog during download.
- Implement delete confirmation dialog.
- Pass `isBundled` flag to `FlipbookScreen`.

#### [flipbook_screen.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/views/screens/flipbook_screen.dart)
- Accept and pass `isBundled` to the ViewModel.

#### [book_card_widget.dart](file:///C:/Users/LuckyNutz/Documents/SoftwareDevelop/Flutter/KadoCeria/lib/views/widgets/book_card_widget.dart)
- Conditionally hide and disable view count logic for non-bundled books.
- Add a delete icon/button for downloaded network books.

## Verification Plan

### Automated Tests
- Not applicable for UI changes, but I will check for syntax errors using `analyze_file`.

### Manual Verification
1. **ID 1 & 2 Visibility**: Verify that if the API returns a book with ID 1, it appears in the "Discover" section (if not downloaded) even though ID 1 is also in "My Library" (bundled).
2. **View Count**: Verify that network books do not show the eye icon/count.
3. **Download Popup**: Click download on a network book and verify the confirmation dialog shows the correct file size.
4. **Loading Popup**: Confirm a loading dialog appears and stays until the download finishes.
5. **Delete Book**: Download a book, then use the new delete option. Verify the confirmation popup appears and the book returns to "NOT_DOWNLOADED" status after deletion.
6. **Open Downloaded Book**: Verify that a downloaded network book (including ID 1/2 updates) opens correctly and displays content from the filesystem.
