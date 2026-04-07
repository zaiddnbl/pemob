import 'package:flutter/material.dart';

class DaftarPage extends StatelessWidget {
  const DaftarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7EF),
      appBar: AppBar(
        title: const Text("Daftar Akun"),
        backgroundColor: const Color(0xFF6FCF97),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildInput("Nama"),
            buildInput("Email"),
            buildInput("Alamat"),
            buildInput("Nama Kios"),
            buildInput("No Telephone"),
            buildInput("Username"),
            buildInput("Password", isPassword: true),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FCF97),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pop(context); // balik ke login
              },
              child: const Text("Daftar"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInput(String label, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: label,
          filled: true,
          fillColor: const Color(0xFFE6F4EA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}