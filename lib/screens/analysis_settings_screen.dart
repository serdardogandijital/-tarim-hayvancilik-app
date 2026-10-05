import 'package:flutter/material.dart';

import '../services/analysis_provider.dart';
import '../services/api_key_store.dart';

class AnalysisSettingsScreen extends StatefulWidget {
  const AnalysisSettingsScreen({super.key});

  @override
  State<AnalysisSettingsScreen> createState() => _AnalysisSettingsScreenState();
}

class _AnalysisSettingsScreenState extends State<AnalysisSettingsScreen> {
  final _geminiController = TextEditingController();
  final _openAiController = TextEditingController();
  AnalysisProvider _selected = AnalysisProvider.openAi;
  bool _hasGemini = false;
  bool _hasOpenAi = false;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final selected = await AnalysisProviderStore.selected();
      final gemini = await AnalysisProviderStore.readGeminiKey();
      final openAi = await ApiKeyStore.read();
      if (!mounted) return;
      setState(() {
        _selected = selected;
        _hasGemini = gemini != null;
        _hasOpenAi = openAi != null && openAi.isNotEmpty;
        _busy = false;
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      _message('Anahtar durumu okunamadı. Tekrar deneyin.');
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveGemini() async {
    final key = _geminiController.text.trim();
    if (key.isEmpty) return _message('Gemini anahtarını girin.');
    try {
      await AnalysisProviderStore.saveGeminiKey(key);
      _geminiController.clear();
      await _refresh();
      _message('Gemini anahtarı kaydedildi ve fotoğraf analizi için seçildi.');
    } catch (_) {
      _message('Gemini anahtarı kaydedilemedi. Tekrar deneyin.');
    }
  }

  Future<void> _saveOpenAi() async {
    final key = _openAiController.text.trim();
    if (key.isEmpty) return _message('OpenAI anahtarını girin.');
    try {
      await ApiKeyStore.write(key);
      if (!await AnalysisProviderStore.select(AnalysisProvider.openAi)) {
        throw StateError('Provider selection failed');
      }
      _openAiController.clear();
      await _refresh();
      _message('OpenAI anahtarı kaydedildi ve fotoğraf analizi için seçildi.');
    } catch (_) {
      _message('OpenAI anahtarı kaydedilemedi. Tekrar deneyin.');
    }
  }

  Future<void> _select(AnalysisProvider provider) async {
    try {
      if (!await AnalysisProviderStore.select(provider)) {
        _message('Önce bu sağlayıcının API anahtarını girin.');
        return;
      }
      await _refresh();
    } catch (_) {
      _message('Sağlayıcı seçilemedi. Tekrar deneyin.');
    }
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _openAiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yapay zekâ ayarları')),
    body: _busy
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Fotoğraf analizi sağlayıcısı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kendi API anahtarınız bu cihazın güvenli alanında saklanır. Anahtar ve fotoğraflar seçtiğiniz sağlayıcıya gönderilir. Veteriner sohbeti OpenAI kullanır.',
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Gemini'),
                subtitle: Text(
                  _hasGemini ? 'Anahtar kayıtlı' : 'Anahtar gerekli',
                ),
                trailing: _selected == AnalysisProvider.gemini
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () => _select(AnalysisProvider.gemini),
              ),
              TextField(
                controller: _geminiController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Gemini API anahtarı',
                  hintText: 'Yeni anahtar girin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saveGemini,
                child: const Text('Gemini anahtarını kaydet'),
              ),
              if (_hasGemini)
                TextButton(
                  onPressed: () async {
                    await AnalysisProviderStore.deleteGeminiKey();
                    await _refresh();
                    _message('Gemini anahtarı silindi.');
                  },
                  child: const Text('Gemini anahtarını sil'),
                ),
              const Divider(height: 32),
              ListTile(
                title: const Text('OpenAI'),
                subtitle: Text(
                  _hasOpenAi ? 'Anahtar kayıtlı' : 'Anahtar gerekli',
                ),
                trailing: _selected == AnalysisProvider.openAi
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () => _select(AnalysisProvider.openAi),
              ),
              TextField(
                controller: _openAiController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'OpenAI API anahtarı',
                  hintText: 'Yeni anahtar girin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: _saveOpenAi,
                child: const Text('OpenAI anahtarını kaydet'),
              ),
              const SizedBox(height: 24),
              const Text(
                'API anahtarları ve kullanım ücretleri ilgili sağlayıcının hesabına aittir. Anahtarınızı sohbetlerde paylaşmayın.',
              ),
            ],
          ),
  );
}
