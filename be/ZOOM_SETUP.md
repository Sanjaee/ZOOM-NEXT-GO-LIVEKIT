# Setup Zoom/Video Call dengan LiveKit

## Backend Setup

### 1. Install Dependencies

```bash
cd be
go mod tidy
```

### 2. Environment Variables

Tambahkan ke file `.env`:

```env
# LiveKit Configuration
LIVEKIT_URL=wss://livekit:7880
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
```

### 3. Database Migration

Database akan otomatis di-migrate saat server start. Model yang akan dibuat:
- `rooms` - tabel untuk room video call
- `room_participants` - tabel many-to-many untuk relasi room dan user

### 4. Run dengan Docker Compose

```bash
docker-compose up -d
```

Ini akan menjalankan:
- PostgreSQL database
- Redis
- RabbitMQ
- LiveKit server
- Backend Go API

### 5. API Endpoints

#### Create Room
```
POST /api/v1/rooms
Authorization: Bearer <token>
Body: {
  "name": "Room Name",
  "description": "Optional description",
  "max_participants": 10
}
```

#### Get All Rooms
```
GET /api/v1/rooms
```

#### Get Room by ID
```
GET /api/v1/rooms/:id
```

#### Join Room (Get LiveKit Token)
```
POST /api/v1/rooms/:id/join
Authorization: Bearer <token>
Response: {
  "token": "livekit_jwt_token",
  "url": "wss://livekit:7880",
  "room": { ... }
}
```

#### Get My Rooms
```
GET /api/v1/rooms/my
Authorization: Bearer <token>
```

#### Delete Room
```
DELETE /api/v1/rooms/:id
Authorization: Bearer <token>
```

## Frontend Setup

### 1. Install Dependencies

```bash
cd fe
npm install livekit-client
```

### 2. Environment Variables

Tambahkan ke file `.env.local`:

```env
NEXT_PUBLIC_API_URL=http://localhost:5000
```

### 3. Pages

- `/zoom` - List semua rooms dan create room baru
- `/zoom/[roomId]` - Join ke room dan video call

### 4. Run Development Server

```bash
npm run dev
```

## Struktur Database

### Room Model
- `id` (UUID) - Primary key
- `name` (string) - Nama room
- `description` (text, optional) - Deskripsi room
- `created_by_id` (UUID) - Foreign key ke users
- `is_active` (boolean) - Status aktif room
- `max_participants` (integer, optional) - Maksimal peserta
- `created_at`, `updated_at` - Timestamps

### RoomParticipant Model
- `room_id` (UUID) - Foreign key ke rooms
- `user_id` (UUID) - Foreign key ke users
- `joined_at` (timestamp) - Waktu join
- `left_at` (timestamp, optional) - Waktu leave
- `is_active` (boolean) - Status aktif

## Cara Menggunakan

1. **Login** ke aplikasi untuk mendapatkan access token
2. **Buat Room** baru di halaman `/zoom`
3. **Join Room** dengan klik tombol "Gabung Room" atau akses langsung `/zoom/[roomId]`
4. **Video Call** akan otomatis connect ke LiveKit server
5. **Toggle Mic/Camera** menggunakan tombol di bawah
6. **Leave Room** dengan klik tombol phone off

## Troubleshooting

### LiveKit tidak connect
- Pastikan LiveKit server running di docker
- Check environment variables LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET
- Pastikan port 7880, 7881, 7882 terbuka

### Token generation error
- Pastikan LIVEKIT_API_KEY dan LIVEKIT_API_SECRET sesuai dengan livekit.yaml
- Check apakah user sudah login dan memiliki valid token

### Video tidak muncul
- Pastikan browser memberikan izin untuk camera dan microphone
- Check console untuk error messages
- Pastikan LiveKit server accessible dari browser

