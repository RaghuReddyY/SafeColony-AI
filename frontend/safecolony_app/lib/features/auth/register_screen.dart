import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/primary_button.dart';

import 'models/property_lookup.dart';
import 'models/section_lookup.dart';

import 'providers/auth_provider.dart';
import 'providers/public_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends ConsumerState<RegisterScreen> {
  
  final _formKey = GlobalKey<FormState>();

  final _organizationCodeController =
      TextEditingController();

  final _unitNumberController =
      TextEditingController();

  final _nameController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;

  bool _obscureConfirmPassword = true;

  PropertyLookup? _selectedProperty;

  SectionLookup? _selectedSection;

  String _residentType = "OWNER";

Future<void> _verifyOrganization() async {
  if (_organizationCodeController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text("Enter Organization Code"),
      ),
    );
    return;
  }

  final success = await ref
      .read(publicProvider.notifier)
      .lookupOrganization(
        _organizationCodeController.text.trim(),
      );

  if (!mounted) return;

  if (!success) {
    final error =
        ref.read(publicProvider).error ??
            "Organization not found";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(error),
      ),
    );

    return;
  }

  final organization =
      ref.read(publicProvider).organization;

  if (organization != null &&
      organization.properties.isNotEmpty) {
    _selectedProperty =
        organization.properties.first;

    await ref
        .read(publicProvider.notifier)
        .loadSections(
          _selectedProperty!.id,
        );

    _selectedSection = null;

    setState(() {});
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      backgroundColor: Colors.green,
      content: Text(
        "Organization Verified",
      ),
    ),
  );
}

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text !=
        _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Passwords do not match"),
        ),
      );
      return;
    }
    if (ref.read(publicProvider).organization == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      backgroundColor: Colors.red,
      content: Text("Please verify your organization."),
    ),
  );
  return;
}

if (_selectedProperty == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      backgroundColor: Colors.red,
      content: Text("Please select a property."),
    ),
  );
  return;
}

if (_selectedSection == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      backgroundColor: Colors.red,
      content: Text("Please select a section."),
    ),
  );
  return;
}

if (_unitNumberController.text.trim().isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      backgroundColor: Colors.red,
      content: Text("Please enter your unit number."),
    ),
  );
  return;
}

    final success =
    await ref.read(authProvider.notifier).register(
      organizationCode:
          _organizationCodeController.text.trim(),

      sectionId: _selectedSection?.id ?? 0,

      unitNumber:
          _unitNumberController.text.trim(),

      residentType: _residentType,

      fullName: _nameController.text.trim(),

      email: _emailController.text.trim(),

      phone: _phoneController.text.trim(),

      password: _passwordController.text,
    );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
              "Registration successful. Please login."),
        ),
      );

      Navigator.pop(context);
    } else {
      final error =
          ref.read(authProvider).error ??
              "Registration failed";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(error),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final publicState = ref.watch(publicProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 500,
            child: GlassCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_add,
                      size: 70,
                      color: Colors.white,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Resident Registration",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

const SizedBox(height: 30),

Row(
  children: [
    Expanded(
      child: AppTextField(
        controller: _organizationCodeController,
        hint: "Organization Code",
        icon: Icons.business,
      ),
    ),
    const SizedBox(width: 10),
    ElevatedButton(
      onPressed: publicState.isLoading
          ? null
          : _verifyOrganization,
      child: const Text("VERIFY"),
    ),
  ],
),

const SizedBox(height: 16),

if (publicState.organization != null)
  Card(
    color: Colors.green.shade50,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            publicState.organization!.organizationName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          
        ],
      ),
    ),
  ),

const SizedBox(height: 16),

if (publicState.organization != null &&
    publicState.organization!.properties.isNotEmpty)
  DropdownButtonFormField<PropertyLookup>(
    initialValue: _selectedProperty,
    decoration: const InputDecoration(
      labelText: "Property",
      border: OutlineInputBorder(),
    ),
    items: publicState.organization!.properties
        .map(
          (property) => DropdownMenuItem<PropertyLookup>(
            value: property,
            child: Text(property.name),
          ),
        )
        .toList(),
    onChanged: (property) async {
      if (property == null) return;

      setState(() {
        _selectedProperty = property;
        _selectedSection = null;
      });

      await ref
          .read(publicProvider.notifier)
          .loadSections(property.id);
    },
  ),

const SizedBox(height: 16),

if (publicState.sections.isNotEmpty)
  DropdownButtonFormField<SectionLookup>(
    initialValue: _selectedSection,
    decoration: const InputDecoration(
      labelText: "Section",
      border: OutlineInputBorder(),
    ),
    items: publicState.sections
        .map(
          (section) => DropdownMenuItem<SectionLookup>(
            value: section,
            child: Text(section.name),
          ),
        )
        .toList(),
    onChanged: (section) {
      setState(() {
        _selectedSection = section;
      });
    },
  ),

const SizedBox(height: 16),

AppTextField(
  controller: _unitNumberController,
  hint: "Unit Number",
  icon: Icons.home,
),

const SizedBox(height: 16),

DropdownButtonFormField<String>(
  initialValue: _residentType,
  decoration: const InputDecoration(
       border: OutlineInputBorder(),
  ),
  items: const [
    DropdownMenuItem(
      value: "OWNER",
      child: Text("Owner"),
    ),
    DropdownMenuItem(
      value: "TENANT",
      child: Text("Tenant"),
    ),
    DropdownMenuItem(
      value: "FAMILY_MEMBER",
      child: Text("Family Member"),
    ),
  ],
  onChanged: (value) {
    if (value == null) return;

    setState(() {
      _residentType = value;
    });
  },
),

const SizedBox(height: 16),

AppTextField(
  controller: _nameController,
  hint: "Full Name",
  icon: Icons.person,
),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _emailController,
                      hint: "Email",
                      icon: Icons.email,
                    ),

                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _phoneController,
                      hint: "Phone",
                      icon: Icons.phone,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return "Password is required";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Password",
                        prefixIcon:
                            const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                          _confirmPasswordController,
                      obscureText:
                          _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return "Confirm your password";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Confirm Password",
                        prefixIcon:
                            const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: authState.isLoading
                          ? const Center(
                              child:
                                  CircularProgressIndicator(),
                            )
                          : PrimaryButton(
                              title: "REGISTER",
                              onPressed: _register,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

@override
void dispose() {
  _organizationCodeController.dispose();
  _unitNumberController.dispose();

  _nameController.dispose();
  _emailController.dispose();
  _phoneController.dispose();

  _passwordController.dispose();
  _confirmPasswordController.dispose();

  super.dispose();
}
}