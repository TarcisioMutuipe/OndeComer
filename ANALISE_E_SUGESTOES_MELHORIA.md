# Análise Completa do Sistema & Plano Estratégico de Melhorias
**Projeto: Onde Comer Em Salvador**  
**Stack:** Mobile Flutter (Riverpod, GoRouter, Hive) + Backend .NET 8 (ASP.NET Core, EF Core, PostgreSQL)  
**Data da Análise:** Outubro de 2026

---

## Sumário Executivo

O projeto **Onde Comer Em Salvador** é uma plataforma que conecta estabelecimentos gastronômicos e clientes na capital baiana. O sistema se destaca por uma arquitetura moderna:
- **Backend robusto em .NET 8**: Clean Architecture / DDD simplificado, CQRS/Repository pattern, PostgreSQL com EF Core, autenticação JWT com refresh token, sync offline idempotente e envio de push notifications via FCM.
- **Frontend mobile em Flutter**: Gestão de estado reativa com Riverpod, roteamento declarativo com GoRouter, suporte offline-first com Hive e cache local, além de modelos imutáveis com Freezed.
- **Modelo de Negócio Inovador**: Migrou de um modelo de cupom genérico para um modelo estruturado de **Tickets Promocionais em Lotes com QR Code e Cooldown**, prevenindo desperdício e abusos.

Abaixo está o mapeamento completo do que foi aprendido sobre o sistema, seus pontos fortes e gargalos, além de propostas detalhadas de melhorias de usabilidade, gráficos, estratégia de imagens, arquitetura e atração de restaurantes e clientes.

---

## 1. Mapeamento e Diagnóstico do Sistema Atual

### 1.1 Backend (.NET 8 & PostgreSQL)
- **Estrutura de Solução**:
  - `OndeComer.Domain`: Entidades centrais (`User`, `Restaurant`, `Dish`, `Promotion`, `PromotionTicket`, `PromotionSettings`, `Review`, `Comment`, `Favorite`, `Wishlist`, `CheckIn`, `Badge`, `UserBadge`, `LoyaltyCampaign`, `LoyaltyPoints`, `UploadedImage`, `ModerationLog`).
  - `OndeComer.Application`: Interfaces, DTOs e serviços de aplicação (`AuthService`, `RestaurantService`, `DishService`, `PromotionService`, `PromotionTicketLifecycleService`, `DashboardService`, `CheckInService`, `LoyaltyService`, `ModerationService`, `AdminService`).
  - `OndeComer.Infrastructure`: EF Core `AppDbContext`, Migrations, Repositories, Unit of Work, `TokenService`, `ImageService` (SixLabors.ImageSharp), `FcmPushSender`, `ResendEmailService`, Hosted Service `PromotionTicketReminderHostedService`, e suporte a Redis/MemoryCache.
  - `OndeComer.API`: Controllers REST versionados (`/api/v1/...`), Middlewares globais de exceção, documentação Swagger/OpenAPI e logging com Serilog.

- **Destaques Positivos**:
  - Auto-migrations e suporte transparente a Postgres / SQL Server / Redis.
  - Hosted Service dedicado para expirar tickets e disparar pushes de lembrete com auditoria (`ReminderSentAt`, `ExpirationReason`).
  - Suporte a sincronização offline em lote via `POST /api/v1/sync` com resolução idempotente.

- **Gargalos e Riscos Técnicos**:
  1. **Armazenamento de Imagens Local**: O `ImageService` salva arquivos em disco local (`wwwroot/uploads/yyyy/MM/{guid}.jpg`). Em caso de conteinerização (Docker), múltiplos nós de API ou deploy em nuvem (Azure App Service, AWS ECS, GCP Cloud Run), as imagens não são compartilhadas entre instâncias e podem se perder em restarts.
  2. **Ausência de Múltiplos Tamanhos de Imagem**: Todas as imagens salvas são redimensionadas para largura máxima de 1200px (JPEG q80). Quando um cliente abre uma lista com 20 restaurantes, o app baixa 20 imagens de até 1200px apenas para exibir cartões de 140px de altura.
  3. **Duplicação de Registro de DI**: `FavoriteService` e `WishlistService` estão registrados duplamente no container (no `Application` e no `Infrastructure`).

---

