import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/image_upload_service.dart';
import '../../../admin/presentation/viewmodels/admin_restaurant_viewmodel.dart';
import '../../data/models/restaurant_model.dart';
import '../viewmodels/restaurant_viewmodel.dart';

class RestaurantFormScreen extends ConsumerStatefulWidget {
  final RestaurantModel? restaurant;
  final bool isAdmin;
  const RestaurantFormScreen(
      {super.key, this.restaurant, this.isAdmin = false});

  @override
  ConsumerState<RestaurantFormScreen> createState() =>
      _RestaurantFormScreenState();
}

class _RestaurantFormScreenState extends ConsumerState<RestaurantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _category;
  late final TextEditingController _logoUrl;
  late final TextEditingController _coverUrl;
  late final TextEditingController _instagramHandle; // stores only handle
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _openingHours;

  // Picked image state
  XFile? _logoXFile;
  XFile? _coverXFile;
  Uint8List? _logoBytes;
  Uint8List? _coverBytes;
  bool _uploadingLogo = false;
  bool _uploadingCover = false;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final r = widget.restaurant;
    _name = TextEditingController(text: r?.name ?? '');
    _description = TextEditingController(text: r?.description ?? '');
    _address = TextEditingController(text: r?.address ?? '');
    _city = TextEditingController(text: r?.city ?? 'Salvador');
    _category = TextEditingController(text: r?.category ?? '');
    _logoUrl = TextEditingController(text: r?.logoUrl ?? '');
    _coverUrl = TextEditingController(text: r?.coverUrl ?? '');
    _lat = TextEditingController(text: r?.latitude?.toString() ?? '');
    _lng = TextEditingController(text: r?.longitude?.toString() ?? '');
    _openingHours = TextEditingController(text: r?.openingHours ?? '');

    // Strip prefix from stored Instagram URL
    String handle = r?.instagramUrl ?? '';
    for (final prefix in [
      'https://www.instagram.com/',
      'https://instagram.com/',
      'http://instagram.com/',
      'instagram.com/',
    ]) {
      if (handle.startsWith(prefix)) {
        handle = handle.substring(prefix.length);
        break;
      }
    }
    _instagramHandle = TextEditingController(text: handle);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _description,
      _address,
      _city,
      _category,
      _logoUrl,
      _coverUrl,
      _instagramHandle,
      _lat,
      _lng,
      _openingHours,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage({required bool isLogo}) async {
    final xFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    setState(() {
      if (isLogo) {
        _logoXFile = xFile;
        _logoBytes = bytes;
        _uploadingLogo = true;
      } else {
        _coverXFile = xFile;
        _coverBytes = bytes;
        _uploadingCover = true;
      }
    });

    try {
      final url = await ref.read(imageUploadServiceProvider).uploadImage(
            xFile,
            entityType: 'Restaurant',
            entityId: widget.restaurant?.id,
          );
      setState(() {
        if (isLogo)
          _logoUrl.text = url;
        else
          _coverUrl.text = url;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLogo ? 'Logo enviado!' : 'Capa enviada!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          if (isLogo) {
            _logoXFile = null;
            _logoBytes = null;
          } else {
            _coverXFile = null;
            _coverBytes = null;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isLogo)
            _uploadingLogo = false;
          else
            _uploadingCover = false;
        });
      }
    }
  }

  Widget _imagePickerTile({
    required String label,
    required bool isLogo,
    required Uint8List? pickedBytes,
    required String? currentUrl,
    required bool uploading,
  }) {
    final hasImage =
        pickedBytes != null || (currentUrl != null && currentUrl.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: uploading ? null : () => _pickImage(isLogo: isLogo),
          child: Container(
            height: isLogo ? 100 : 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: uploading
                ? const Center(child: CircularProgressIndicator())
                : hasImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: pickedBytes != null
                                ? Image.memory(pickedBytes, fit: BoxFit.cover)
                                : Image.network(
                                    currentUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        size: 40),
                                  ),
                          ),
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Alterar',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 36, color: Colors.grey.shade600),
                          const SizedBox(height: 4),
                          Text('Toque para escolher',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final instagramUrl = _instagramHandle.text.trim().isEmpty
        ? null
        : 'https://instagram.com/${_instagramHandle.text.trim()}';

    final data = {
      'name': _name.text,
      'description': _description.text.isEmpty ? null : _description.text,
      'address': _address.text,
      'city': _city.text.isEmpty ? 'Salvador' : _city.text,
      'category': _category.text,
      'logoUrl': _logoUrl.text.isEmpty ? null : _logoUrl.text,
      'coverUrl': _coverUrl.text.isEmpty ? null : _coverUrl.text,
      'instagramUrl': instagramUrl,
      'latitude': double.tryParse(_lat.text) ?? 0.0,
      'longitude': double.tryParse(_lng.text) ?? 0.0,
      'openingHours': _openingHours.text.isEmpty ? null : _openingHours.text,
    };

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      if (widget.isAdmin) {
        final dataSource = ref.read(adminRestaurantDataSourceProvider);
        if (widget.restaurant == null) {
          await dataSource.createRestaurant(data);
        } else {
          await dataSource.updateRestaurant(widget.restaurant!.id, data);
        }
      } else {
        final success = widget.restaurant == null
            ? await ref
                .read(restaurantViewModelProvider.notifier)
                .createRestaurant(data)
            : await ref
                .read(restaurantViewModelProvider.notifier)
                .updateRestaurant(widget.restaurant!.id, data);
        if (!success) {
          throw Exception(ref.read(restaurantViewModelProvider).error ??
              'Não foi possível salvar o restaurante.');
        }
      }

      if (mounted) context.pop(true);
    } catch (error) {
      if (mounted) setState(() => _submitError = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.restaurant != null;
    final state = ref.watch(restaurantViewModelProvider);
    final isLoading = widget.isAdmin ? _isSubmitting : state.isLoading;
    final errorMessage = _submitError ?? (widget.isAdmin ? null : state.error);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Restaurante' : 'Cadastrar Restaurante'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(errorMessage,
                    style: const TextStyle(color: Colors.red)),
              ),
            TextFormField(
              controller: _name,
              decoration:
                  const InputDecoration(labelText: 'Nome do Restaurante *'),
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Descricao'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Endereco *'),
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Cidade *'),
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(
                  labelText: 'Categoria *', hintText: 'Ex: Japonesa, Pizza...'),
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatorio' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _lat,
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lng,
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _imagePickerTile(
              label: 'Logo do Restaurante',
              isLogo: true,
              pickedBytes: _logoBytes,
              currentUrl: _logoUrl.text.isEmpty ? null : _logoUrl.text,
              uploading: _uploadingLogo,
            ),
            const SizedBox(height: 16),
            _imagePickerTile(
              label: 'Imagem de Capa',
              isLogo: false,
              pickedBytes: _coverBytes,
              currentUrl: _coverUrl.text.isEmpty ? null : _coverUrl.text,
              uploading: _uploadingCover,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instagramHandle,
              decoration: const InputDecoration(
                labelText: 'Instagram',
                prefixText: 'instagram.com/',
                hintText: 'seurestaurante',
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _openingHours,
              decoration: const InputDecoration(
                  labelText: 'Horario de Funcionamento',
                  hintText: 'Ex: Seg-Sex 11h-22h'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (isLoading || _uploadingLogo || _uploadingCover)
                  ? null
                  : _submit,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text(isEditing
                      ? 'Salvar Alteracoes'
                      : 'Cadastrar Restaurante'),
            ),
          ],
        ),
      ),
    );
  }
}
