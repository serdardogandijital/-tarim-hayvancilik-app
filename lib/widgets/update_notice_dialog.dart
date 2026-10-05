import 'package:flutter/material.dart';

class UpdateNoticeDialog extends StatelessWidget {
  const UpdateNoticeDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Çiftçi+ yenilikleri'),
    content: const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sürüm 1.1.1'),
        SizedBox(height: 12),
        Text(
          '• Tarla ve hayvan kayıtları bildirimler hazırlanırken de hemen gösterilir.',
        ),
        SizedBox(height: 8),
        Text(
          '• Bir kayıt okunamazsa diğer kayıtlar gizlenmez; mevcut veri korunur.',
        ),
        SizedBox(height: 8),
        Text('• Fotoğraf analizi ve bakım asistanı artık anahtar girmeden çalışır.'),
        SizedBox(height: 8),
        Text('• Güncelleme notlarına ana sayfadan yeniden ulaşabilirsiniz.'),
        SizedBox(height: 12),
        Text('Kayıtlarınız görünmüyorsa uygulamayı silmeyin.'),
      ],
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Tamam'),
      ),
    ],
  );
}
