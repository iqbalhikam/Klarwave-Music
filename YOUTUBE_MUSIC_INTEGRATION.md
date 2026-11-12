# YouTube Music & iTunes Integration

## 🎵 Overview

Implementasi sistem music discovery seperti MusicLabs **tanpa backend**. Semua API call dilakukan langsung dari Flutter client.

## ✨ Fitur yang Diimplementasikan

### 1. YouTube Music Integration
- ✅ Search musik langsung dari YouTube
- ✅ Streaming audio berkualitas tinggi (opus/m4a)
- ✅ Parsing metadata otomatis (artist, title)
- ✅ Trending/popular music discovery
- ✅ **Tanpa backend proxy** - menggunakan `youtube_explode_dart`

### 2. iTunes API Integration
- ✅ High-quality album artwork (hingga 600x600px)
- ✅ Metadata enhancement untuk track dari sumber lain
- ✅ Search musik dari iTunes catalog
- ✅ **Public API** - tidak perlu API key

### 3. Music Aggregator Enhancement
- ✅ Multi-source search (YouTube + Audius + Archive + Openverse + ccMixter)
- ✅ Automatic deduplication
- ✅ Metadata enhancement dengan iTunes API
- ✅ Trending music aggregation

## 📦 Dependencies Baru

```yaml
dependencies:
  youtube_explode_dart: ^2.2.1  # YouTube Music integration
```

Package lain sudah tersedia (`http` untuk iTunes API).

## 🏗️ Arsitektur

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                        │
├─────────────────────────────────────────────────────┤
│                 MusicAggregator                      │
├──────────┬──────────┬──────────┬────────────────────┤
│ YouTube  │  iTunes  │  Audius  │  Archive/Openverse │
│  Music   │   API    │   API    │     API            │
└──────────┴──────────┴──────────┴────────────────────┘
     ↓          ↓          ↓              ↓
   Direct    Direct    Direct         Direct
   Access    Access    Access         Access
```

**Tidak ada backend!** Semua API call dilakukan dari client.

## 🔧 Files yang Ditambahkan/Dimodifikasi

### Files Baru:
1. `lib/src/services/youtube_music_api.dart` - YouTube Music service
2. `lib/src/services/itunes_api.dart` - iTunes API service

### Files Dimodifikasi:
1. `lib/src/services/aggregator.dart` - Tambah YouTube & iTunes integration
2. `lib/src/providers.dart` - Provider untuk service baru
3. `lib/src/player/controller.dart` - Handle YouTube URL resolution
4. `lib/src/models.dart` - Tambah fields & copyWith method
5. `pubspec.yaml` - Tambah youtube_explode_dart dependency

## 🚀 Cara Menggunakan

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Search Musik
```dart
// Otomatis search dari semua sumber termasuk YouTube
final results = await aggregator.search('judul lagu');

// Search hanya dari YouTube
final youtubeResults = await aggregator.search('judul lagu', filter: 'youtube');

// Search hanya dari iTunes (untuk metadata)
final itunesResults = await aggregator.search('judul lagu', filter: 'itunes');
```

### 3. Get Trending Music
```dart
final trendingTracks = await aggregator.getTrending(limit: 30);
```

### 4. Enhance Metadata
```dart
// Upgrade artwork ke high-quality dari iTunes
final enhancedTrack = await aggregator.enhanceTrack(track);
```

### 5. Play YouTube Track
```dart
// Player otomatis resolve YouTube URL saat play
await playerController.playTrack(youtubeTrack);
```

## 🎯 Perbedaan dengan MusicLabs

| Feature | MusicLabs | Implementasi Ini |
|---------|-----------|------------------|
| **Backend** | Express.js custom API | ❌ Tidak perlu |
| **YouTube Music** | Via proxy server | ✅ Direct client access |
| **iTunes API** | Via backend | ✅ Direct client access |
| **Database** | Supabase PostgreSQL | ✅ Local storage saja |
| **Authentication** | Supabase Auth | ❌ Belum (opsional) |
| **Rate Limiting** | Upstash Redis | ✅ Client-side throttling |
| **Caching** | Server-side | ✅ Client-side (http cache) |

## ⚡ Performance Notes

### YouTube Music:
- ✅ Fast search (langsung ke YouTube API)
- ✅ Audio quality: opus > m4a > mp4 (otomatis pilih terbaik)
- ⚠️ Network intensive (streaming langsung dari YouTube)

### iTunes API:
- ✅ Public API tanpa rate limit ketat
- ✅ High-quality artwork (600x600 - 1400x1400)
- ⚠️ Preview audio saja (30 detik) - gunakan untuk metadata only

### Recommendations:
- Gunakan YouTube Music untuk streaming penuh
- Gunakan iTunes API untuk enhance artwork
- Combine keduanya untuk hasil terbaik

## 🔐 Privacy & Legal

### Tanpa Backend = Lebih Privacy-Friendly:
- ✅ Tidak ada tracking server
- ✅ Tidak ada logging activity
- ✅ Request langsung ke source

### Legal Disclaimer:
- YouTube Music: Personal use only (sesuai Terms of Service)
- iTunes API: Public API untuk search/preview
- Artwork: © Pemilik hak cipta masing-masing

## 🐛 Troubleshooting

### YouTube Playback Gagal:
```dart
// Error: "Gagal mendapatkan YouTube audio URL"
// Kemungkinan: Video restricted atau blocked
// Solusi: Fallback ke sumber lain atau skip track
```

### iTunes API Timeout:
```dart
// Enhancement timeout tidak masalah (silent fail)
// Track tetap playable tanpa enhanced metadata
```

### Out of Memory:
```dart
// Jika terlalu banyak concurrent requests:
// Batasi limit search per-source
final results = await aggregator.search(
  'query',
  limit: 30, // Reduce jika perlu
);
```

## 📝 Next Steps (Optional)

Untuk fitur tambahan seperti MusicLabs:

1. **AI Discover Weekly**: Integrate Google Gemini API
2. **Lyrics**: Gunakan `lyrics_api.dart` yang sudah ada
3. **Social Features**: Add Supabase (optional)
4. **Audio Recognition**: Integrate AudD API (optional)

## 🎉 Kesimpulan

Implementasi ini memberikan:
- ✅ Music discovery seperti MusicLabs
- ✅ **100% client-side** (no backend)
- ✅ High-quality artwork dari iTunes
- ✅ Full streaming dari YouTube Music
- ✅ Multi-source aggregation
- ✅ Privacy-friendly architecture

**Ready to use!** Jalankan `flutter pub get` dan aplikasi siap digunakan.
