// lib/shared/models/mock_data.dart
import 'models.dart';

class MockData {
  MockData._();

  static const UserModel currentUser = UserModel(
    id: 'user-001',
    name: 'Budi Santoso',
    email: 'budi@example.com',
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
    type: UserType.individu,
    isVerified: true,
    bio:
        'Passionate about community resilience and helping neighbors in need. Joined in 2022.',
    donationCount: 12,
    pointsHelped: 8,
    totalDonation: 2500000,
    communityPoints: 450,
  );

  static const List<DonationRequest> activeRequests = [
    DonationRequest(
      id: 'req-001',
      title: 'Tabung Oksigen / Isi Ulang',
      description:
          'Mohon bantuannya, orang tua saya sedang sesak napas butuh oksigen segera. Posisi di Jl. Kaliurang KM 5, dekat warung Bu Agus. Jika ada info pengisian yang buka 24 jam atau pinjaman tabung, mohon kabari.',
      authorName: 'Sarah J.',
      authorAvatar: 'https://i.pravatar.cc/150?img=5',
      urgency: UrgencyLevel.urgent,
      status: RequestStatus.open,
      category: 'Medical Supplies',
      location: 'Jl. Kaliurang KM 5',
      distanceKm: 0.3,
      timeAgo: '30 menit yang lalu',
      imageUrl: null,
      goalAmount: 2,
      collectedAmount: 1,
      goalText: 'Goal: 2 Buah',
      tags: ['#MedicalSupplies', '#Emergency', '#Oksigen'],
    ),
    DonationRequest(
      id: 'req-002',
      title: 'Nasi Bungkus & Air Mineral',
      description:
          'Untuk warga terdampak luapan sungai di RW 04. Kami butuh sekitar 20 porsi nasi bungkus untuk makan malam anak-anak dan lansia di posko sementara. Terima kasih banyak',
      authorName: 'Trikarta',
      authorAvatar: 'https://i.pravatar.cc/150?img=8',
      urgency: UrgencyLevel.urgent,
      status: RequestStatus.open,
      category: 'Medical Supplies',
      location: 'Posko RW 04 Sleman',
      distanceKm: 10,
      timeAgo: '2 jam yang lalu',
      tags: ['#FoodAid', '#Banjir', '#Emergency'],
    ),
    DonationRequest(
      id: 'req-003',
      title: 'Bantuan Sembako Warga Isolasi',
      description:
          'Paket sembako untuk 50 keluarga yang sedang melakukan isolasi mandiri di wilayah RW 07.',
      authorName: 'Pak RT 03',
      authorAvatar: 'https://i.pravatar.cc/150?img=3',
      urgency: UrgencyLevel.normal,
      status: RequestStatus.onProgress,
      category: 'Food & Water',
      location: 'RW 07, Condong Catur',
      distanceKm: 2.5,
      timeAgo: '1 hari yang lalu',
      imageUrl:
          'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=400',
      goalAmount: 5000000,
      collectedAmount: 2500000,
      tags: ['#Sembako', '#Isolasi'],
    ),
    DonationRequest(
      id: 'req-004',
      title: 'Obat-obatan Puskesmas Desa',
      description:
          'Membutuhkan stok obat-obatan dasar untuk puskesmas desa yang kehabisan stok.',
      authorName: 'dr. Hani',
      authorAvatar: 'https://i.pravatar.cc/150?img=9',
      urgency: UrgencyLevel.normal,
      status: RequestStatus.open,
      category: 'Medical',
      location: 'Puskesmas Desa Maguwo',
      distanceKm: 5.1,
      timeAgo: '3 jam yang lalu',
      tags: ['#Medis', '#Obat'],
    ),
  ];

