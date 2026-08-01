import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../providers/app_state_provider.dart';
import '../main.dart';
import '../models/categories_data.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isSignUp = false;
  String _selectedRole = 'customer'; // 'customer' or 'provider'
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  String? _selectedCategory = 'reparaciones_mantenimiento';
  String? _selectedSubcategory = 'gasfiteria';

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Recuperar contraseña', style: TextStyle(color: Color(0xFF0F172A))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.', style: TextStyle(color: Colors.black87)),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Correo electrónico',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isNotEmpty) {
                  Navigator.pop(context); // Cerrar diálogo
                  try {
                    await SupabaseService.instance.resetPassword(email);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Se ha enviado un enlace a tu correo para restablecer la contraseña.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al enviar el correo. Verifica tu dirección.')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Enviar Enlace', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    try {
      if (_isSignUp) {
        // Sign up
        final user = await SupabaseService.instance.signUp(
          email: email,
          password: password,
          name: name,
          role: _selectedRole,
          category: _selectedRole == 'provider' ? _selectedCategory : null,
          subcategory: _selectedRole == 'provider' ? _selectedSubcategory : null,
        );

        if (user != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Registro exitoso! Por favor inicia sesión.')),
            );
            setState(() {
              _isSignUp = false;
            });
          }
        }
      } else {
        // Sign in
        final response = await SupabaseService.instance.signIn(
          email: email,
          password: password,
        );

        final user = response.user;
        if (user != null && mounted) {
          // Obtener el rol real del usuario desde su perfil en Supabase
          final profile = await SupabaseService.instance.getUserProfile(user.id);
          final role = profile?['role'] ?? 'customer';

          final appState = Provider.of<AppStateProvider>(context, listen: false);
          await appState.switchRole(role);
          await appState.initializeProviderState(user.id);
          
          NotificationService().saveTokenToDatabase(user.id);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AuthWrapper(),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors matching DESIGN.md
    const surfaceNavy = Color(0xFF0F172A);
    const accentBlue = Color(0xFF2563EB);
    const borderGrey = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Logo or Emblem
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surfaceNavy,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.handshake_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Reinicia la app (flutter run) para ver el logo',
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'MatchWork',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: surfaceNavy,
                      letterSpacing: -0.02,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp ? 'Crea una cuenta nueva' : 'Inicia sesión para continuar',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name Field (Only on Sign Up)
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: surfaceNavy),
                      textCapitalization: TextCapitalization.words,
                      maxLength: 50,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo',
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: borderGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: accentBlue, width: 2),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: surfaceNavy),
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: borderGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: accentBlue, width: 2),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Ingresa tu correo';
                      if (!val.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: surfaceNavy),
                    maxLength: 30,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: borderGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: accentBlue, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (val) => val == null || val.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 16),

                  // Role Segment Selector (Only on Sign Up)
                  if (_isSignUp) ...[
                    const Text(
                      'Regístrate como:',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: surfaceNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Cliente')),
                            selected: _selectedRole == 'customer',
                            onSelected: (val) {
                              if (val) setState(() => _selectedRole = 'customer');
                            },
                            selectedColor: accentBlue,
                            labelStyle: TextStyle(
                              color: _selectedRole == 'customer' ? Colors.white : surfaceNavy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Prestador')),
                            selected: _selectedRole == 'provider',
                            onSelected: (val) {
                              if (val) setState(() => _selectedRole = 'provider');
                            },
                            selectedColor: accentBlue,
                            labelStyle: TextStyle(
                              color: _selectedRole == 'provider' ? Colors.white : surfaceNavy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedRole == 'provider') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Categoría de Servicio',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: surfaceNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        style: const TextStyle(color: surfaceNavy),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: borderGrey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: accentBlue, width: 2),
                          ),
                        ),
                        items: categories.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value.label));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                            if (val != null && categories[val] != null) {
                              _selectedSubcategory = categories[val]!.subcategories.keys.first;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Subcategoría de Servicio',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: surfaceNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedSubcategory,
                        style: const TextStyle(color: surfaceNavy),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: borderGrey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: accentBlue, width: 2),
                          ),
                        ),
                        items: _selectedCategory == null || categories[_selectedCategory] == null
                            ? []
                            : categories[_selectedCategory]!.subcategories.entries.map((e) {
                                return DropdownMenuItem(value: e.key, child: Text(e.value.label));
                              }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSubcategory = val;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],

                  // Action Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isSignUp ? 'Registrarse' : 'Iniciar Sesión',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Forgot Password Button (Only in login mode)
                  if (!_isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        style: TextButton.styleFrom(foregroundColor: accentBlue),
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),

                  // Toggle Button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                      });
                    },
                    style: TextButton.styleFrom(foregroundColor: accentBlue),
                    child: Text(
                      _isSignUp 
                          ? '¿Ya tienes una cuenta? Inicia sesión' 
                          : '¿No tienes una cuenta? Regístrate',
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  // Privacy Policy Link
                  TextButton(
                    onPressed: () async {
                      final url = Uri.parse('https://matchwork.com/privacidad');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    child: const Text(
                      'Términos, Condiciones y Políticas de Privacidad',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