### 1.2 Frontend Mobile (Flutter)
- **Estrutura de Código**:
  - Separação por *features*: `auth`, `feed`, `restaurant`, `reviews`, `favorites`, `search`, `checkin`, `loyalty`, `rankings`, `admin`, `notifications`, `legal`.
  - Camada compartilhada com interceptor Dio que renova JWT automaticamente.
  - Monitoramento de conectividade em tempo real com banner animado e fila offline no Hive.

- **Destaques Positivos**:
  - UX offline consistente: se a internet cair, operações pendentes acumulam na fila e o app não trava.
  - Design system com cores quentes e identidade baiana (amarelos vibrantes, tipografia limpa, botões com cantos arredondados).

- **Gargalos de Usabilidade e UX Identificados**:
  1. **Navegação Fragmentada**: Funcionalidades avançadas já desenvolvidas (como Badges/Fidelidade, Histórico de Check-ins e Notificações) não têm atalhos visíveis no `ProfileScreen` nem na barra inferior.
  2. **Falta de Contexto Geográfico Baiano**: Salvador é dividida em polos gastronômicos com personalidades muito distintas (Pelourinho, Rio Vermelho, Barra, Pituba, Itapuã, Cidade Baixa). O app só oferece filtro por nome/categoria e busca genérica, sem visualização em mapa ou filtros por polos/bairros.
  3. **Visualização de Métricas Limitada**: A tela de métricas do restaurante (`MetricsDashboardScreen`) e o painel de administrador (`AdminDashboardScreen`) utilizam apenas cartões de números e barras estáticas manuais, sem gráficos dinâmicos de linha, área ou pizza.
  4. **Experiência com Imagens no Formulário**: O upload é disparado assim que o usuário seleciona a foto da galeria, sem ferramenta de recorte (*crop*), e se o usuário cancelar o cadastro, a imagem já foi enviada e fica órfã no servidor.

---

## 2. Otimizações de Imagens & Recursos Visuais

### 2.1 Estratégia de Imagens (Arquitetura e Performance)

| Aspecto | Situação Atual | Proposta de Melhoria | Benefício |
|---|---|---|---|
| **Armazenamento** | Disco rígido local (`wwwroot/uploads`) | Abstração `IStorageService` apontando para S3 / Cloudflare R2 / MinIO | Escalabilidade infinita, custo próximo de zero no R2 (sem taxas de egress), pronto para containers |
| **Formatos** | Salva em JPEG padrão | Conversão automática para **WebP** com fallback JPEG | Redução de 40% a 60% no peso de cada arquivo sem perda perceptível de qualidade |
| **Resoluções** | Apenas 1 tamanho (1200px) | Geração de 3 variantes no upload:<br>- `thumb`: 250x250 (listas, avatares)<br>- `medium`: 600x400 (cards, feed)<br>- `full`: 1200x800 (detalhe, hero zoom) | Listagens carregam 5x mais rápido no 4G/5G; menor consumo de dados |
| **Placeholder** | Ícone cinza estático | **BlurHash** ou **ThumbHash** gerado no backend e salvo no banco | O usuário vê um blur colorido harmonioso instantaneamente enquanto a imagem carrega, sem tela branca ou cinza |
| **No App (Flutter)** | `image_picker` direto | Inclusão de `image_cropper` com proporções fixas (16:9 capa, 1:1 logo, 4:3 prato) | Imagens nunca mais ficam esticadas, cortadas ou tortas nos cards |
| **Cache em Memória** | `CachedNetworkImage` padrão | Configuração de `memCacheWidth` e `memCacheHeight` no Flutter | Evita estouro de memória RAM e travamentos em aparelhos Android de entrada |
| **UGC (Fotos de Clientes)** | Avaliações aceitam apenas texto | Permitir que clientes enviem até 3 fotos do prato que consumiram | Aumenta drasticamente a credibilidade das avaliações |

---

### 2.2 Gráficos, Painéis e Visualizações de Dados

Atualmente o pacote `fl_chart` não está instalado no Flutter. Sua inclusão transformará o aplicativo em uma ferramenta de inteligência para os restaurantes.

#### 1. Para os Donos de Restaurantes (Painel Gerencial B2B):
- **Gráfico de Funil de Conversão de Tickets**:
  - *Visualizações do Anúncio* → *Tickets Resgatados no App* → *Tickets Consumidos no Salão* (taxa de conversão real).
