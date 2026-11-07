import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  bool _editing = false;
  bool _dataActionLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authViewModelProvider.notifier)
        .updateProfile(_nameCtrl.text.trim(), null);
    setState(() => _editing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado!')),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authViewModelProvider.notifier).logout();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  Future<void> _openTerms() async {
    context.push(AppRoutes.termsOfUse);
  }

  Future<void> _openPrivacy() async {
    context.push(AppRoutes.privacyPolicy);
  }

  Future<void> _exportMyData() async {
    setState(() => _dataActionLoading = true);
    try {
      final payload = await ref
          .read(authViewModelProvider.notifier)
          .exportMyData(format: 'json');

      if (!mounted) return;

      final decoded = jsonDecode(payload);
      final prettyJson = const JsonEncoder.withIndent('  ').convert(decoded);

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Exportar meus dados'),
          content: SingleChildScrollView(
            child: SelectableText(prettyJson),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: prettyJson));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Dados copiados para a área de transferência.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Copiar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível exportar seus dados: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _dataActionLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
          'Essa ação remove sua conta e seus dados pessoais. Você poderá precisar criar uma nova conta depois.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _dataActionLoading = true);
    try {
      await ref.read(authViewModelProvider.notifier).deleteMyAccount();
      if (mounted) context.go(AppRoutes.login);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível excluir a conta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _dataActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.primaryYellow,
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameCtrl,
                      enabled: _editing,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Informe o nome';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: user.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: user.profileType,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de perfil',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    if (authState.error != null) ...[
                      const SizedBox(height: 16),
                      Text(authState.error!,
                          style: const TextStyle(color: AppTheme.error)),
                    ],
                    const SizedBox(height: 32),
                    if (!_editing && user.profileType != 'Admin') ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Gastronomia & Atividades',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.confirmation_number_outlined,
                            color: Colors.orange),
                        title: const Text('Meus Tickets de Ofertas'),
                        subtitle: const Text('Cupons e tickets resgatados'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.myTickets),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.military_tech_outlined,
                            color: Colors.amber),
                        title: const Text('Fidelidade & Selos'),
                        subtitle:
                            const Text('Passaporte gastronômico e conquistas'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.loyalty),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.pin_drop_outlined,
                            color: Colors.teal),
                        title: const Text('Histórico de Check-ins'),
                        subtitle: const Text('Lugares onde você esteve'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.checkInHistory),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.favorite_border,
                            color: Colors.red),
                        title: const Text('Meus Favoritos'),
                        subtitle: const Text('Restaurantes e pratos salvos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.favorites),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.bookmark_border,
                            color: Colors.blue),
                        title: const Text('Minhas Listas'),
                        subtitle: const Text('Coleções gastronômicas públicas'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.wishlists),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.casino_outlined,
                            color: Colors.orange),
                        title: const Text('Onde Comer Hoje? 🎲'),
                        subtitle: const Text(
                            'Enquete WhatsApp & Roleta com a galera'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.ondeComerHoje),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.table_restaurant_outlined,
                            color: Colors.teal),
                        title: const Text('Minhas Reservas'),
                        subtitle: const Text('Acompanhe suas mesas reservadas'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.myReservations),
                      ),
                      if (user.profileType != 'Restaurant' &&
                          user.profileType != 'Admin') ...[
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.add_business_outlined,
                              color: AppTheme.primaryYellowDark),
                          title: const Text('Tem um Restaurante?'),
                          subtitle: const Text(
                              'Cadastre seu estabelecimento no guia'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push(AppRoutes.restaurantDashboard),
                        ),
                      ],
                      if (user.profileType == 'Restaurant') ...[
                        const Divider(),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Gestão do Restaurante',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.analytics_outlined,
                              color: Colors.green),
                          title: const Text('Painel de Indicadores & Métricas'),
                          subtitle: const Text(
                              'Acessos, horários de pico e avaliações'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/restaurant/panel'),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.qr_code_scanner,
                              color: Colors.teal),
                          title: const Text('Validar Ticket de Oferta (QR)'),
                          subtitle: const Text(
                              'Escanear cupom apresentado pelo cliente'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push(AppRoutes.finalizePromotionTicket),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.restaurant_menu,
                              color: Colors.deepOrange),
                          title: const Text('Gerenciar Cardápio & Pratos'),
                          subtitle: const Text('Fotos, preços e categorias'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push(AppRoutes.restaurantDashboard),
                        ),
                      ],
                      if (user.profileType == 'Admin') ...[
                        const Divider(),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Administração',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                              Icons.admin_panel_settings_outlined,
                              color: Colors.deepPurple),
                          title: const Text('Painel Geral Admin'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(AppRoutes.admin),
                        ),
                      ],
                      const Divider(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Configurações & Legal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.notifications_none_outlined,
                            color: Colors.indigo),
                        title: const Text('Preferências de Notificações'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push(AppRoutes.notificationPreferences),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_outlined,
                            color: Colors.blueGrey),
                        title: const Text('Termos de uso'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openTerms,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.privacy_tip_outlined,
                            color: Colors.blueGrey),
                        title: const Text('Política de privacidade'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openPrivacy,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.file_download_outlined,
                            color: Colors.green),
                        title: const Text('Exportar meus dados'),
                        trailing: _dataActionLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _dataActionLoading ? null : _exportMyData,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_forever_outlined,
                            color: AppTheme.error),
                        title: const Text('Excluir minha conta',
                            style: TextStyle(color: AppTheme.error)),
                        trailing: _dataActionLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right,
                                color: AppTheme.error),
                        onTap: _dataActionLoading ? null : _deleteAccount,
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],
                    if (_editing) ...[
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _save,
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Salvar alterações'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          _nameCtrl.text = user.name;
                          setState(() => _editing = false);
                        },
                        child: const Text('Cancelar'),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: AppTheme.error),
                        label: const Text('Sair',
                            style: TextStyle(color: AppTheme.error)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
