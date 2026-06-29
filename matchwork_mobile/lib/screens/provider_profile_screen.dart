import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../providers/app_state_provider.dart';

class ProviderProfileScreen extends StatefulWidget {
  final String providerId;
  const ProviderProfileScreen({super.key, required this.providerId});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.getUserProfile(widget.providerId);
    setState(() {
      _profileData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const surfaceNavy = Color(0xFF0F172A);
    const accentBlue = Color(0xFF2563EB);

    final appState = Provider.of<AppStateProvider>(context);
    final isDark = appState.isDarkMode;
    final currentUserId = SupabaseService.instance.currentUser?.id;
    final isOwnProfile = currentUserId == widget.providerId;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : surfaceNavy;
    final subTextColor = isDark ? Colors.white70 : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceNavy,
        foregroundColor: Colors.white,
        title: const Text('MatchWork', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _showEditProfileDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
              ? const Center(child: Text('No se encontró el perfil de trabajador'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Header Profile Card
                      Card(
                        color: cardBgColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundImage: NetworkImage(
                                  _profileData!['avatar_url'] ??
                                      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _profileData!['name'] ?? 'Trabajador Profesional',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Profesional Verificado',
                                      style: TextStyle(
                                        color: Color(0xFF065F46),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.star, color: Colors.amber, size: 18),
                                            Icon(Icons.star, color: Colors.amber, size: 18),
                                            Icon(Icons.star, color: Colors.amber, size: 18),
                                            Icon(Icons.star, color: Colors.amber, size: 18),
                                            Icon(Icons.star, color: Colors.amber, size: 18),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '128 Reseñas',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: subTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 36,
                                    width: 1,
                                    color: Colors.grey[300],
                                  ),
                                  const Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '340+',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: accentBlue,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Trabajos Completados',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Trabajos Recientes Section
                      _buildSectionTitle(context, 'Trabajos Recientes', textColor, trailing: 'Ver Todo'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildWorkGalleryImage(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuAiGmsJtAqtn7Pw0PWMqzdwYo2Sds1YRsWuIXzZ-JzJkJ6aW2Eur_ysO98zKSPnHJpNWZuN_oC-5XSGUSm85icfBTrGpTVmVTbRjHPJk5Wf3U7UaDA2mMPaesv28I-eKJrqOyAl_kguQ2WkQqB4dtuZ2jbeMpHLt561sXewzbxjoloQsiIL1VVcvtgzVsSx8eIyqb4_0STDitvVG1Cb2AfygWSaxCQglxqJWWTcyE20HGqt7MvzaAGuPW0GGMSnkxbvLyGhBuHWiCw',
                            ),
                            const SizedBox(width: 12),
                            _buildWorkGalleryImage(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuDXqfjGwJReW1F2wk3N2uJ6q3fXsl1wgRSA2kmHsVsxNuhgejWhcEqSHwP9lue8PLd6m2-HYgSHHv5NJhlYMCfvhsQRDipEFu07SzA8Lb_45Yxy05IYfl-GKpBHYkJDimAFL9mhPlXaVNuKB_acKkn130iv-K1-GDb--Rwe7gSyhzAcFQ0zFLpfsC9pt4wzlv_dsE6NITlQ1UNaG7oaXHtqeMW8R_Fxon-fALO9NYahU75RbTBtlSVdFsr4JcZvLcGxaKtP8tkWuKw',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Descripción del Servicio Section
                      Card(
                        color: cardBgColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, color: accentBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Descripción del Servicio',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _profileData!['description'] ?? 'Sin descripción de servicio disponible.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subTextColor,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Tarifas y Pagos Section
                      Card(
                        color: cardBgColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.payments_outlined, color: accentBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tarifas y Pagos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${_profileData!['price'] ?? '\$0'} / hora base',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Incluye tarifa de diagnóstico estándar. Los costos de materiales se calculan por separado.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subTextColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              Text(
                                'MÉTODOS DE PAGO ACEPTADOS:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: subTextColor,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildPaymentMethodsRow(context),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. Garantía y Experiencia Section
                      Card(
                        color: cardBgColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.verified_user_outlined, color: accentBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Experiencia y Garantía',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.work_history_outlined, 'Experiencia:', _profileData!['experience'] ?? '5+ años', textColor),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.security_outlined, 'Garantía:', _profileData!['guarantee'] ?? '30 días sobre mano de obra', textColor),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 6. Action Button (If Own Profile: "Editar Perfil", If Customer: "Solicitar")
                      if (isOwnProfile)
                        ElevatedButton.icon(
                          onPressed: _showEditProfileDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar mi Perfil de Trabajador', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, Color textColor, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        if (trailing != null)
          TextButton(
            onPressed: () {},
            child: Row(
              children: [
                Text(trailing, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF2563EB)),
              ],
            ),
          )
      ],
    );
  }

  Widget _buildWorkGalleryImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 160,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 160,
          height: 120,
          color: Colors.grey[350],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsRow(BuildContext context) {
    final list = _profileData!['payment_methods'];
    List<String> payments = [];
    if (list is List) {
      payments = list.map((e) => e.toString()).toList();
    } else if (list is String) {
      payments = list.replaceAll(RegExp(r'[{}"[\]]'), '').split(',');
    } else {
      payments = ['cash', 'transfer', 'card'];
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (payments.contains('cash')) _buildPaymentBadge(Icons.money, 'Efectivo'),
        if (payments.contains('transfer')) _buildPaymentBadge(Icons.account_balance, 'Transferencia'),
        if (payments.contains('card')) _buildPaymentBadge(Icons.credit_card, 'Tarjeta'),
      ],
    );
  }

  Widget _buildPaymentBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _profileData!['name']);
    final professionController = TextEditingController(text: _profileData!['profession']);
    final descController = TextEditingController(text: _profileData!['description']);
    final priceController = TextEditingController(text: _profileData!['price']);
    final expController = TextEditingController(text: _profileData!['experience']);
    final guarController = TextEditingController(text: _profileData!['guarantee']);

    final list = _profileData!['payment_methods'];
    List<String> payments = [];
    if (list is List) {
      payments = list.map((e) => e.toString()).toList();
    } else if (list is String) {
      payments = list.replaceAll(RegExp(r'[{}"[\]]'), '').split(',');
    } else {
      payments = ['cash', 'transfer', 'card'];
    }

    bool payCash = payments.contains('cash');
    bool payTransfer = payments.contains('transfer');
    bool payCard = payments.contains('card');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.edit_note, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text('Editar Perfil de Trabajador'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre Completo'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: professionController,
                      decoration: const InputDecoration(labelText: 'Profesión / Especialidad'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Descripción del Servicio'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Precio por Hora Base (Ej: \$15.000)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: expController,
                      decoration: const InputDecoration(labelText: 'Experiencia (Ej: 5+ años)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: guarController,
                      decoration: const InputDecoration(labelText: 'Garantía (Ej: 30 días de garantía)'),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Métodos de Pago Aceptados:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('Efectivo'),
                      value: payCash,
                      onChanged: (val) => setDialogState(() => payCash = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Transferencia Bancaria'),
                      value: payTransfer,
                      onChanged: (val) => setDialogState(() => payTransfer = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Tarjeta de Crédito / Débito'),
                      value: payCard,
                      onChanged: (val) => setDialogState(() => payCard = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final updatedPayments = <String>[];
                    if (payCash) updatedPayments.add('cash');
                    if (payTransfer) updatedPayments.add('transfer');
                    if (payCard) updatedPayments.add('card');

                    final updates = {
                      'name': nameController.text.trim(),
                      'profession': professionController.text.trim(),
                      'description': descController.text.trim(),
                      'price': priceController.text.trim(),
                      'experience': expController.text.trim(),
                      'guarantee': guarController.text.trim(),
                      'payment_methods': updatedPayments,
                    };

                    await SupabaseService.instance.updateUserProfile(widget.providerId, updates);

                    // Sync changes into provider table if the worker is online
                    final providers = await SupabaseService.instance.getProviders();
                    final isOnline = providers.any((p) => p.id == widget.providerId && p.status != 'Fuera de servicio');
                    if (isOnline) {
                      await SupabaseService.instance.updateProviderAvailability(
                        providerId: widget.providerId,
                        status: 'En línea',
                      );
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Perfil actualizado con éxito!')),
                      );
                      Navigator.pop(context);
                      _loadProfile();
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
