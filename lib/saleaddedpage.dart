import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SaleAddedPage extends StatefulWidget {
  const SaleAddedPage({super.key});

  @override
  State<SaleAddedPage> createState() => _SaleAddedPageState();
}

class _SaleAddedPageState extends State<SaleAddedPage> {
  final TextEditingController _editController = TextEditingController();
  String? _editingDocId;

  void _startEditing(String docId, String currentUrl) {
    setState(() {
      _editingDocId = docId;
      _editController.text = currentUrl;
    });
  }

  Future<void> _saveEdit() async {
    if (_editingDocId == null || _editController.text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('Sale')
          .doc(_editingDocId)
          .update({'imageUrl': _editController.text.trim()});

      setState(() {
        _editingDocId = null;
        _editController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Black background
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Sale Images',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Sale')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No sale images added.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final docId = doc.id;
                      final imageUrl = doc['imageUrl'] as String? ?? '';

                      final isEditing = _editingDocId == docId;

                      return Card(
                        color: Colors.grey[850], // Dark card background
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              imageUrl.isNotEmpty
                                  ? Image.network(
                                imageUrl,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                                  : const Text(
                                'No image available',
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 10),
                              if (isEditing)
                                Column(
                                  children: [
                                    TextFormField(
                                      controller: _editController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Edit Image URL',
                                        labelStyle: const TextStyle(color: Colors.white),
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.blue),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: _saveEdit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                          ),
                                          child: const Text('Save'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _editingDocId = null;
                                              _editController.clear();
                                            });
                                          },
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                )
                              else
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _startEditing(docId, imageUrl),
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                    label: const Text('Edit', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
