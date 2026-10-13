import 'package:flutter/material.dart';
import '../../data/models/citizen_profile.dart';
import '../../data/services/supabase_service.dart';
import '../theme/dinig_theme.dart';
import '../view_models/dinig_view_model.dart';
import 'help_card_screen.dart';

class AuthScreen extends StatefulWidget {
  final DinigViewModel viewModel;
  final VoidCallback onAuthenticated;
  final VoidCallback? onSignedUp;
  final bool startOnRegister;

  const AuthScreen({
    super.key,
    required this.viewModel,
    required this.onAuthenticated,
    this.onSignedUp,
    this.startOnRegister = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sign In Tab Controllers
  final _loginPhoneController =
      TextEditingController();

  // Registration Tab Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController =
      TextEditingController();
  final _barangayController = TextEditingController();
  final _addressController =
      TextEditingController();
  final _contactNameController =
      TextEditingController();
  final _contactPhoneController =
      TextEditingController();
  final _medicalController =
      TextEditingController();

  // Selected careSupportOptions labels (Care Mode only).
  final Set<String> _support = {};
  AppFor _appFor = AppFor.myself;

  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccessMessage = true;

  final List<String> _barangayOptions = [
    'Brgy. Canlubang',
    'Brgy. 171',
    'Brgy. Turbina',
    'Brgy. Real',
    'Brgy. Bucal',
    'Brgy. Pansol',
  ];

  @override
  void initState() {
    super.initState();
    // The dropdown shows the first barangay by default, so the field must match.
    _barangayController.text = _barangayOptions.first;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.startOnRegister ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginPhoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _barangayController.dispose();
    _addressController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  /// Selected labels in list order, joined the way the profile stores them.
  String get _supportNotes =>
      careSupportOptions.where(_support.contains).join('; ');

  void _applyDemoAccount({
    required String firstName,
    required String lastName,
    required String phone,
    required String barangay,
    required String address,
    required String contactName,
    required String contactPhone,
  }) {
    setState(() {
      _loginPhoneController.text = phone;
      _firstNameController.text = firstName;
      _lastNameController.text = lastName;
      _phoneController.text = phone;
      _emailController.text =
          '${firstName.toLowerCase()}.${lastName.toLowerCase().replaceAll(' ', '')}@gmail.com';
      _barangayController.text = barangay;
      _addressController.text = address;
      _contactNameController.text = contactName;
      _contactPhoneController.text = contactPhone;
    });
  }

  Future<void> _handleLogin() async {
    final phone = _loginPhoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter your registered mobile phone number.';
        _isSuccessMessage = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final current = widget.viewModel.userProfile;
    final updated = current.copyWith(
      phoneNumber: phone,
      isRegistered: true,
      isLoggedIn: true,
    );

    await widget.viewModel.saveUserProfile(updated);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      widget.onAuthenticated();
    }
  }

  Future<void> _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final barangay = _barangayController.text.trim();
    final address = _addressController.text.trim();
    final contactName = _contactNameController.text.trim();
    final contactPhone = _contactPhoneController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        barangay.isEmpty) {
      setState(() {
        _statusMessage = 'Please fill in your name, phone, and barangay.';
        _isSuccessMessage = false;
      });
      return;
    }
    if (_appFor.isCareMode && contactPhone.isEmpty) {
      setState(() {
        _statusMessage =
            "Please add the caregiver's phone number. Care Mode calls it.";
        _isSuccessMessage = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final newProfile = CitizenProfile(
      fullName: '$firstName $lastName'.trim(),
      phoneNumber: phone,
      email: _emailController.text.trim(),
      barangay: barangay,
      city: 'Calamba',
      province: 'Laguna',
      address: address,
      emergencyContactName: contactName,
      emergencyContactPhone: contactPhone,
      medicalNotes: _medicalController.text.trim(),
      appFor: _appFor,
      supportNotes: _appFor.isCareMode ? _supportNotes : '',
      isRegistered: true,
      isLoggedIn: true,
    );

    // Sync with Supabase public.residents table
    final registeredOnSupabase =
        await SupabaseService.registerResident(newProfile);

    await widget.viewModel.saveUserProfile(newProfile);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccessMessage = true;
        _statusMessage = registeredOnSupabase
            ? 'Profile saved and registered.'
            : 'Profile saved on this phone only. The registry could not be reached.';
      });
      if (widget.onSignedUp != null) {
        widget.onSignedUp!();
      } else {
        widget.onAuthenticated();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Resident Authentication'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: DinigColors.primaryBlue,
          unselectedLabelColor: DinigColors.textSecondary,
          indicatorColor: DinigColors.primaryBlue,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Sign In'),
            Tab(text: 'Register Resident'),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_statusMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSuccessMessage
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isSuccessMessage
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isSuccessMessage
                          ? const Color(0xFF166534)
                          : const Color(0xFF991B1B),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Fills the screen on any phone size; each tab scrolls itself.
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(child: _buildSignInTab()),
                    _buildRegisterTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Sign in with Mobile Phone',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: DinigColors.darkNavy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your mobile number to open your profile on this phone. Demo sign-in: no password or code is checked.',
          style: TextStyle(fontSize: 13, color: DinigColors.textSecondary),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _loginPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Registered Mobile Phone',
            hintText: '+63 917 123 4567',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone_android_outlined),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: DinigColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'SIGN IN TO DINIG',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ),
        const SizedBox(height: 28),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'QUICK DEMO PROFILES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: DinigColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        _buildDemoCard(
          name: 'Maria Santos',
          phone: '+63 917 123 4567',
          barangay: 'Brgy. Canlubang',
          onTap: () {
            _applyDemoAccount(
              firstName: 'Maria',
              lastName: 'Santos',
              phone: '+63 917 123 4567',
              barangay: 'Brgy. Canlubang',
              address: 'Block 3, Sitio Buntog',
              contactName: 'Juan Santos (Husband)',
              contactPhone: '+63 918 987 6543',
            );
            _handleLogin();
          },
        ),
        const SizedBox(height: 10),
        _buildDemoCard(
          name: 'Juan Dela Cruz',
          phone: '+63 917 842 1928',
          barangay: 'Brgy. 171, Calamba',
          onTap: () {
            _applyDemoAccount(
              firstName: 'Juan',
              lastName: 'Dela Cruz',
              phone: '+63 917 842 1928',
              barangay: 'Brgy. 171',
              address: 'Purok 4, Sitio Riverside',
              contactName: 'Maria Dela Cruz (Spouse)',
              contactPhone: '+63 920 551 8839',
            );
            _handleLogin();
          },
        ),
      ],
    );
  }

  Widget _buildRegisterTab() {
    return ListView(
      children: [
        const SizedBox(height: 8),
        const Text(
          'Register Citizen Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: DinigColors.darkNavy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your details are saved on this phone and sent to the DINIG resident registry, so a report can carry your name and barangay.',
          style: TextStyle(fontSize: 13, color: DinigColors.textSecondary),
        ),
        const SizedBox(height: 16),
        const Text(
          'This app is for',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: DinigColors.darkNavy,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final a in AppFor.values)
              ChoiceChip(
                label: Text(a.label),
                selected: _appFor == a,
                onSelected: (_) => setState(() => _appFor = a),
              ),
          ],
        ),
        if (_appFor.isCareMode)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Care Mode shows big picture buttons. Enter the details of the person who will use this phone.',
              style: TextStyle(fontSize: 12, color: DinigColors.textSecondary),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Mobile Phone Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _barangayOptions.contains(_barangayController.text)
              ? _barangayController.text
              : _barangayOptions.first,
          decoration: const InputDecoration(
            labelText: 'Barangay (Calamba City)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
          items: _barangayOptions
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _barangayController.text = val;
              });
            }
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Sitio / Street / House No.',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _contactNameController,
          decoration: InputDecoration(
            labelText: _appFor.isCareMode
                ? 'Caregiver name'
                : 'Emergency Contact Person & Relationship',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.contact_phone_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _contactPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: _appFor.isCareMode
                ? 'Caregiver phone (required)'
                : 'Emergency Contact Phone Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone_in_talk_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _medicalController,
          decoration: const InputDecoration(
            labelText: 'Medical Notes / Allergies (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medical_services_outlined),
          ),
        ),
        const SizedBox(height: 14),
        if (_appFor.isCareMode) ...[
          const SizedBox(height: 18),
          const Text(
            'How should responders approach? (Optional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: DinigColors.darkNavy,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final option in careSupportOptions)
                FilterChip(
                  label: Text(option),
                  selected: _support.contains(option),
                  onSelected: (on) => setState(
                    () => on ? _support.add(option) : _support.remove(option),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'This is what a responder will see',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: DinigColors.darkNavy,
            ),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: Listenable.merge([
              _firstNameController,
              _lastNameController,
              _contactNameController,
              _contactPhoneController,
              _medicalController,
            ]),
            builder: (context, _) => HelpCard(
              profile: CitizenProfile(
                fullName:
                    '${_firstNameController.text} ${_lastNameController.text}'.trim(),
                emergencyContactName: _contactNameController.text,
                emergencyContactPhone: _contactPhoneController.text,
                medicalNotes: _medicalController.text,
                supportNotes: _supportNotes,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'This card is shown on this phone. It is not sent with the alert.',
            style: TextStyle(fontSize: 12, color: DinigColors.textSecondary),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: DinigColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'REGISTER RESIDENT PROFILE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDemoCard({
    required String name,
    required String phone,
    required String barangay,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: DinigColors.borderLight),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: DinigColors.softBlue,
          child: Text(
            name[0],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: DinigColors.primaryBlue,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '$barangay • $phone',
          style:
              const TextStyle(fontSize: 12, color: DinigColors.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: DinigColors.textSecondary),
      ),
    );
  }
}
