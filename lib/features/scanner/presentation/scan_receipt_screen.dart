import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../data/ocr_service.dart';

class ScanReceiptScreen extends ConsumerStatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  ConsumerState<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends ConsumerState<ScanReceiptScreen> {
  String? _imagePath;
  bool _isScanning = false;
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ocr = ref.read(ocrServiceProvider);
      final path = await ocr.pickImage(source);
      
      if (path != null) {
        setState(() {
          _imagePath = path;
          _isScanning = true;
        });
        await _scanImage(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _scanImage(String path) async {
    try {
      final ocr = ref.read(ocrServiceProvider);
      final data = await ocr.scanReceipt(path);
      
      if (mounted) {
        setState(() {
          if (data.amount != null) {
             // Handle potential integer values for clearer display
             if (data.amount! % 1 == 0) {
               _amountController.text = data.amount!.toInt().toString();
             } else {
               _amountController.text = data.amount!.toStringAsFixed(2);
             }
          }
          if (data.date != null) {
            _selectedDate = data.date;
          }
          // Simple heuristic: if we want to try to guess merchant, we'd need better OCR logic.
          // For now, we leave merchant/note empty or maybe put "Scanned Receipt" as default if empty?
          if (_merchantController.text.isEmpty) {
             _merchantController.text = "Scanned Receipt";
          }
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
        setState(() => _isScanning = false);
      }
    }
  }

  void _confirm() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final result = ReceiptData(
      amount: amount,
      date: _selectedDate,
      text: _merchantController.text, // Using text field for Note/Merchant
    );
    
    context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        actions: [
          if (_imagePath != null && !_isScanning)
            TextButton(
              onPressed: _confirm,
              child: Text('Confirm', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: _imagePath == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
                   const SizedBox(height: 24),
                   Text(
                     'Take a photo of your receipt',
                     style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
                   ),
                   const SizedBox(height: 32),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       FilledButton.icon(
                         onPressed: () => _pickImage(ImageSource.camera),
                         icon: const Icon(Icons.camera_alt),
                         label: const Text('Camera'),
                       ),
                       const SizedBox(width: 16),
                       OutlinedButton.icon(
                         onPressed: () => _pickImage(ImageSource.gallery),
                         icon: const Icon(Icons.image),
                         label: const Text('Gallery'),
                       ),
                     ],
                   )
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Image Preview
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(_imagePath!), fit: BoxFit.contain),
                        if (_isScanning)
                          Container(
                            color: Colors.black54,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          ),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton.small(
                            onPressed: () {
                              setState(() {
                                _imagePath = null;
                                _amountController.clear();
                                _merchantController.clear();
                                _selectedDate = null;
                              });
                            },
                            child: const Icon(Icons.refresh),
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  // Form
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Review Details', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: _merchantController,
                          decoration: const InputDecoration(
                            labelText: 'Note / Merchant',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _selectedDate != null 
                                ? DateFormat.yMMMd().format(_selectedDate!) 
                                : 'Select Date',
                              style: GoogleFonts.outfit(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