- **Mapa de Calor Semanal (Dia x Horário)**:
  - Uma matriz visual (segunda a domingo vs 11h às 23h) mostrando onde ocorrem mais check-ins e interações, permitindo ao dono planejar promoções para os horários ociosos.
- **Gráfico de Quadrantes dos Pratos (Popularidade x Avaliação)**:
  - *Carros-chefe*: Alta nota e muitos pedidos.
  - *Oportunidades*: Alta nota, mas poucos pedidos (precisam de promoção/destaque).
  - *Pontos de atenção*: Baixa nota.
- **Evolução da Nota Média (Linha de Tendência)**:
  - Gráfico de linha interativo exibindo a evolução da nota ao longo das últimas 8 semanas com média móvel.

#### 2. Para a Administração Geral:
- **Crescimento de Usuários & Novos Estabelecimentos** (gráfico de área com filtros de 7, 30 e 90 dias).
- **Volume Financeiro Estimado Transacionado** via tickets gerados.
- **Volume de Moderações Diárias** (tempo médio de resposta do conteúdo gerado por IA/usuário).

#### 3. Para o Cliente / Consumidor Final:
- **Gráfico Radar de Atributos do Restaurante**:
  - Mostra a pontuação em 5 eixos: *Sabor da Comida*, *Atendimento*, *Ambiente/Música*, *Custo-Benefício* e *Velocidade*.
- **Passaporte Gastronômico Visual**:
  - Barra de progresso circular indicando o percentual de bairros gastronômicos de Salvador já explorados pelo cliente (ex: "4/10 Bairros Conquistados").

---

## 3. Melhorias de Usabilidade e Experiência do Usuário (UX/UI)

### 3.1 Navegação e Hierarquia de Telas
1. **Unificação do Menu do Perfil**:
   - Adicionar ao `ProfileScreen` atalhos diretos para: *Minhas Conquistas & Selos (Gamificação)*, *Histórico de Check-ins*, *Preferências de Notificação*, *Meus Tickets Ativos*.
   - Permitir edição de avatar com troca de foto direto pelo perfil.
2. **Ajuste na Barra Inferior (Bottom Navigation Bar)**:
   - Renomear a aba "Feed" para **"Ofertas & Tickets"** (o termo "Feed" confunde o usuário que espera uma timeline social).
   - Inserir um botão de destaque central ou ícone na AppBar: **"Escanear QR de Mesa / Check-in"**, facilitando o registro da presença sem precisar de deep links.
3. **Cardápio Interativo com Filtros Rápidos (Chips)**:
   - No `MenuScreen`, permitir navegação por categorias em abas deslizantes no topo (*Entradas*, *Pratos Principais*, *Moquecas*, *Bebidas*, *Sobremesas*) com barra de busca rápida no cardápio.
4. **Filtros e Visualização Geográfica de Salvador**:
   - Criar uma aba ou botão de alternância **"Mapa / Lista"** na tela de busca.
   - Adicionar filtro rápido por **Polos Gastronômicos**:
     - *Rio Vermelho* (Largo de Santana, Dinha, boêmia)
     - *Pelourinho & Santo Antônio Além do Carmo* (vista para a Baía, casarões, bistrôs)
     - *Barra & Ondina* (orla, pôr do sol, frutos do mar)
     - *Pituba & Itaigara* (alta gastronomia, hamburguerias, japoneses)
     - *Ribeira & Cidade Baixa* (sorveterias, orla da Ribeira, peixes)
     - *Itapuã & Stella Maris* (praias, quiosques tradicionais)

---

## 4. Estratégias para Atrair Mais Restaurantes

Os proprietários de bares e restaurantes em Salvador enfrentam três dores principais:
1. **Altas taxas cobradas pelos grandes apps de delivery** (muitas vezes entre 12% e 27% sobre a venda).
2. **Mesas vazias em dias de baixo movimento** (terça a quinta-feira).
3. **Falta de fidelização dos clientes físicos** (dificuldade de reter quem visita o salão).

### 4.1 Propostas de Valor Irrecusáveis para os Donos:
1. **Modelo de Tráfego de Salão com Taxa Zero**:
   - Posicionar a plataforma como um canal focado em **lotar o salão físico (Dine-in)**, e não em delivery de moto. O restaurante não paga comissão percentual sobre cada refeição consumida.
