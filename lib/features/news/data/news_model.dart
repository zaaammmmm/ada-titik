import 'package:flutter/material.dart';

class NewsItem {
  final String title;
  final String subtitle;
  final String content; // teks untuk ditampilkan di dalam aplikasi
  final String url;
  final String category; // Environment | Social | Donation
  final IconData icon;

  const NewsItem({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.url,
    required this.category,
    required this.icon,
  });
}