  static const List<FeedPost> communityFeed = [
    FeedPost(
      id: 'post-001',
      authorName: 'Ahmad Ridwan',
      authorRole: 'Relawan',
      content:
          'Alhamdulilah, distribusi bantuan sembako untuk warga Desa Sukamaju yang terdampak banjir telah selesai hari ini. Terima kasih kepada semua donatur yang telah berpartisipasi! Mari terus tebar kebaikan. 🙏',
      timeAgo: '2 jam yang lalu',
      type: FeedPostType.updateKomunitas,
      imageUrl:
          'https://images.unsplash.com/photo-1593113598332-cd288d649433?w=400',
      likes: 142,
      comments: 24,
    ),
    FeedPost(
      id: 'post-002',
      authorName: 'Budi Santoso',
      authorRole: 'Pengurus Panti',
      content:
          'Peralatan Sekolah untuk Panti Asuhan Harapan\n\nTahun ajaran baru akan segera dimulai, namun masih banyak anak-anak di Panti Asuhan Harapan yang belum memiliki peralatan sekolah yang memadai. Kami membutuhkan donasi berupa buku tulis, pensil, pulpen, tas, dan seragam sekolah layak pakai. Setiap bantuan sangat berarti bagi mereka.',
      timeAgo: '4 jam yang lalu',
      type: FeedPostType.bantuanDibutuhkan,
      likes: 0,
      comments: 12,
      tagLabel: 'BANTUAN DIBUTUHKAN',
    ),
    FeedPost(
      id: 'post-003',
      authorName: 'Siti Aminah',
      authorRole: 'Donatur',
      content:
          'Cara mendonasikan pakaian layak pakai?\n\nHalo teman-teman, saya punya beberapa dus pakaian layak pakai anak-anak dan dewasa. Apakah ada panti asuhan atau posko terdekat di area Jakarta Selatan yang sedang membutuhkan? Mohon infonya ya.',
      timeAgo: '5 jam yang lalu',
      type: FeedPostType.pertanyaan,
      likes: 56,
      comments: 18,
      tagLabel: 'PERTANYAAN',
    ),
    FeedPost(
      id: 'post-004',
      authorName: 'Komunitas Peduli Lingkungan',
      authorRole: 'Organisasi',
      content:
          'Aksi bersih-bersih Sungai Ciliwung akhir pekan lalu berjalan sukses! Lebih dari 1 ton sampah berhasil dikumpulkan dengan bantuan 60+ relawan yang luar biasa. Terima kasih semuanya! 💚♻️',
      timeAgo: '6 jam yang lalu',
      type: FeedPostType.updateKomunitas,
      imageUrl:
          'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=400',
      likes: 205,
      comments: 32,
      tagLabel: 'UPDATE KOMUNITAS',
    ),
    FeedPost(
      id: 'post-005',
      authorName: 'Dian Pertiwi',
      authorRole: 'Relawan · Kemarin',
      content:
          'Menjadi relawan pengajar di daerah terpencil benar-benar membuka mata saya. Melihat semangat belajar anak-anak di tengah keterbatasan fasilitas sungguh luar biasa. Senyum mereka adalah bayaran yang tak ternilai harganya. Mari kita terus mendukung pendidikan anak bangsa. 📚',
      timeAgo: 'Kemarin',
      type: FeedPostType.inspirasi,
      likes: 310,
      comments: 45,
      tagLabel: 'INSPIRASI',
    ),
    FeedPost(
      id: 'post-006',
      authorName: 'Riza Fahlevi',
      authorRole: 'Calon Donatur · Kemarin',
      content:
          'Bagaimana cara menjadi donatur tetap?\n\nSaya ingin berkontribusi lebih rutin untuk program-program Community Aid. Adakah sistem autodebet atau cara mudah untuk mendaftar sebagai donatur bulanan? Terima kasih sebelumnya.',
      timeAgo: 'Kemarin',
      type: FeedPostType.pertanyaan,
      likes: 8,
      comments: 3,
      tagLabel: 'PERTANYAAN',
    ),
    FeedPost(
      id: 'post-007',
      authorName: 'Keluarga Bapak Maman',
      authorRole: 'Penerima Manfaat · 2 Hari yang lalu',
      content:
          'Berkat bantuan modal usaha dari para donatur Community Aid, warung kelontong kami kini kembali beroperasi dan omzetnya bahkan berlipat ganda. 🙏',
      timeAgo: '2 hari yang lalu',
      type: FeedPostType.kisahSukses,
      likes: 452,
      comments: 89,
      tagLabel: 'KISAH SUKSES',
    ),
  ];