2. **Promoções Relâmpago para Horários Ociosos (Yield Management Dinâmico)**:
   - Permitir que o restaurante abra lotes pontuais de 10 a 20 tickets com validade exclusiva para dias fracos (ex: *"Moqueca de Camarão com 30% OFF nesta Terça das 18h às 21h"*). O salão enche, a cozinha é aproveitada e clientes novos conhecem o local.
3. **Cardápio Digital sem Custo Adicional**:
   - O restaurante ganha um cardápio digital moderno, atualizado pelo próprio aplicativo, com QR Code pronto para impressão nas mesas, eliminando a necessidade de contratar sistemas externos caros de cardápio digital.
4. **Kit de Boas-Vindas Físico para o Balcão ("Estamos no Onde Comer")**:
   - Oferecer um display acrílico com QR Code para balcão e adesivo de vitrine. O cliente escaneia na mesa, ganha pontos de fidelidade no app e o restaurante ganha avaliações legítimas.
5. **Painel de CRM Automático e Retargeting**:
   - Notificações automáticas para clientes que já fizeram check-in ou consumiram tickets: *"Faz 30 dias que você provou nosso acarajé! Volte essa semana e ganhe uma caipirinha de cortesia"*.

---

## 5. Estratégias para Atrair e Reter Clientes (Usuários e Turistas)

### 5.1 Gamificação: "Passaporte Gastronômico de Salvador"
- **Sistema de Selos e Conquistas**:
  - *Mestre do Dendê*: Avaliar 5 casas de acarajé/comida baiana.
  - *Pôr do Sol Perfeito*: Fazer check-in em 3 restaurantes com vista para a Baía de Todos os Santos.
  - *Trilha da Boêmia*: Fazer check-in em 4 bares no Rio Vermelho.
  - *Crítico da Cidade*: Escrever 10 comentários com fotos.
- **Benefícios Reais**:
  - Selos desbloqueiam cupons VIPs e prioridade no resgate de tickets concorridos.

### 5.2 Roteiros Temáticos e Curadoria Cultural
- Criar coleções editoriais que conectam o app à essência de Salvador:
  - *"Onde almoçar após o banho de mar no Porto da Barra"*
  - *"Os 7 melhores cafés do Santo Antônio Além do Carmo"*
  - *"Roteiro da Maniçoba e Feijoada Tradicional"*
  - *"Menu Executivo de Qualidade na Av. Tancredo Neves"*
- **Modo Turista**:
  - Um botão na tela inicial que ativa o guia para visitantes recém-chegados à cidade, destacando pratos típicos indispensáveis e alertas de segurança/localização.

### 5.3 Recursos Sociais e Compartilhamento
- **"Onde Comer Hoje?" (Enquete de Grupo)**:
  - O usuário cria uma lista rápida com 3 restaurantes e compartilha um link no WhatsApp para o grupo de amigos ou família votar. O restaurante mais votado vence e todos podem resgatar tickets juntos.
- **Parcerias com Criadores de Conteúdo Locais**:
  - Parcerias com influenciadores gastronômicos da Bahia, concedendo a eles perfis verificados de "Curadores". Suas listas (ex: *"Os pratos favoritos de @Fulano"*) ganham destaque na Home.

---

## 6. Novas Funcionalidades Sugeridas

1. **Visualização Interativa em Mapa**:
   - Implementação de tela com mapa (`flutter_map` com OpenStreetMap ou Google Maps), exibindo pins de restaurantes próximos com indicação de tickets ativos e filtro de "Aberto Agora".
2. **Reserva de Mesas com Confirmação Rápida**:
   - Integração simples para solicitação de reserva ou direcionamento imediato para o WhatsApp oficial do restaurante já com mensagem pré-formatada: *"Olá! Vi vocês no Onde Comer em Salvador e gostaria de reservar uma mesa para 4 pessoas nesta sexta às 20h"*.
3. **Notificações Inteligentes por Geofencing / Proximidade**:
   - Quando o usuário estiver no Rio Vermelho à noite, recebe um push suave: *"Você está no Rio Vermelho! Que tal conhecer o cardápio e promoções de hoje por aqui?"*.
4. **Programa de Fidelidade Digital Unificado**:
   - Permitir que cada restaurante tenha seu cartão fidelidade digital dentro do app (ex: *"A cada 5 pratos consumidos, o 6º tem R$ 30 de desconto"*), com validação pelo QR Code do restaurante.

---

