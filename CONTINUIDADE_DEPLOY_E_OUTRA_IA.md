# Handoff do projeto Onde Comer em Salvador

Atualizado em 2026-11-04. Documento para continuar o trabalho com outro assistente ou outra conta. Leia antes de executar novos comandos.

## Objetivo atual

Publicar a API ASP.NET Core e o PostgreSQL, depois publicar o Flutter Web. O usuário é iniciante em deploy e pediu instruções passo a passo, sem pressupor experiência com Cloudflare, Neon, Render, Docker ou GitHub.

O usuário pretende mudar a conta do GitHub e continuar com outra IA. Não presumir que a nova IA terá a mesma autenticação de GitHub ou Neon. Nunca solicitar senha, token, código de verificação ou connection string no chat.

## Projeto e tecnologias

- Workspace: `C:\OndeComerEmSalvador`
- Backend: .NET 8, ASP.NET Core, EF Core, PostgreSQL/Npgsql.
- App: Flutter/Dart, diretório `mobile/`.
- Repositório Git: `https://github.com/TarcisioMutuipe/OndeComer.git`
- Branch local: `main`; último commit enviado: `086295c Implementa cardapio publico e aprovacao de promocoes`.
- O remoto `origin` está configurado para o repositório acima. A conta que atualmente conversa com o assistente não é necessariamente a conta GitHub usada para esse remoto.

## Funcionalidades já implementadas

- Cardápio público mobile-first, QR com logo, seções/subcategorias e links.
- Feed misto de promoções e pratos.
- Pratos com `ShowInFeed`, `IsActive` e `DeactivatedAt`; exclusão automática de pratos desativados após sete dias.
- Exclusão de relações promocionais e imagens associadas ao excluir pratos.
- Dashboard administrativo com restaurantes mais salvos e perfil Admin direcionado à gestão.
- Cobrança Pix opcional para tickets promocionais, aprovação manual, notificações e regra de antecedência de 48 horas.
- Migrations mais recentes: `20261030234025_AddDishFeedAndRetentionFields` e `20261031014242_PromotionPaymentApproval`.

Segundo o histórico anterior, as migrations locais foram aplicadas e os builds/testes das features passaram. O commit indicado acima foi enviado para `origin/main`.

## Estado do deploy

### Neon

- O usuário criou/login na conta Cloudflare e na conta Neon.
- Organização Neon: `Tarcisio`, ID `org-long-leaf-28353026`.
- Projeto PostgreSQL criado pelo Neon CLI na região São Paulo, plano Free.
- Nome do projeto: `onde-comer-salvador`.
- ID do projeto conforme CLI: `shy-mud-88073653`.
- Branch conforme CLI: `main` (o painel pode traduzir o rótulo para “principal”).
- Projeto no painel: https://console.neon.tech/app/projects/shy-mud-88073653/
- Neon CLI foi instalado e autenticado com sucesso; `neon init` criou `.neon`, `neon.ts`, `package.json`, `package-lock.json` e `.env.local`, instalou o plugin Neon para VS Code e dependências do Neon.
- `.env.local` contém dados de conexão e deve permanecer secreto. Foi verificado que `.env.local` é ignorado pelo Git. Não abrir, imprimir, copiar para o repo, commitar ou pedir que o usuário envie esse arquivo.
- O banco aparece sem tabelas porque a API ainda não foi conectada/iniciada no Neon. `Program.cs` executa `Database.MigrateAsync()` no startup; a API criará o schema ao conectar pela primeira vez.
- Não executar o SQL manualmente se a API for iniciar normalmente, para evitar passos duplicados. Um script idempotente foi gerado como alternativa manual em `C:\OndeComer\BancodeDados\OndeComer_PostgreSQL.sql`.

### API e script SQL em pastas locais

- Publicação .NET Release em `C:\OndeComer\API`.
- Foi removido do pacote publicado qualquer `appsettings*.json` para não carregar configurações locais. `C:\OndeComer\API\LEIA-ME.txt` documenta inicialização/variáveis necessárias.
- Script PostgreSQL idempotente em `C:\OndeComer\BancodeDados\OndeComer_PostgreSQL.sql`; foi validada a presença das migrations mais recentes.
- Essas duas pastas estão fora do repositório e não são o mecanismo de deploy do Render. Para deploy, Render usa o código do GitHub e o `Dockerfile` da raiz.

### Docker e Render (CONCLUÍDO)

- Web Service criado com sucesso no Render.
- Deploy concluído com sucesso: `Deploy succeeded | Live`.
- URL pública da API: `https://ondecomer-wm3r.onrender.com`
- Swagger ativo em: `https://ondecomer-wm3r.onrender.com/swagger`
- Health check testado em: `https://ondecomer-wm3r.onrender.com/health`
- O banco Neon conectou com sucesso e as migrations EF Core foram aplicadas automaticamente na inicialização da API.

## Variáveis necessárias no Render

