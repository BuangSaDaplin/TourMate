import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tourmate_app/models/guide_verification_model.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/database_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  XFile? _idImage;
  XFile? _lguImage;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source, Function(XFile?) onPicked) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    setState(() {
      onPicked(image);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
                'Please upload your valid ID and LGU Certificate to get verified.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery, (image) {
                setState(() {
                  _idImage = image;
                });
              }),
              child: const Text('Upload Valid ID'),
            ),
            if (_idImage != null)
              Image.file(
                File(_idImage!.path),
                height: 100,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery, (image) {
                setState(() {
                  _lguImage = image;
                });
              }),
              child: const Text('Upload LGU Certificate'),
            ),
            if (_lguImage != null)
              Image.file(
                File(_lguImage!.path),
                height: 100,
              ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      if (_idImage != null && _lguImage != null) {
                        setState(() {
                          _isLoading = true;
                        });
                        final user = _authService.getCurrentUser();
                        if (user != null) {
                          final idUrl = await _authService.uploadProfilePhoto(
                              user.uid, _idImage!);
                          final lguUrl = await _authService.uploadProfilePhoto(
                              user.uid, _lguImage!);

                          final verification = GuideVerification(
                            id: '${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
                            guideId: user.uid,
                            guideName: user.displayName ??
                                user.email?.split('@')[0] ??
                                'Unknown Guide',
                            guideEmail: user.email ?? '',
                            idDocumentUrl: [idUrl!],
                            lguDocumentUrl: [lguUrl!],
                            submittedAt: DateTime.now(),
                          );

                          await _db.submitGuideVerification(verification);
                        }
                        setState(() {
                          _isLoading = false;
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Submit for Verification'),
                  ),
          ],
        ),
      ),
    );
  }
}