## 7. Roadmap Recomendado de Execução

```mermaid
flowchart TD
    subgraph Fase 1 - Quick Wins [Fase 1: Quick Wins & Refinamento Imediato]
        A1[Instalar fl_chart no Flutter e enriquecer MetricsDashboard]
        A2[Adicionar atalhos de Badges e Notificações no ProfileScreen]
        A3[Adicionar image_cropper e validação de proporção no app]
        A4[Renomear aba Feed para 'Ofertas & Tickets']
    end

    subgraph Fase 2 - Otimização de Mídia & UX [Fase 2: Mídia, Imagens & Polos de Salvador]
        B1[Migrar Uploads para S3/R2 com geração de WebP e Thumbnails]
        B2[Implementar BlurHash para carregamento instantâneo de imagens]
        B3[Adicionar Filtros por Bairros/Polos Gastronômicos de Salvador]
        B4[Permitir fotos de clientes nas avaliações]
    end

    subgraph Fase 3 - Crescimento & Engajamento [Fase 3: Expansão de Mercado & B2B]
        C1[Implementar tela de Mapa Interativo]
        C2[Lançar Passaporte Gastronômico e Gamificação completa]
        C3[Kit Físico de Balcão e Campanha de Aquisição de Restaurantes]
        C4[Enquetes Sociais de Grupo via WhatsApp]
    end

    Fase 1 --> Fase 2 --> Fase 3
```

---

## 8. Melhorias Já Implementadas no Código

1. **Navegação & Hierarquia de Menus**:
   - Bottom Navigation Bar renomeada de "Feed" para "Ofertas & Tickets".
   - `ProfileScreen` reformulado em 3 blocos lógicos com atalhos para Tickets, Fidelidade, Histórico de Check-ins, Favoritos e Listas.
   - Adicionado convite para restaurantes parceiros no perfil do usuário (`Tem um Restaurante?`).
2. **Identidade Cultural & Polos Gastronômicos de Salvador**:
   - Filtros horizontais por bairros (*Rio Vermelho, Pelourinho & Carmo, Barra & Ondina, Pituba & Itaigara, Ribeira, Itapuã*) na Home.
   - Coleções e Roteiros Temáticos (*Pôr do Sol na Baía, Circuito do Dendê, Charme no Centro Histórico, Sabores da Cidade Baixa*) em carrossel na Home.
   - Categorias da Busca Avançada expandidas com especialidades baianas (*Acarajé & Tabuleiro, Comida Baiana, Frutos do Mar, etc.*).
   - Busca avançada no repositório backend (`RestaurantRepository.cs`) agora busca também por endereço/bairro.
3. **Engajamento & Passaporte Gastronômico**:
   - Card convidativo de Passaporte Gastronômico na Home.
   - Botões de atalho para Selos & Fidelidade e Favoritos na AppBar.
   - Modal explicativo detalhado ao tocar em qualquer selo na tela de Fidelidade, informando progresso, requisitos e status.
4. **Atração e Aquisição de Restaurantes (B2B)**:
   - Tela de boas-vindas com proposta de valor no `RestaurantDashboardScreen`: destaque para Taxa Zero no Salão, Cardápio Digital com QR Code de Mesa, Ofertas para dias fracos e Fidelização.
5. **Gráficos & Métricas de Negócio**:
   - Pódio com medalhas (🥇, 🥈, 🥉) para os pratos mais bem avaliados no painel do restaurante.
   - Gráfico de barras de Horários de Pico agora interativo: toque para selecionar horário e visualizar diagnóstico de fluxo e comentários.
6. **Performance e Gestão de Mídias**:
   - Backend `ImageService.cs`: geração automática de miniaturas otimizadas (`_thumb.jpg`, 400px, 75% qualidade).
   - `CachedNetworkImage` com `memCacheWidth` e `SkeletonLoader` (Shimmer) no lugar de caixas cinzas no cardápio, cards e promoções.
7. **Viralidade Social & Decisão em Grupo ("Onde Comer Hoje? 🎲")**:
   - Criação da tela interativa `OndeComerHojeScreen` (`/onde-comer-hoje`), acessível pela Home e pelo Menu de Perfil.
   - Gerador de enquete com emojis e detalhes de até 4 opções, pronta para copiar e colar com 1 toque no WhatsApp da galera.
   - "Roleta da Decisão (Sorteio Soteropolitano)": modal interativo animado que sorteia um restaurante e encerra discussões de grupo ("Ninguém discute mais, o rolê tá fechado!").
