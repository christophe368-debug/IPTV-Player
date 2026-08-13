import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/profile.dart';
import '../../providers/profile_provider.dart';
import '../../services/m3u_parser_service.dart';
import '../../services/xtream_service.dart';

/// Bildschirm zum Hinzufuegen eines neuen IPTV-Profils.
/// Bietet drei Wege an: Xtream Codes API, M3U-Playlist-URL oder eine
/// lokal ausgewaehlte M3U-Datei.
class AddProfileScreen extends ConsumerStatefulWidget {
  const AddProfileScreen({super.key});

  @override
  ConsumerState<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends ConsumerState<AddProfileScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil hinzufuegen'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Xtream Codes'),
            Tab(text: 'M3U-Link'),
            Tab(text: 'Lokale Datei'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _XtreamForm(),
          _M3uUrlForm(),
          _M3uFileForm(),
        ],
      ),
    );
  }
}

/// Gemeinsamer Zustand fuer "wird gerade geprueft" + Fehlermeldung,
/// von allen drei Formularen genutzt.
mixin _SubmitStateMixin<T extends StatefulWidget> on State<T> {
  bool isSubmitting = false;
  String? errorText;

  Future<void> runSubmit(Future<void> Function() action) async {
    setState(() {
      isSubmitting = true;
      errorText = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => errorText = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Xtream Codes
// ---------------------------------------------------------------------------

class _XtreamForm extends ConsumerStatefulWidget {
  const _XtreamForm();
  @override
  ConsumerState<_XtreamForm> createState() => _XtreamFormState();
}

class _XtreamFormState extends ConsumerState<_XtreamForm> with _SubmitStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _serverCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Profilname (frei waehlbar)', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte einen Namen eingeben' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _serverCtrl,
            decoration: const InputDecoration(
              labelText: 'Server-URL',
              hintText: 'http://beispiel-anbieter.tv:8080',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte Server-URL eingeben' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _userCtrl,
            decoration: const InputDecoration(labelText: 'Benutzername', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte Benutzername eingeben' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Passwort',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Bitte Passwort eingeben' : null,
          ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            Text(errorText!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: isSubmitting ? null : _submit,
            child: isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Verbindung testen & speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await runSubmit(() async {
      final service = XtreamService(
        serverUrl: _serverCtrl.text.trim(),
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await service.authenticate(); // wirft Exception bei falschen Daten

      final profile = Profile(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        type: ProfileType.xtream,
        serverUrl: _serverCtrl.text.trim(),
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await ref.read(profilesProvider.notifier).add(profile);
      if (mounted) Navigator.of(context).pop();
    });
  }
}

// ---------------------------------------------------------------------------
// M3U-URL
// ---------------------------------------------------------------------------

class _M3uUrlForm extends ConsumerStatefulWidget {
  const _M3uUrlForm();
  @override
  ConsumerState<_M3uUrlForm> createState() => _M3uUrlFormState();
}

class _M3uUrlFormState extends ConsumerState<_M3uUrlForm> with _SubmitStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Profilname (frei waehlbar)', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte einen Namen eingeben' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'Playlist-URL',
              hintText: 'http://beispiel.de/playlist.m3u',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte Playlist-URL eingeben' : null,
          ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            Text(errorText!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: isSubmitting ? null : _submit,
            child: isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Playlist laden & speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await runSubmit(() async {
      final result = await M3uParserService().parseFromUrl(_urlCtrl.text.trim());
      if (result.channels.isEmpty) {
        throw Exception('Playlist enthaelt keine abspielbaren Eintraege');
      }

      final profile = Profile(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        type: ProfileType.m3uUrl,
        m3uSource: _urlCtrl.text.trim(),
      );
      await ref.read(profilesProvider.notifier).add(profile);
      if (mounted) Navigator.of(context).pop();
    });
  }
}

// ---------------------------------------------------------------------------
// Lokale M3U-Datei
// ---------------------------------------------------------------------------

class _M3uFileForm extends ConsumerStatefulWidget {
  const _M3uFileForm();
  @override
  ConsumerState<_M3uFileForm> createState() => _M3uFileFormState();
}

class _M3uFileFormState extends ConsumerState<_M3uFileForm> with _SubmitStateMixin {
  final _nameCtrl = TextEditingController();
  String? _pickedFileName;
  List<int>? _pickedBytes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Profilname (frei waehlbar)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: isSubmitting ? null : _pickFile,
          icon: const Icon(Icons.folder_open),
          label: Text(_pickedFileName ?? 'M3U-Datei auswaehlen'),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 12),
          Text(errorText!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: (isSubmitting || _pickedBytes == null) ? null : _submit,
          child: isSubmitting
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Datei importieren & speichern'),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m3u', 'm3u8', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _pickedFileName = result.files.first.name;
      _pickedBytes = result.files.first.bytes;
      if (_nameCtrl.text.trim().isEmpty) {
        _nameCtrl.text = result.files.first.name.replaceAll(RegExp(r'\.(m3u8?|txt)$'), '');
      }
    });
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => errorText = 'Bitte einen Profilnamen eingeben');
      return;
    }
    await runSubmit(() async {
      final content = String.fromCharCodes(_pickedBytes!);
      final result = M3uParserService().parseContent(content);
      if (result.channels.isEmpty) {
        throw Exception('Datei enthaelt keine abspielbaren Eintraege');
      }

      // Datei dauerhaft im App-eigenen Speicher ablegen, damit sie auch
      // nach einem Neustart noch verfuegbar ist (der urspruengliche Pfad
      // koennte auf Android/iOS nicht dauerhaft zugaenglich sein).
      final docsDir = await getApplicationDocumentsDirectory();
      final playlistsDir = Directory('${docsDir.path}/playlists');
      if (!await playlistsDir.exists()) {
        await playlistsDir.create(recursive: true);
      }
      final id = const Uuid().v4();
      final savedFile = File('${playlistsDir.path}/$id.m3u');
      await savedFile.writeAsBytes(_pickedBytes!);

      final profile = Profile(
        id: id,
        name: _nameCtrl.text.trim(),
        type: ProfileType.m3uFile,
        m3uSource: savedFile.path,
      );
      await ref.read(profilesProvider.notifier).add(profile);
      if (mounted) Navigator.of(context).pop();
    });
  }
}