  static const List<ActivityItem> recentActivity = [
    ActivityItem(
      id: 'act-001',
      title:
          'Penyaluran Berhasil: Bantuan sembako telah diterima oleh warga RW 02.',
      subtitle: '',
      timeAgo: '2 hours ago',
      iconType: 'success',
    ),
    ActivityItem(
      id: 'act-002',
      title:
          'Donasi Masuk: Seseorang mendonasikan Rp 500.000 untuk Obat-obatan Puskesmas.',
      subtitle: '',
      timeAgo: '5 hours ago',
      iconType: 'donation',
    ),
    ActivityItem(
      id: 'act-003',
      title:
          'Request Baru: Penggalangan dana untuk perbaikan atap madrasah dimulai.',
      subtitle: '',
      timeAgo: '1 day ago',
      iconType: 'request',
    ),
  ];

  static const List<DonationHistory> donationHistory = [
    DonationHistory(
      id: 'hist-001',
      requestId: '#AID-2023-11A',
      title: 'Perbaikan Atap Sekolah Dasar 04',
      status: RequestStatus.onProgress,
      category: 'Infrastruktur',
      timeStr: 'Today, 09:30 AM',
      updates: [
        StatusUpdate(
          dateStr: 'Today, 09:30 AM',
          description:
              'Material bangunan tahap kedua telah tiba di lokasi. Proses pemasangan rangka atap dimulai.',
          isActive: true,
        ),
        StatusUpdate(
          dateStr: 'Oct 24, 2023',
          description:
              'Dana tahap pertama berhasil dicairkan. Pembongkaran atap lama selesai.',
          isActive: false,
        ),
      ],
      docImages: [
        'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=200',
        'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=200',
      ],
    ),
    DonationHistory(
      id: 'hist-002',
      requestId: '#AID-2023-08B',
      title: 'Distribusi Sembako Desa Mandiri',
      status: RequestStatus.completed,
      category: 'Pangan',
      timeStr: 'Sep 15, 2023',
      updates: [
        StatusUpdate(
          dateStr: 'Sep 15, 2023',
          description:
              'Distribusi 500 paket sembako selesai dilakukan. Laporan pertanggungjawaban telah diunggah.',
          isActive: true,
        ),
      ],
      docImages: [
        'https://images.unsplash.com/photo-1593113598332-cd288d649433?w=200',
      ],
    ),
  ];

  static const List<AdminReport> adminReports = [
    AdminReport(
      id: '#REP-9921',
      title: 'Pola Aktivitas Mencurigakan',
      description: 'Beberapa percobaan login gagal dari IP tidak dikenal.',
      statusLabel: 'Sedang Diproses',
      statusColor: 'orange',
      timeAgo: '10 menit yang lalu',
      iconType: 'warning',
    ),
    AdminReport(
      id: '#REP-9920',
      title: 'Dokumentasi Donasi Tidak Lengkap',
      description: 'Kwitansi hilang untuk batch distribusi 45A.',
      statusLabel: 'Menunggu Tinjauan',
      statusColor: 'yellow',
      timeAgo: '2 jam yang lalu',
      iconType: 'doc',
    ),
    AdminReport(
      id: '#REP-9919',
      title: 'Permintaan Akun Pengguna Duplikat',
      description:
          'Potensi pendaftaran duplikat yang cocok dengan info kontak yang ada.',
      statusLabel: 'Selesai',
      statusColor: 'green',
      timeAgo: '1 hari yang lalu',
      iconType: 'user',
    ),
  ];
}
