import 'package:flutter/material.dart';

class CartController {
  static ValueNotifier<List<Map<String, dynamic>>> items =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  /// TAMBAH KE KERANJANG
  static void addItem(Map<String, dynamic> alat) {
    final list = List<Map<String, dynamic>>.from(items.value);

    // Cek apakah barang sudah ada
    final index = list.indexWhere((e) => e['id_alat'] == alat['id_alat']);

    if (index != -1) {
      // Jika sudah ada, tambahkan qty (selama stok mencukupi)
      if (list[index]['qty'] < alat['stok_total']) {
        list[index]['qty']++;
      }
    } else {
      // Jika belum ada, tambah baru
      list.add({
        ...alat,
        'qty': 1,
      });
    }
    items.value = list;
  }

  /// UPDATE QTY (Untuk tombol + dan - di halaman transaksi)
  static void updateQty(int idAlat, int delta) {
    final list = List<Map<String, dynamic>>.from(items.value);
    final index = list.indexWhere((e) => e['id_alat'] == idAlat);

    if (index != -1) {
      int newQty = list[index]['qty'] + delta;

      // Jika qty jadi 0, hapus dari keranjang
      if (newQty <= 0) {
        list.removeAt(index);
      } else if (newQty <= list[index]['stok_total']) {
        // Update hanya jika stok cukup
        list[index]['qty'] = newQty;
      }
      items.value = list;
    }
  }

  static void removeItem(int idAlat) {
    items.value = items.value.where((e) => e['id_alat'] != idAlat).toList();
  }

  static void clear() {
    items.value = [];
  }
}
