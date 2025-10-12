import 'package:flutter/material.dart';

Widget listView(List<Map<String, dynamic>> categories, Function(String) onTap) {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: categories.length,
    itemBuilder: (context, index) {
      final category = categories[index];
      return GestureDetector(
        onTap: () => onTap(category["title"] as String),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF615EFC).withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                category["icon"] as IconData,
                size: 30,
                color: const Color(0xFF615EFC),
              ),
              const SizedBox(width: 12),
              Text(
                category["title"] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