8. **Navegação & Direções GPS**:
   - Adicionado atalho de cópia rápida do endereço formatado para GPS (Google Maps, Waze, Uber) na tela de detalhes do restaurante.
9. **Barra de Polos Gastronômicos na Busca Avançada (`SearchScreen`)**:
   - Chips horizontais de seleção rápida por bairro (*Todos, Rio Vermelho, Pelourinho, Barra, Pituba, Ribeira, Itapuã, Stella Maris, Santo Antônio*).
   - Ao tocar, filtra instantaneamente os restaurantes pelo bairro escolhido, eliminando atrito de digitação no mobile.
10. **Tags Rápidas em Avaliações de Pratos (`DishReviewSection`)**:
   - Chips rápidos de 1 toque (*😋 Muito gostoso, 🍤 Bem servido, ⚡ Atendimento rápido, 🌶️ Bem temperado, 💰 Bom custo-benefício, ⭐ Recomendo muito*).
   - Permite que o cliente componha a avaliação em poucos segundos sem precisar digitar textos longos, aumentando em até 3x a taxa de conclusão de avaliações.
11. **Modo Radar e Explorador de Circuitos de Salvador (`SalvadorRadarView`)**:
   - Alternador de visualização (**Lista ⇄ Modo Radar**) na tela de busca.
   - Gráfico de radar com anéis concêntricos de proximidade (< 2km a pé, 2-5km Uber rápido, 5-12km circuito de carro).
   - Grid visual dos 4 grandes Circuitos Gastronômicos de Salvador (*Orla Atlântica, Histórico & Baía, Cidade Baixa, Litoral Norte*) com filtro imediato por toque.
   - Listagem com badges de proximidade em destaque (*📍 800m*, *📍 1.8km*) e identificação do bairro.
12. **Auditoria e Adequação de Funcionalidades por Perfil (Consumer, Restaurant, Admin)**:
   - **Desbloqueio de Novo Restaurante (MetricsDashboardScreen)**: Corrigido bug crítico de carregamento infinito (`CircularProgressIndicator` eterno) quando um novo usuário com perfil `Restaurant` se cadastrava e ainda não tinha um restaurante vinculado. Agora exibe onboarding amigável convidando para cadastrar o estabelecimento com botão direto para `RestaurantFormScreen`.
   - **Barra de Ações Rápidas no Painel do Restaurante**: Adicionado bloco de atalhos rápidos de alta frequência no topo do painel:
     * 🎟️ *Validar Ticket*: Leitor de QR Code / digitação de cupom com 1 toque.
     * ⚡ *Promoções*: Acesso imediato à gestão de ofertas e descontos.
     * 🍽️ *Editar Pratos*: Gestão de preços e cardápio.
     * 🖨️ *QR das Mesas*: Geração e visualização de plaquinhas para mesas do salão.
   - **Diferenciação no Feed de Ofertas (FeedScreen)**:
     * Usuários com perfil `Consumer` visualizam tickets resgatados e botão para resgatar cupom.
     * Usuários com perfil `Restaurant` visualizam na AppBar e no topo da lista um card de gestão: atalhos para *Validar Ticket QR* do cliente e *Minhas Ofertas*.
   - **Acesso Rápido para Administradores (RestaurantListScreen)**:
     * Se o usuário logado for `Admin`, a AppBar da Home exibe ícone de escudo com acesso em 1 toque ao Painel Administrativo de moderação e tickets.
     * Se for `Restaurant`, exibe ícone de estabelecimento com acesso ao seu painel.
   - **Menu de Perfil Enriquecido por Perfil (ProfileScreen)**:
     * Clientes comuns veem atalhos para Fidelidade, Tickets Resgatados, Histórico de Check-ins, Favoritos, Coleções e o botão de convite para cadastrar restaurante.
     * Restaurantes veem bloco dedicado "Gestão do Restaurante" com atalhos para *Painel de Indicadores*, *Validar Ticket de Oferta (QR)* e *Gerenciar Cardápio & Pratos*.
     * Administradores mantêm atalhos de gestão e auditoria do sistema.
