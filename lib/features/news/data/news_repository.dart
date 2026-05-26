import 'package:flutter/material.dart';

import 'news_model.dart';

class NewsRepository {
  const NewsRepository();

  List<NewsItem> getAll() {
    // Sumber open untuk referensi (metadata + link). Konten tidak di-scrape.
    return const [
      // Lingkungan
      NewsItem(
        category: 'Lingkungan',
        title: 'Perubahan Iklim: dampak dan upaya mitigasi',
        subtitle:
            'Ringkasan tentang perubahan iklim, penyebab, dan solusi global.',
        content:
            'Perubahan iklim adalah perubahan jangka panjang pada pola cuaca dan suhu bumi. Dampaknya dapat terlihat pada cuaca ekstrem, kenaikan permukaan air laut, gangguan ketersediaan air, serta tekanan terhadap kesehatan dan ketahanan pangan. Mitigasi berfokus pada pengurangan emisi gas rumah kaca (misalnya melalui efisiensi energi, energi terbarukan, dan pengurangan deforestasi) sekaligus memperkuat adaptasi terhadap dampak yang sudah terjadi.',
        url: 'https://id.wikipedia.org/wiki/Perubahan_iklim',
        icon: Icons.eco_rounded,
      ),
      NewsItem(
        category: 'Lingkungan',
        title: 'Polusi udara: sumber dan dampaknya',
        subtitle: 'Kenali penyebab polusi udara serta efeknya bagi kesehatan.',
        content:
            'Polusi udara terjadi ketika zat berbahaya (misalnya partikel halus, gas buang kendaraan, dan emisi industri) masuk ke atmosfer. Dampaknya dapat memengaruhi sistem pernapasan, memicu penyakit jantung, serta menurunkan kualitas hidup terutama pada kelompok rentan seperti anak-anak dan lansia. Upaya penanganan umumnya mencakup pengendalian emisi di sumbernya, peningkatan kualitas transportasi, pengelolaan industri, dan edukasi perilaku lingkungan.',
        url: 'https://id.wikipedia.org/wiki/Polusi',
        icon: Icons.air_rounded,
      ),
      NewsItem(
        category: 'Lingkungan',
        title: 'Energi Terbarukan dan transisi energi',
        subtitle:
            'Mengapa energi terbarukan penting untuk masa depan yang berkelanjutan.',
        content:
            'Energi terbarukan seperti surya, angin, air, dan panas bumi membantu mengurangi ketergantungan pada bahan bakar fosil yang menghasilkan emisi tinggi. Transisi energi berarti mengalihkan sistem pembangkitan dan konsumsi energi menuju teknologi yang lebih bersih serta memperkuat efisiensi. Selain menekan emisi, energi terbarukan juga berpotensi membuka lapangan kerja dan mendukung ketahanan energi di berbagai wilayah.',
        url: 'https://id.wikipedia.org/wiki/Energi_terbarukan',
        icon: Icons.bolt_rounded,
      ),

      // Sosial
      NewsItem(
        category: 'Sosial',
        title: 'Tanggung jawab sosial (CSR) dan dampaknya',
        subtitle:
            'Bagaimana praktik sosial dapat membantu komunitas secara berkelanjutan.',
        content:
            'Corporate Social Responsibility (CSR) adalah komitmen organisasi untuk memberikan dampak positif kepada masyarakat dan lingkungan, tidak hanya berfokus pada keuntungan. CSR yang efektif biasanya terhubung dengan kebutuhan nyata komunitas, melibatkan pemangku kepentingan, dan diukur hasilnya secara berkala. Dampaknya bisa berupa peningkatan akses layanan, pemberdayaan ekonomi, serta dukungan untuk program sosial jangka panjang.',
        url: 'https://id.wikipedia.org/wiki/Tanggung_jawab_sosial',
        icon: Icons.people_outline_rounded,
      ),
      NewsItem(
        category: 'Sosial',
        title: 'Kemanusiaan: kerja sukarela dan solidaritas',
        subtitle:
            'Konsep kemanusiaan dan peran organisasi sosial serta relawan.',
        content:
            'Kemanusiaan menekankan kepedulian terhadap martabat manusia dan kebutuhan dasar. Kerja sukarela dan solidaritas membantu mempercepat respons terhadap situasi krisis, menyalurkan dukungan secara lebih terkoordinasi, serta membangun kepedulian lintas kelompok. Program kemanusiaan sering mencakup bantuan darurat, dukungan pemulihan, dan pendampingan agar masyarakat dapat bangkit lebih mandiri.',
        url: 'https://id.wikipedia.org/wiki/Kemanusiaan',
        icon: Icons.volunteer_activism_rounded,
      ),
      NewsItem(
        category: 'Sosial',
        title: 'Pengentasan kemiskinan: strategi dan tantangan',
        subtitle: 'Gambaran program dan kebijakan untuk mengurangi kemiskinan.',
        content:
            'Pengentasan kemiskinan memerlukan kombinasi kebijakan dan program yang mencakup akses pendidikan, kesehatan, pekerjaan layak, perlindungan sosial, serta perbaikan ekonomi lokal. Tantangan yang sering muncul meliputi ketimpangan, hambatan akses layanan, serta dampak krisis ekonomi maupun bencana. Pendekatan yang berkelanjutan biasanya berfokus pada pemberdayaan dan memastikan bantuan tepat sasaran.',
        url: 'https://id.wikipedia.org/wiki/Kemiskinan',
        icon: Icons.monetization_on_outlined,
      ),

      // Donasi
      NewsItem(
        category: 'Donasi',
        title: 'Donasi: definisi dan contoh kegiatan filantropi',
        subtitle:
            'Memahami donasi sebagai bentuk dukungan untuk yang membutuhkan.',
        content:
            'Donasi adalah bentuk dukungan yang diberikan oleh individu atau kelompok kepada pihak yang membutuhkan. Donasi dapat berupa uang, barang, atau layanan, dan sering ditujukan untuk membantu kebutuhan mendesak seperti pangan, pendidikan, kesehatan, serta pemulihan pasca bencana. Agar berdampak, donasi idealnya disalurkan melalui pengelolaan yang transparan dan terkoordinasi dengan kebutuhan penerima.',
        url: 'https://id.wikipedia.org/wiki/Donasi',
        icon: Icons.favorite_rounded,
      ),
      NewsItem(
        category: 'Donasi',
        title: 'Filantropi: sejarah dan praktik pemberdayaan',
        subtitle:
            'Peran filantropi dalam mendukung program sosial dan kemanusiaan.',
        content:
            'Filantropi adalah upaya memberi kontribusi untuk kesejahteraan masyarakat melalui bantuan atau program yang bertujuan mendorong perubahan sosial. Praktik filantropi bisa mencakup dukungan pendidikan, layanan kesehatan, bantuan darurat, hingga program pemberdayaan ekonomi. Dampak filantropi yang baik biasanya ditopang oleh perencanaan, pelaksanaan yang bertanggung jawab, serta evaluasi berkelanjutan.',
        url: 'https://id.wikipedia.org/wiki/Filantropi',
        icon: Icons.handshake_rounded,
      ),
      NewsItem(
        category: 'Donasi',
        title: 'Tata kelola bantuan dan distribusi yang efektif',
        subtitle:
            'Kenapa distribusi dan koordinasi penting agar bantuan tepat sasaran.',
        content:
            'Distribusi bantuan yang efektif membutuhkan koordinasi agar bantuan sampai pada pihak yang tepat dan pada waktu yang dibutuhkan. Tata kelola biasanya mencakup perencanaan kebutuhan, pengumpulan, verifikasi penerima, logistik, serta pelaporan. Dengan sistem yang baik, kualitas bantuan meningkat dan potensi salah sasaran berkurang. Hal ini membantu memastikan bantuan benar-benar menghasilkan dampak positif bagi penerima.',
        url: 'https://id.wikipedia.org/wiki/Distribusi',
        icon: Icons.local_shipping_outlined,
      ),
    ];
  }

  static const categories = <String>['Lingkungan', 'Sosial', 'Donasi'];
}
