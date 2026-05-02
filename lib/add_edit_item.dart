import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'full_screen_image.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final ImagePicker _picker = ImagePicker();

void showImageSourceDialog(
  BuildContext context,
  Future<void> Function(ImageSource) onSelect,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  "Add Image",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SourceTile(
                        icon: Icons.camera_alt_rounded,
                        label: "Camera",
                        onTap: () async {
                          Navigator.pop(context);
                          await onSelect(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SourceTile(
                        icon: Icons.photo_library_rounded,
                        label: "Gallery",
                        onTap: () async {
                          Navigator.pop(context);
                          await onSelect(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple.shade100),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepPurple, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.deepPurple.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddEdit extends StatelessWidget {
  final bool add;
  final String? itemId;

  const AddEdit({required this.add, this.itemId, super.key});

  @override
  Widget build(BuildContext context) => MyAddEdit(add: add, itemId: itemId);
}

class MyAddEdit extends StatefulWidget {
  final bool add;
  final String? itemId;

  const MyAddEdit({required this.add, this.itemId, super.key});

  @override
  State<MyAddEdit> createState() => _MyAddEditState();
}

class _MyAddEditState extends State<MyAddEdit> {
  final _nameController = TextEditingController();
  final _rentController = TextEditingController();
  final _descController = TextEditingController();

  final supabase = Supabase.instance.client;
  late final String _itemId;
  List<String> imageUrls = [];
  final List<String> _pendingUploadPaths = [];
  final List<String> _pendingDeletePaths = [];
  bool isLoading = true;
  bool _didSave = false;

  @override
  void initState() {
    super.initState();
    _itemId = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('items')
        .doc(widget.itemId)
        .id;
    if (widget.add) {
      isLoading = false;
    } else {
      loadItemData();
    }
  }

  String _storagePathFromUrl(String url) {
    final fileName = Uri.parse(url).pathSegments.last;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return '$uid/$_itemId/$fileName';
  }

  Set<String> _currentImagePaths() {
    return imageUrls.map(_storagePathFromUrl).toSet();
  }

  Future<void> _deletePendingImagesAfterSave() async {
    final currentPaths = _currentImagePaths();
    final pathsToDelete = <String>{..._pendingDeletePaths};

    for (final path in _pendingUploadPaths) {
      if (!currentPaths.contains(path)) {
        pathsToDelete.add(path);
      }
    }

    if (pathsToDelete.isEmpty) return;

    try {
      await supabase.storage.from('images').remove(pathsToDelete.toList());
    } catch (e) {
      debugPrint('Pending image cleanup error: $e');
    }
  }

  Future<void> _cleanupUnsavedUploads() async {
    if (_pendingUploadPaths.isEmpty) return;

    try {
      await supabase.storage.from('images').remove(
        List<String>.from(_pendingUploadPaths),
      );
    } catch (e) {
      debugPrint('Unsaved upload cleanup error: $e');
    }
  }

  Future<void> loadImages(String itemId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final files = await supabase.storage
          .from('images')
          .list(path: '$uid/$itemId');

      final List<String> urls = [];

      for (final file in files) {
        final url = supabase.storage
            .from('images')
            .getPublicUrl('$uid/$itemId/${file.name}');

        urls.add(url);
      }

      setState(() {
        imageUrls = urls;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Load error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> loadItemData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('items')
          .doc(widget.itemId)
          .get();

      final data = doc.data();

      if (data != null) {
        _nameController.text = data["name"] ?? "";
        _rentController.text = data["rent"] ?? "";
        _descController.text = data["desc"] ?? "";

        if (!mounted) return;
        setState(() {
          imageUrls = List<String>.from(data["imageUrls"] ?? []);
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Load item error: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> pickAndUploadImage(ImageSource source) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (image == null) return;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$uid/$_itemId/$fileName';

      await supabase.storage
          .from('images')
          .upload(
            path,
            File(image.path),
            fileOptions: const FileOptions(upsert: true),
          );

      final url = supabase.storage.from('images').getPublicUrl(path);

      if (!mounted) return;
      setState(() {
        imageUrls.add(url);
        _pendingUploadPaths.add(path);
      });
    } catch (e) {
      debugPrint('Upload error: $e');
    }
  }

  Future<void> _removeImage(int index) async {
    final url = imageUrls[index];
    final path = _storagePathFromUrl(url);

    setState(() {
      imageUrls.removeAt(index);
    });

    if (_pendingUploadPaths.contains(path)) {
      try {
        await supabase.storage.from('images').remove([path]);
        _pendingUploadPaths.remove(path);
      } catch (e) {
        debugPrint('Unsaved image delete error: $e');
      }
      return;
    }

    if (!_pendingDeletePaths.contains(path)) {
      _pendingDeletePaths.add(path);
    }
  }

  @override
  void dispose() {
    if (!_didSave) {
      unawaited(_cleanupUnsavedUploads());
    }
    _nameController.dispose();
    _rentController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: widget.add ? Text("Add Item") : Text("Edit Item"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(label: "Item Details"),
              const SizedBox(height: 12),
              _buildDetailsCard(),
              const SizedBox(height: 24),
              _SectionLabel(label: "Images"),
              const SizedBox(height: 12),
              _buildImagesSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 5,
      child: Column(
        children: [
          _StyledTextField(
            controller: _nameController,
            label: "Item Name",
            icon: Icons.inventory_2_outlined,
            keyboardType: TextInputType.text,
            isFirst: true,
          ),
          _Divider(),
          _StyledTextField(
            controller: _rentController,
            label: "Rent Amount",
            icon: Icons.currency_rupee_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _Divider(),
          _StyledTextField(
            controller: _descController,
            label: "Description",
            icon: Icons.notes_rounded,
            keyboardType: TextInputType.multiline,
            maxLines: 4,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  color: Colors.deepPurple.shade400,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  imageUrls.isEmpty
                      ? "No images added"
                      : "${imageUrls.length} image${imageUrls.length > 1 ? 's' : ''} added",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () =>
                      showImageSourceDialog(context, pickAndUploadImage),
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                  label: const Text("Add"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.deepPurple.shade50,
                  ),
                ),
              ],
            ),
          ),

          // Image grid
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else if (imageUrls.isNotEmpty) ...{
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return _ImageThumbnail(
                    imageUrl: imageUrls[index],
                    onTap: () => _openViewer(index),
                    onDelete: () => _removeImage(index),
                  );
                },
              ),
            ),
          },
        ],
      ),
    );
  }

  void _openViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FullScreenImageViewer(images: imageUrls, initialIndex: index),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        if (_nameController.text.trim().isEmpty ||
            _rentController.text.trim().isEmpty ||
            _descController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please fill all the details")),
          );
          return;
        }

        final rent = double.tryParse(_rentController.text.trim());

        if (rent == null || rent <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Enter a valid rent amount")),
          );
          return;
        }

        if (imageUrls.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Add at least one image")),
          );
          return;
        }

        try {
          final uid = FirebaseAuth.instance.currentUser!.uid;

          if (widget.add) {
            final itemRef = FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('items')
                .doc(_itemId);

            await itemRef.set({
              "itemId": _itemId,
              "name": _nameController.text.trim(),
              "rent": _rentController.text.trim(),
              "desc": _descController.text.trim(),
              "imageUrls": imageUrls,
              "createdAt": FieldValue.serverTimestamp(),
            });

            _didSave = true;
            await _deletePendingImagesAfterSave();
            _pendingUploadPaths.clear();
            _pendingDeletePaths.clear();

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Item saved")));
          } else {
            final itemRef = FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('items')
                .doc(_itemId);

            await itemRef.update({
              "itemId": _itemId,
              "name": _nameController.text.trim(),
              "rent": _rentController.text.trim(),
              "desc": _descController.text.trim(),
              "imageUrls": imageUrls,
              "createdAt": FieldValue.serverTimestamp(),
            });

            _didSave = true;
            await _deletePendingImagesAfterSave();
            _pendingUploadPaths.clear();
            _pendingDeletePaths.clear();

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Item updated")));
          }

          Navigator.pop(context);
        } catch (e) {
          debugPrint("Save error: $e");
        }
      },
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.deepPurple),
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        elevation: WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        minimumSize: WidgetStatePropertyAll(Size(double.infinity, 50)),
      ),
      icon: const Icon(Icons.check),
      label: const Text(
        "Save Item",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ImageThumbnail({
    required this.imageUrl,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(imageUrl, fit: BoxFit.cover),
            // Gradient overlay
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.transparent],
                  ),
                ),
              ),
            ),
            // Delete button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final bool isFirst;
  final bool isLast;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.keyboardType,
    this.maxLines = 1,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF1A1A2E),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, size: 18, color: Colors.deepPurple.shade300),
        ),
        prefixIconConstraints: const BoxConstraints(),
        hintText: label,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 45, endIndent: 15, thickness: 0.8);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey[500],
        letterSpacing: 1.2,
      ),
    );
  }
}


