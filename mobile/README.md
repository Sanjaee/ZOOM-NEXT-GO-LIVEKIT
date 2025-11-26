lib/
 ├── main.dart
 ├── app.dart
 ├── core/
 │    ├── constants/
 │    │     ├── colors.dart
 │    │     └── text_styles.dart
 │    ├── utils/
 │    │     └── validators.dart
 │    └── widgets/
 │          ├── primary_button.dart
 │          └── input_field.dart
 │
 ├── data/
 │    ├── models/
 │    ├── services/
 │    └── repository/
 │
 ├── features/
 │    ├── auth/
 │    │     ├── pages/
 │    │     ├── controllers/
 │    │     └── widgets/
 │    └── home/
 │          ├── pages/
 │          ├── controllers/
 │          └── widgets/
 │
 └── routes/
       └── app_routes.dart

Sedikit folder, tidak bikin pusing.

Scalable, mirip pola Clean Architecture tapi versi ringan.

Setiap fitur terpisah (auth, home, dashboard).

Reusable, widget & helper tidak campur dengan fitur.

Mudah dibaca, developer lain langsung paham.

Penjelasan Singkat (biar gampang ingat)
✔️ core/

Hal-hal yang bisa dipakai di seluruh aplikasi
→ warna, text style, widget kecil (Button, InputField)

✔️ data/

Semua yang berkaitan dengan data
→ API service, model JSON, local storage

✔️ features/

Folder utama berisi fitur
→ Auth, Home, Profile, dll
Masing-masing punya pages, controller, widget

✔️ routes/

Semua routing aplikasi di satu file
→ AppRoutes