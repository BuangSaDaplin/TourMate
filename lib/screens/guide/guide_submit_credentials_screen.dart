import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tourmate_app/models/guide_verification_model.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/database_service.dart';
import '../../utils/app_theme.dart';

class GuideSubmitCredentialsScreen extends StatefulWidget {
  const GuideSubmitCredentialsScreen({super.key});

  @override
  State<GuideSubmitCredentialsScreen> createState() =>
      _GuideSubmitCredentialsScreenState();
}

class _GuideSubmitCredentialsScreenState
    extends State<GuideSubmitCredentialsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();

  List<PlatformFile> _idDocuments = [];
  List<PlatformFile> _lguDocuments = [];
  bool _isLoading = false;
  bool _hasExistingSubmission = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSubmission();
  }

  Future<void> _checkExistingSubmission() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final existing = await _db.getGuideVerification(user.uid);
      setState(() => _hasExistingSubmission = existing != null);
    }
  }

  Future<void> _pickDocuments(Function(List<PlatformFile>) onFilesPicked,
      List<PlatformFile> existingFiles) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      // Validate file sizes (max 5MB each)
      for (final file in result.files) {
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'File size too large. Please select files under 5MB each.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        onFilesPicked([...existingFiles, ...result.files]);
      });
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idDocuments.isEmpty || _lguDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload both ID and LGU documents')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('User not authenticated');

      // Show loading indicator for uploads
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading documents...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Upload ID documents and get URLs
      List<String> idUrls = [];
      for (final file in _idDocuments) {
        final url = await _db.uploadCredentialDocument(user.uid, 'id', file);
        idUrls.add(url);
      }

      // Upload LGU documents and get URLs
      List<String> lguUrls = [];
      for (final file in _lguDocuments) {
        final url = await _db.uploadCredentialDocument(user.uid, 'lgu', file);
        lguUrls.add(url);
      }

      final verification = GuideVerification(
        id: '${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
        guideId: user.uid,
        guideName:
            user.displayName ?? user.email?.split('@')[0] ?? 'Unknown Guide',
        guideEmail: user.email ?? '',
        bio: _bioController.text.trim(),
        idDocumentUrl: idUrls,
        lguDocumentUrl: lguUrls,
        submittedAt: DateTime.now(),
      );

      // Submit verification request
      await _db.submitGuideVerification(verification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Verification submitted successfully! You will be notified once reviewed.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting verification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Guide Credentials'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Become a Verified Tour Guide',
                style: AppTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Submit your credentials for admin review. This process helps ensure quality and trust.',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Guide Bio
              Text(
                'Guide Bio',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Tell us about your experience as a tour guide, your specialties, and what makes you unique...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a guide bio';
                  }
                  if (value.trim().length < 50) {
                    return 'Bio must be at least 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ID Document Upload
              Text(
                'Government ID',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a clear photo of your valid government-issued ID (Passport, Driver\'s License, etc.)',
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildDocumentUploadSection(
                'ID Documents',
                _idDocuments,
                (files) => setState(() => _idDocuments = files),
              ),
              const SizedBox(height: 32),

              // LGU Document Upload
              Text(
                'LGU Certificate',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Upload your Local Government Unit (LGU) accreditation or tourism certificate',
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildDocumentUploadSection(
                'LGU Certificates',
                _lguDocuments,
                (files) => setState(() => _lguDocuments = files),
              ),
              const SizedBox(height: 32),

              // Requirements Info
              Card(
                color: AppTheme.primaryColor.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Requirements',
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRequirement('Valid government-issued ID'),
                      _buildRequirement(
                          'LGU tourism accreditation or certificate'),
                      _buildRequirement(
                          'Professional guide bio (min. 50 characters)'),
                      _buildRequirement('Clear, readable document photos'),
                      _buildRequirement('Documents must be current and valid'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit for Verification',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Review typically takes 1-3 business days',
                  style: AppTheme.bodySmall
                      .copyWith(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentUploadSection(String title, List<PlatformFile> files,
      Function(List<PlatformFile>) onFilesPicked) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              files.isNotEmpty ? AppTheme.successColor : AppTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (files.isEmpty) ...[
              // Show upload options when no files
              Icon(
                Icons.upload_file,
                size: 48,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'No $title uploaded',
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'You can upload multiple documents',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _pickDocuments(onFilesPicked, files),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select Documents'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              // Show uploaded files preview
              Container(
                height: 120,
                width: double.infinity,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: file.extension == 'pdf'
                                  ? null
                                  : DecorationImage(
                                      image: kIsWeb && file.bytes != null
                                          ? MemoryImage(file.bytes!)
                                          : FileImage(File(file.path!))
                                              as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                              color: file.extension == 'pdf'
                                  ? AppTheme.dividerColor.withOpacity(0.1)
                                  : null,
                            ),
                            child: file.extension == 'pdf'
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.picture_as_pdf,
                                        size: 32,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'PDF',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                final updatedFiles =
                                    List<PlatformFile>.from(files);
                                updatedFiles.removeAt(index);
                                onFilesPicked(updatedFiles);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${files.length} document${files.length == 1 ? '' : 's'} uploaded',
                style:
                    AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _pickDocuments(onFilesPicked, files),
                icon: const Icon(Icons.add),
                label: const Text('Add More'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: AppTheme.successColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
