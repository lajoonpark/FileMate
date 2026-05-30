# FileMate ✨

A native macOS app that helps you manage your files — organize messy folders into clean subfolders and search for any file on your system.

---

## Features

### Organize
- **Drag-and-drop or pick a folder** — drop any folder onto the window or click "Choose Folder"
- **Dry-run preview** — see exactly where every file will go before anything moves
- **Selective organization** — uncheck individual files to skip them
- **Undo all** — one click reverts every move; the log is saved to disk
- **Custom rules** — edit which extensions map to which category via the "Rules…" panel
- **Recursive mode** — optionally organize files inside sub-folders too
- **Collision-safe** — duplicate names get `_1`, `_2`, … suffixes, never overwritten

### Search
- **Find any file** — search every file by name inside any folder on your Mac
- **Live results** — results stream in as the search runs, with file size and modification date
- **Quick actions** — Reveal in Finder or Open directly from search results
- **Scoped search** — pick any folder as the search root

### Default categories

| Category   | Extensions |
|------------|------------|
| Images     | jpg, jpeg, png, gif, heic, webp, svg, raw, tiff, bmp |
| Videos     | mp4, mov, avi, mkv, m4v, wmv, flv |
| Audio      | mp3, aac, flac, wav, m4a, ogg, opus |
| Documents  | pdf, doc, docx, xls, xlsx, ppt, pptx, txt, md, rtf, pages, numbers, key, odt, csv |
| Archives   | zip, tar, gz, bz2, rar, 7z, xz, dmg, pkg |
| Code       | swift, py, js, ts, html, css, json, yaml, sh, rb, go, rs, c, cpp, h, java, kt, xml |
| Screenshots | files whose name starts with "Screenshot" or "Screen Shot" |
| Others     | everything else |

---

## Requirements

- macOS 13 Ventura or later
- Xcode 15+ (to build from source)

---

## Build & Run

1. Clone the repo:
   ```bash
   git clone https://github.com/lajoonpark/file-cleaner.git
   cd file-cleaner
   ```
2. Open the project in Xcode:
   ```bash
   open FileCleaner.xcodeproj
   ```
3. Select the **FileCleaner** scheme and press **⌘R** to run, or **⌘B** to build.

### Export a standalone `.app`

1. In Xcode: **Product → Archive**
2. Click **Distribute App → Copy App**
3. Zip the exported `FileMate.app` and share it

> **Unsigned builds:** right-click → Open the first time to bypass Gatekeeper.

---

## User Flow

### Organize mode
```
Launch → Organize tab
  └─ Drop / Choose Folder
       └─ Scanning spinner
            └─ Preview Table (File | Category | Will Move To)
                 └─ [Uncheck to skip]  [Run Organizer]
                      └─ Progress bar
                           └─ Done! N files organized
                                └─ [Undo All]  [Open Folder]  [Done]
```

### Search mode
```
Launch → Search tab
  └─ Type a file name
       └─ Live streaming results (name, path, size, date)
            └─ [Reveal in Finder]  [Open]
```

---

## Project Structure

```
FileCleaner.xcodeproj
FileCleaner/
├── App/
│   └── FileCleanerApp.swift        # @main entry point
├── Views/
│   ├── ContentView.swift           # mode switcher (Organize / Search) + organize state machine
│   ├── FolderPickerView.swift      # drop zone + NSOpenPanel
│   ├── PreviewView.swift           # sortable Table with checkboxes
│   ├── CleanProgressView.swift     # done / undo screen
│   ├── RulesEditorView.swift       # edit category → extension mappings
│   └── SearchView.swift            # live file search with streaming results
├── Models/
│   ├── FileItem.swift              # one file + proposed destination
│   └── OrganizationRule.swift      # category with extension list
├── Services/
│   ├── FileScanner.swift           # walks the selected directory
│   ├── FileOrganizer.swift         # moves files, tracks progress
│   └── AppUndoManager.swift        # persists & replays move log
└── Resources/
    └── Assets.xcassets
```