Definir na seção **Environment Variables** do Web Service, não no código nem em `.env` com commit:

- `UsePostgres=true`
- `ConnectionStrings__DefaultConnection=<connection string Npgsql para o Neon>`
- `Jwt__Secret=<chave aleatória forte de pelo menos 32 caracteres>`
- `Google__ClientId=<Client ID OAuth usado pelo app>`
- `ASPNETCORE_ENVIRONMENT=Production`

A string que o Neon CLI colocou em `.env.local` é URL Postgres (`DATABASE_URL`). A configuração atual da API lê `ConnectionStrings:DefaultConnection` via Npgsql. Na integração com Render, usar a connection string no formato Npgsql `Host=...;Database=...;Username=...;Password=...;SSL Mode=Require;Channel Binding=Require`, ou confirmar no exemplo .NET do painel do Neon. Nunca revelar a string ao assistente.

`AuthService` exige `Google:ClientId`; configurar `Google__ClientId` para o login Google funcionar. `Program.cs` exige `Jwt:Secret` e o backend exige `ConnectionStrings:DefaultConnection`.

Quando o Render concluir o deploy, testar `https://<servico>.onrender.com/health`, que deve responder `{"status":"ok"}`. Swagger está habilitado em `/swagger`.

## Git e proteção de segredos

- `.gitignore` atual (criado no setup Neon e confirmado no workspace) contém `.env`, `.env.*`, exceção `.env.example`, `.neon` e `node_modules/`.
- `.dockerignore` protege appsettings e artefatos na construção Docker.
- O `.gitignore` atual não ignora `bin/`, `obj/` ou `logs/`; eles aparecem no `git status`. Não adicioná-los ao commit. Stage somente arquivos específicos do deploy.
- `git status` mais recente mostrou `Dockerfile`, `.dockerignore`, `.gitignore`, `neon.ts`, `package.json`, `package-lock.json` não rastreados, além de muitos arquivos de build/log. `.env.local` não apareceu porque está ignorado.
- Para o deploy da API, os três arquivos mínimos são `Dockerfile`, `.dockerignore` e `.gitignore`. `neon.ts`/package files foram gerados pelo Neon CLI e podem ser necessários para a integração de dev Neon, mas não são necessários para construir a API no Render; revisar antes de decidir incluí-los.
- O arquivo rastreado `backend/OndeComer.API/appsettings.json` contém uma senha de banco local e uma chave JWT de exemplo. Não imprimir seus valores nem copiá-los para deploy. Se a senha for real ou reutilizada, recomendar rotação; não alterar config do usuário sem necessidade.

## Próxima sequência recomendada

1. No VS Code, revisar Source Control e preparar commit/push apenas de `Dockerfile`, `.dockerignore` e `.gitignore`. Não usar Stage All. Se a conta GitHub mudar, primeiro autenticar a conta correta no VS Code e confirmar que ela tem acesso ao repo ou transferir o repositório.
2. No Render, criar **Web Service**, autorizar GitHub, selecionar `OndeComer`, branch `main`, runtime Docker, Root Directory vazio e Dockerfile raiz.
3. Configurar as cinco variáveis de ambiente indicadas acima. Não pedir ao usuário para colar segredos no chat; orientá-lo a inseri-los diretamente no painel Render.
4. Acompanhar build/deploy e logs; testar `/health`. Ao iniciar, a API aplica as migrations no Neon.
5. Só depois compilar Flutter Web com o URL público da API:

```powershell
cd C:\OndeComerEmSalvador\mobile
flutter build web --release --dart-define=API_BASE_URL=https://<servico>.onrender.com
```

O output é `mobile\build\web`. Publicar esse diretório no Cloudflare Pages (Workers & Pages). Não adicionar domínio customizado para o primeiro teste. Se usar Direct Upload, deploys futuros são manuais; para automação, configurar Git integration com build que instale Flutter.
6. Depois do teste público, decidir armazenamento persistente para imagens (R2 exige adaptação do `ImageService`).

## Avisos de build conhecidos

- `dotnet publish backend/OndeComer.API/OndeComer.API.csproj --configuration Release --output C:\OndeComer\API` concluiu com sucesso.
- Aviso NuGet: `SixLabors.ImageSharp` 3.1.7 tem advisory de severidade moderada `GHSA-rxmq-m78w-7wmc`.
- Aviso C#: possível argumento nulo em `AuthService.cs` (linha indicada pelo build: 33).
- O comando de migrations inicialmente falhou porque uma API local estava segurando os assemblies Debug; foi executado com `--configuration Release` e o SQL idempotente foi gerado corretamente.
- `neon init` apresentou aviso de depreciação Node `DEP0190`, mas concluiu com sucesso.

## iOS

Distribuição iOS/TestFlight não faz parte do deploy atual. Requer Mac com Xcode e assinatura do Apple Developer Program; não foi informado acesso a Mac.