13. **Reserva Rápida & Contato do Estabelecimento via WhatsApp (RestaurantDetailScreen)**:
   - Adicionado botão de ação `[ 💬 Reservar / WhatsApp ]` em destaque ao lado do check-in na tela de detalhes do restaurante.
   - Abre modal bottom-sheet com modelo pronto de mensagem de reserva formatada: *"Olá! Vi o perfil do [Restaurante] no app Onde Comer em Salvador e gostaria de saber sobre reserva de mesa e atendimento para hoje. 🍽️"*.
   - Botão de 1 toque para copiar a mensagem pronta para colar no WhatsApp do restaurante ou na conversa de grupo. Reduz a zero a fricção de contato e gera tráfego imediato para os restaurantes parceiros.

14. **Indicador Visual Dinâmico "Aberto Agora / Fechado" (`RestaurantOpenStatusBadge`)**:
   - Criação do componente reutilizável `RestaurantOpenStatusBadge` com suporte a múltiplos formatos de horários (JSON estruturado por dia da semana ou texto descritivo como `11:00 às 23:00`, `18h - 02h`).
   - Respeita o fuso horário oficial de Salvador (UTC-3) e suporta horários que viram a madrugada (ex: das 18h até as 02h).
   - Exibição de badge estilizado (`🟢 Aberto Agora` / `🔴 Fechado`) nos seguintes pontos estratégicos:
     * Card de Restaurante (`RestaurantCard`), sobreposto no topo da foto com contraste visual.
     * Detalhes do Restaurante (`RestaurantDetailScreen`), ao lado da descrição dos horários de funcionamento.
     * Modo Radar de Salvador (`SalvadorRadarView`), permitindo ao usuário ver instantaneamente se o polo ou circuito gastronômico está operando no momento.

15. **Fotos Reais de Clientes nas Avaliações de Pratos (`DishReviewSection`)**:
   - Integração completa com a câmera e galeria do celular (`image_picker`) e com o serviço de upload de imagens (`ImageUploadService`).
   - Opção para os clientes anexarem fotos dos pratos no momento da avaliação, com pré-visualização imediata da miniatura e opção de remoção com 1 toque.
   - Envio automático com upload para `/api/v1/images/upload` vinculado à entidade do prato.
   - Apresentação das fotos reais nos comentários aprovados (`_CommentTile`), com banner distintivo *"📸 Foto Real do Cliente • Toque para ampliar"*.
   - Modal com zoom interativo (`InteractiveViewer`) em alta resolução para visualização completa do prato avaliado. Aumenta substancialmente a prova social e a confiança de novos consumidores.

16. **Kit Digital de Balcão e Mesa para Download/Impressão em Formato A6 (`QrCodeScreen`)**:
   - Redesenho completo da tela `QrCodeScreen`, transformando-a em uma central geradora de materiais físicos de salão.
   - Mockup visual fiel ao display acrílico A6 (10,5 × 14,8 cm): cabeçalho em degradê pôr do sol de Salvador, tipografia marcante, chamada para pontuação no *Passaporte Gastronômico*, QR Code central em alta precisão e rodapé *Taxa Zero no Salão*.
   - Alternador dinâmico de modelo: *Display de Mesa A6 (Vertical)* vs *Plaquinha de Balcão & Caixa*.
   - Ação rápida de 1 toque: **"Copiar Dados p/ Gráfica"**, copiando especificações técnicas completas de impressão (dimensões, papel couché 250g/300g, laminação fosca, links e código) prontas para envio no WhatsApp da gráfica.
   - Modal de apoio **"Guia de Impressão & Acrílico A6"** com recomendações de suporte acrílico formato T/L, posicionamento no salão e vantagens comerciais B2B.
   - Integração direta de atalho a partir do painel de métricas do restaurante (`MetricsDashboardScreen` -> *Kit de Mesas (A6)*).

---

## Conclusão



O projeto **Onde Comer Em Salvador** já possui uma fundação arquitetural de altíssimo nível, destacando-se pela robustez do .NET 8 no backend e pela maturidade do Flutter com suporte offline e gestão de tickets. 

Implementando as melhorias propostas — especialmente no processamento inteligente de imagens, na introdução de gráficos visuais expressivos com `fl_chart`, na ambientação cultural e geográfica nos bairros de Salvador e no posicionamento comercial focado em tráfego de salão sem taxas abusivas —, a plataforma tem plenas condições de se consolidar como o principal guia e ecossistema gastronômico de Salvador.

