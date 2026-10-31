import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/image_upload_service.dart';
import '../../data/models/dish_model.dart';
import '../viewmodels/dish_viewmodel.dart';

class DishFormScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final DishModel? dish; // null = create

  const DishFormScreen({super.key, required this.restaurantId, this.dish});

  @override
  ConsumerState<DishFormScreen> createState() => _DishFormScreenState();
}

class _DishFormScreenState extends ConsumerState<DishFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _category;
  late final TextEditingController _subcategory;
  late final TextEditingController _imageUrl;
  DateTime? _availabilityStart;
  DateTime? _availabilityEnd;
  bool _isActive = true;
  bool _showInFeed = true;

  Uint8List? _imageBytes;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final d = widget.dish;
    _name = TextEditingController(text: d?.name ?? '');
    _description = TextEditingController(text: d?.description ?? '');
    _price = TextEditingController(text: d?.price.toStringAsFixed(2) ?? '');
    _category = TextEditingController(text: d?.category ?? '');
    _subcategory = TextEditingController(text: d?.subcategory ?? '');
    _imageUrl = TextEditingController(text: d?.imageUrl ?? '');
    _availabilityStart = d?.availabilityStart;
    _availabilityEnd = d?.availabilityEnd;
    _isActive = d?.isActive ?? true;
    _showInFeed = d?.showInFeed ?? true;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _description,
      _price,
      _category,
      _subcategory,
      _imageUrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDishImage() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _uploadingImage = true;
    });
    try {
      final url = await ref.read(imageUploadServiceProvider).uploadImage(
            xFile,
            entityType: 'Dish',
            entityId: widget.dish?.id,
          );
      setState(() => _imageUrl.text = url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Imagem enviada!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao enviar: $e'), backgroundColor: Colors.red));
        setState(() {
          _imageBytes = null;
        });
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _availabilityStart = picked;
        else
          _availabilityEnd = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'name': _name.text,
      'description': _description.text.isEmpty ? null : _description.text,
      'price': double.tryParse(_price.text.replaceAll(',', '.')) ?? 0.0,
      'category': _category.text,
      'subcategory':
          _subcategory.text.trim().isEmpty ? null : _subcategory.text.trim(),
      'imageUrl': _imageUrl.text.isEmpty ? null : _imageUrl.text,
      'showInFeed': _showInFeed && !_isMenuOnlyCategory(_category.text),
      'availabilityStart': _availabilityStart?.toIso8601String(),
      'availabilityEnd': _availabilityEnd?.toIso8601String(),
      'isActive': _isActive,
    };

    bool success;
    if (widget.dish == null) {
      success = await ref
          .read(dishViewModelProvider(widget.restaurantId).notifier)
          .createDish(data);
    } else {
      success = await ref
          .read(dishViewModelProvider(widget.restaurantId).notifier)
          .updateDish(widget.dish!.id, data);
    }

    if (success && mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.dish != null;
    final state = ref.watch(dishViewModelProvider(widget.restaurantId));

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Prato' : 'Novo Prato'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(state.error!,
                    style: const TextStyle(color: Colors.red)),
              ),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome do Prato *'),
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              decoration: const InputDecoration(
                  labelText: 'Preço (R\$) *', prefixText: 'R\$ '),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Obrigatório';
                if (double.tryParse(v.replaceAll(',', '.')) == null)
                  return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category.text.isEmpty ? null : _category.text,
              decoration: const InputDecoration(labelText: 'Seção do menu *'),
              items: [
                ..._dishSections,
                if (_category.text.isNotEmpty &&
                    !_dishSections.contains(_category.text))
                  _category.text,
              ]
                  .map((section) => DropdownMenuItem(
                        value: section,
                        child: Text(section),
                      ))
                  .toList(),
              onChanged: (section) {
                if (section != null) {
                  setState(() {
                    _category.text = section;
                    if (_isMenuOnlyCategory(section)) _showInFeed = false;
                  });
                }
              },
              validator: (value) =>
                  value == null || value.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subcategory,
              decoration: const InputDecoration(
                labelText: 'Subcategoria',
                hintText: 'Ex.: Massas artesanais, Drinks da casa',
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Publicar também no feed'),
              subtitle: Text(_isMenuOnlyCategory(_category.text)
                  ? 'Bebidas e carta de vinhos ficam somente no menu.'
                  : 'Desative para manter este item apenas no menu.'),
              value: _showInFeed && !_isMenuOnlyCategory(_category.text),
              onChanged: _isMenuOnlyCategory(_category.text)
                  ? null
                  : (value) => setState(() => _showInFeed = value),
            ),
            const SizedBox(height: 8),
            // Image picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Foto do Prato',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _uploadingImage ? null : _pickDishImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _uploadingImage
                        ? const Center(child: CircularProgressIndicator())
                        : (_imageBytes != null || _imageUrl.text.isNotEmpty)
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: _imageBytes != null
                                        ? Image.memory(_imageBytes!,
                                            fit: BoxFit.cover)
                                        : Image.network(_imageUrl.text,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.broken_image,
                                                    size: 40)),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: const Text('Alterar',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
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
                                          color: Colors.grey.shade600,
                                          fontSize: 12)),
                                ],
                              ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text('Disponibilidade',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(true),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_availabilityStart == null
                      ? 'Início (opcional)'
                      : 'Início: ${_availabilityStart!.day}/${_availabilityStart!.month}/${_availabilityStart!.year}'),
                ),
              ),
              const SizedBox(width: 8),
              if (_availabilityStart != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _availabilityStart = null),
                ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(false),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_availabilityEnd == null
                      ? 'Fim (opcional)'
                      : 'Fim: ${_availabilityEnd!.day}/${_availabilityEnd!.month}/${_availabilityEnd!.year}'),
                ),
              ),
              const SizedBox(width: 8),
              if (_availabilityEnd != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _availabilityEnd = null),
                ),
            ]),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Item ativo'),
              subtitle: Text(_isActive
                  ? 'Desative para removê-lo do menu e do feed.'
                  : _deletionWarning(widget.dish?.deactivatedAt)),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (state.isLoading || _uploadingImage) ? null : _submit,
              child: state.isLoading
                  ? const CircularProgressIndicator()
                  : Text(isEditing
                      ? 'Salvar Alterações'
                      : 'Adicionar ao Cardápio'),
            ),
          ],
        ),
      ),
    );
  }
}

const _dishSections = [
  'Entradas',
  'Menu Principal',
  'Petiscos',
  'Sobremesas',
  'Bebidas',
  'Carta de Vinhos',
];

bool _isMenuOnlyCategory(String category) {
  final normalized = category.trim().toLowerCase();
  return normalized.contains('bebid') ||
      normalized.contains('drink') ||
      normalized.contains('vinho');
}

String _deletionWarning(DateTime? deactivatedAt) {
  if (deactivatedAt == null) {
    return 'Reative em até sete dias para evitar a exclusão definitiva.';
  }
  final deleteAt = deactivatedAt.add(const Duration(days: 7));
  return 'Reative até ${deleteAt.day.toString().padLeft(2, '0')}/${deleteAt.month.toString().padLeft(2, '0')}/${deleteAt.year}; depois disso, o item e as imagens serão excluídos.';
}
