import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termos de Uso')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Termos de Uso',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Última atualização: Junho 2025',
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
            _Section(
              title: '1. Aceitação dos Termos',
              content:
                  'Ao utilizar o aplicativo Onde Comer em Salvador, você concorda '
                  'com estes Termos de Uso. Se não concordar, não utilize o aplicativo.',
            ),
            _Section(
              title: '2. Descrição do Serviço',
              content:
                  'O Onde Comer em Salvador é uma plataforma que conecta usuários '
                  'a restaurantes em Salvador, permitindo busca, avaliações, '
                  'check-ins, programas de fidelidade e interação social.',
            ),
            _Section(
              title: '3. Cadastro e Conta',
              content:
                  'Para utilizar o serviço, você deve criar uma conta com informações '
                  'verdadeiras. Você é responsável pela segurança de sua conta e senha.',
            ),
            _Section(
              title: '4. Uso Adequado',
              content:
                  'É proibido publicar conteúdo ofensivo, falso, difamatório ou que '
                  'viole direitos de terceiros. Conteúdos são moderados automaticamente '
                  'e manualmente.',
            ),
            _Section(
              title: '5. Propriedade Intelectual',
              content:
                  'Todo o conteúdo do aplicativo é protegido por direitos autorais. '
                  'Avaliações e comentários enviados pelo usuário podem ser utilizados '
                  'pela plataforma.',
            ),
            _Section(
              title: '6. Limitação de Responsabilidade',
              content:
                  'O Onde Comer não se responsabiliza pela qualidade dos serviços '
                  'prestados pelos restaurantes listados na plataforma.',
            ),
            _Section(
              title: '7. Alterações nos Termos',
              content:
                  'Podemos alterar estes termos a qualquer momento. Alterações '
                  'significativas serão comunicadas aos usuários.',
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
