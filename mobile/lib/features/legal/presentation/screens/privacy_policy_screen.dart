import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de Privacidade')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Política de Privacidade',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Última atualização: Junho 2025',
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
            _Section(
              title: '1. Dados Coletados',
              content:
                  'Coletamos dados que você fornece ao criar sua conta (nome, email, '
                  'nome de usuário) e dados gerados pelo uso do aplicativo (avaliações, '
                  'check-ins, preferências).',
            ),
            _Section(
              title: '2. Uso dos Dados',
              content:
                  'Seus dados são utilizados para: personalizar sua experiência, '
                  'exibir recomendações, processar check-ins e pontos de fidelidade, '
                  'e enviar notificações relevantes.',
            ),
            _Section(
              title: '3. Compartilhamento',
              content:
                  'Não vendemos seus dados pessoais. Compartilhamos apenas: '
                  'avaliações e comentários públicos, informações necessárias para '
                  'restaurantes processarem seus check-ins.',
            ),
            _Section(
              title: '4. Segurança',
              content:
                  'Utilizamos criptografia, autenticação JWT e práticas de segurança '
                  'modernas para proteger seus dados. Senhas são armazenadas com hash '
                  'seguro (BCrypt).',
            ),
            _Section(
              title: '5. Seus Direitos (LGPD)',
              content:
                  'De acordo com a Lei Geral de Proteção de Dados, você tem direito a:\n'
                  '• Acessar seus dados pessoais\n'
                  '• Exportar seus dados (portabilidade)\n'
                  '• Solicitar correção de dados incorretos\n'
                  '• Solicitar exclusão da sua conta\n'
                  '• Revogar consentimento a qualquer momento',
            ),
            _Section(
              title: '6. Retenção de Dados',
              content:
                  'Seus dados são mantidos enquanto sua conta estiver ativa. Após '
                  'solicitar exclusão, seus dados são desativados (soft delete) e '
                  'removidos permanentemente após 30 dias.',
            ),
            _Section(
              title: '7. Cookies e Rastreamento',
              content:
                  'O aplicativo não utiliza cookies de terceiros. Dados de sessão '
                  'são armazenados localmente no dispositivo.',
            ),
            _Section(
              title: '8. Contato',
              content:
                  'Para exercer seus direitos ou tirar dúvidas, acesse as configurações '
                  'do aplicativo em Minha Conta > Exportar Dados ou Excluir Conta.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
