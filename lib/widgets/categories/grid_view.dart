import 'package:flutter/material.dart';

Widget gridView(List<Map<String, dynamic>> categories, Function(String) onTap) {
  return GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
    ),
    itemCount: categories.length,
    itemBuilder: (context, index) {
      final category = categories[index];
      return GestureDetector(
        onTap: () => onTap(category["title"] as String),
        child: Container(
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category["icon"] as IconData,
                size: 40,
                color: const Color(0xFF615EFC),
              ),
              const SizedBox(height: 10),
              Text(
                category["title"] as String,
                style: const TextStyle(
                  fontSize: 14,
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
