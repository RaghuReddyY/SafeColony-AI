import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/primary_button.dart';

class OrganizationRegistrationScreen extends ConsumerStatefulWidget {
  const OrganizationRegistrationScreen({super.key});

  @override
  ConsumerState<OrganizationRegistrationScreen> createState() =>
      _OrganizationRegistrationScreenState();
}

class _OrganizationRegistrationScreenState
    extends ConsumerState<OrganizationRegistrationScreen> {

  final _formKey = GlobalKey<FormState>();

  // Organization
  final _organizationNameController = TextEditingController();
  final _organizationEmailController = TextEditingController();
  final _organizationPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController =
      TextEditingController(text: "India");
  final _pincodeController = TextEditingController();

  // Admin
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _organizationType = "APARTMENT";

  @override
  void dispose() {
    _organizationNameController.dispose();
    _organizationEmailController.dispose();
    _organizationPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();

    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

Widget _buildOrganizationCard() {
  return GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Organization Details",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        AppTextField(
          controller: _organizationNameController,
          hint: "Organization Name",
          icon: Icons.apartment,
        ),

        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _organizationType,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.business),
                   ),
          items: const [
            DropdownMenuItem(
              value: "APARTMENT",
              child: Text("Apartment"),
            ),
            DropdownMenuItem(
              value: "VILLA",
              child: Text("Villa"),
            ),
            DropdownMenuItem(
              value: "GATED_COMMUNITY",
              child: Text("Gated Community"),
            ),
            DropdownMenuItem(
              value: "RESIDENTIAL_LAYOUT",
              child: Text("Residential Layout"),
            ),
            DropdownMenuItem(
              value: "OFFICE_CAMPUS",
              child: Text("Office Campus"),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _organizationType = value!;
            });
          },
        ),

        const SizedBox(height: 16),

        AppTextField(
          controller: _organizationEmailController,
          hint: "Organization Email",
          icon: Icons.email,
        ),

        const SizedBox(height: 16),

        AppTextField(
          controller: _organizationPhoneController,
          hint: "Phone Number",
          icon: Icons.phone,
        ),

        const SizedBox(height: 16),

        AppTextField(
          controller: _addressController,
          hint: "Address",
          icon: Icons.location_on,
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _cityController,
                hint: "City",
                icon: Icons.location_city,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: AppTextField(
                controller: _stateController,
                hint: "State",
                icon: Icons.map,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _countryController,
                hint: "Country",
                icon: Icons.public,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: AppTextField(
                controller: _pincodeController,
                hint: "Pincode",
                icon: Icons.pin_drop,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


Widget _buildAdminCard() {
  return GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Administrator Details",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        AppTextField(
          controller: _adminNameController,
          hint: "Full Name",
          icon: Icons.person,
        ),

        const SizedBox(height: 16),

        AppTextField(
          controller: _adminEmailController,
          hint: "Email",
          icon: Icons.email,
        ),

        const SizedBox(height: 16),

        AppTextField(
          controller: _adminPhoneController,
          hint: "Phone Number",
          icon: Icons.phone,
        ),

        const SizedBox(height: 16),

        AppTextField(
  controller: _passwordController,
  hint: "Password",
  icon: Icons.lock,
  obscure: true,
),

        const SizedBox(height: 16),

        AppTextField(
          controller: _confirmPasswordController,
          hint: "Confirm Password",
          icon: Icons.lock_outline,
          obscure: true,
        ),
      ],
    ),
  );
}

Future<void> _registerOrganization() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  if (_passwordController.text != _confirmPasswordController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Passwords do not match"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final response = await ref.read(authProvider.notifier).registerOrganization(
        organizationName: _organizationNameController.text.trim(),
        organizationType: _organizationType,
        organizationEmail: _organizationEmailController.text.trim(),
        organizationPhone: _organizationPhoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        stateName: _stateController.text.trim(),
        country: _countryController.text.trim(),
        pincode: _pincodeController.text.trim(),
        adminName: _adminNameController.text.trim(),
        adminEmail: _adminEmailController.text.trim(),
        adminPhone: _adminPhoneController.text.trim(),
        password: _passwordController.text,
      );

  if (!mounted) return;

  if (response == null) {
    final error = ref.read(authProvider).error ?? "Registration failed";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  _showSuccessDialog(response.organizationCode);
}

void _showSuccessDialog(String organizationCode) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return AlertDialog(
        title: const Text("🎉 Organization Registered"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Share this organization code with your residents.",
            ),
            const SizedBox(height: 20),
            SelectableText(
              organizationCode,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Back to Login"),
          ),
        ],
      );
    },
  );
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      elevation: 0,
      title: const Text("Register Organization"),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              const Icon(
                Icons.apartment,
                size: 70,
                color: Colors.blue,
              ),

              const SizedBox(height: 16),

              const Center(
                child: Text(
                  "Register Organization",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  "Create a secure community for your residents",
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 30),

              _buildOrganizationCard(),

              const SizedBox(height: 24),

              _buildAdminCard(),

              const SizedBox(height: 30),

              PrimaryButton(
                title: "REGISTER ORGANIZATION",
                onPressed: _registerOrganization,
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Back to Login"),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
  
    }