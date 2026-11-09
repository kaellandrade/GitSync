# Roadmap de Épicos & User Stories — KGit Native (Android / Kotlin) [v2]

**Projeto:** KGit (Aplicativo Android Nativo evoluído a partir do fork do GitSync)  
**Autores:** Time BMAD (Mary, John, Winston, Amelia, Sally), Viktor (Staff Android / NDK & Rust Reviewer) & Kaell  
**Data:** 2026-11-09  
**Versão:** 2.0 (Pós-Revisão de Especialista)  
**Plataforma Alvo:** Android Nativo (`arm64-v8a` no APK, `linux-x86_64` para testes de host na CI, Kotlin 2.x, Jetpack Compose, Material 3, Rust Core `libgit2`)  
**Foco Principal (Job-to-be-Done):** Sincronização invisível, rápida e confiável de cofres do Obsidian no Android com zero desperdício de bateria/RAM, observabilidade clara e cobertura sólida de testes automatizados.

---

## 1. Visão Arquitetural, Diagnóstico Real & Estratégia de Convivência

### 1.1 Diagnóstico Preciso do Legado (Flutter)
1. **Desperdício de IPC e Bateria em Background:** Em [`gitsync_service.dart:175`](../../lib/gitsync_service.dart), o serviço roda com `autoStart: true, isForegroundMode: false`, mantendo a engine Dart viva em background. Porém, [`GitSyncAccessibilityService.kt:20-33`](../../android/app/src/main/kotlin/com/viscouspot/gitsync/GitSyncAccessibilityService.kt) dispara um `startService(Intent)` a **cada mudança de janela do sistema operacional** (`TYPE_WINDOW_STATE_CHANGED`), gerando tráfego constante de IPC e processamento no Dart ([`main.dart:681-684`](../../lib/main.dart)) apenas para checar se o pacote atual está na lista monitorada — ou forçando cold-start da engine Dart sempre que o Android mata o processo em segundo plano.
2. **Ausência de Testes Unitários no App:** O arquivo [`test/widget_test.dart`](../../test/widget_test.dart) está inteiramente comentado; não há cobertura automatizada para fluxos de sincronização, autenticação ou resolução de conflitos.
3. **Superfície de Código Inflada:** 54 blocos `Platform.isIOS` em `lib/`, diretórios `ios/` e `macos/`, suporte a 6 provedores distintos e dezenas de telas de gerenciamento de repositório (Issues, PRs, Actions, Releases, Editor embutido, IA) que fogem do caso de uso de sincronização do Obsidian.

### 1.2 Estratégia de Migração Lado a Lado (Anti-"Big Rewrite")
- **Diretório/Repositório Isolado & Coexistência:** O app nativo **não** apagará a pasta `lib/` do app Flutter no dia 1. Ele será desenvolvido com `applicationId` próprio (`com.kaell.kgit`), permitindo instalação **lado a lado** no Galaxy A55 com o app Flutter atual (`com.viscouspot.gitsync.kaell`).
- **Critério Objetivo de Cutover (Desativação do Legado):** O app Flutter só será aposentado quando o KGit Native cumprir 14 dias consecutivos sincronizando o cofre `palacio-mental` em uso real sem nenhuma perda de dados, corrupção de `.git/index.lock` ou falha silenciosa.

### 1.3 Escopo de Provedores & Não-Objetivos Explícitos (Out of Scope)
- **Provedores Suportados:** Exclusivamente **GitHub (OAuth + PAT)**, **HTTPS** e **SSH**.
- **Provedores Removidos:** GitLab, Gitea e Codeberg ficam oficialmente fora do KGit Native.
- **Não-Objetivos (Funcionalidades Excluídas):**
  - ❌ Gerenciamento de Issues, Pull Requests, GitHub Actions, Releases e Tags (`issues_page.dart`, `pull_requests_page.dart`, `actions_page.dart`, `releases_page.dart`).
  - ❌ Explorador de arquivos interno, editor de código embutido e visualizador de imagens (`file_explorer.dart`, `code_editor.dart`, `image_viewer.dart`) — o Obsidian já cumpre esse papel.
  - ❌ Ferramentas de IA / AI Wand (`ai_features_page.dart`, `ai_wand_field.dart`).
  - ❌ Qualquer código, flag ou configuração voltada a iOS/macOS.

### 1.4 Arquitetura Alvo (Processo Único + Dupla Camada de Lock)
```
┌──────────────────────────────────────────────────────────────┐
│                 :app / :feature:dashboard                    │
│          Jetpack Compose (M3) + ViewModels (MVI)             │
└──────────────────────────────┬───────────────────────────────┘
                               │
┌──────────────────────────────▼───────────────────────────────┐
│                         :core:sync                           │
│  SyncOrchestrator (Mutex + Rust flock) + Expedited WorkMgr   │
└──────────────┬───────────────────────────────┬───────────────┘
               │                               │
┌──────────────▼───────────────┐ ┌─────────────▼───────────────┐
│          :core:git           │ │        :core:storage        │
│  Kotlin UniFFI <-> Rust git2 │ │ DataStore + Tink + Room Log │
└──────────────────────────────┘ └─────────────────────────────┘
```

---

## 2. Estrutura de Épicos e User Stories (16 Stories)

### Épico 0: Baseline de Performance & Spike de Interop Rust
**Objetivo:** Medir os números reais do app atual no Galaxy A55 e validar a ponte assíncrona Rust <-> Kotlin antes de construir os módulos finais.

#### Story 0.1 — Medição de Baseline no Dispositivo Real (Galaxy A55)
- **Descrição:** Coletar métricas reais do APK Flutter atual (`com.viscouspot.gitsync.kaell`) para comparação objetiva com o app nativo.
- **Critérios de Aceite (AC):**
  - AC1: Registrar tamanho exato do APK `arm64-v8a`, consumo de RAM em repouso e durante sync (`adb shell dumpsys meminfo`), e tempo médio de pull/push no cofre `palacio-mental`.
  - AC2: Registrar contagem de chamadas IPC disparadas pelo `GitSyncAccessibilityService` durante 10 minutos de uso normal do celular.

#### Story 0.2 — Spike Timeboxed: Rust `git_manager.rs` + UniFFI / JNI com Callbacks
- **Descrição:** Validar em um protótipo mínimo a exposição de uma função assíncrona com callback de progresso (`clone_repository` e `pull_changes`) do crate Rust para uma `suspend fun` em Kotlin sem `flutter_rust_bridge`.
- **Critérios de Aceite (AC):**
  - AC1: Decisão documentada (ADR curto) entre **UniFFI** vs **JNI direto (`jni-rs`)** considerando suporte a callbacks de progresso e cancelamento de corrotinas.
  - AC2: Compilação cruzada funcionando para `aarch64-linux-android` (APK) e `x86_64-unknown-linux-gnu` (testes locais/CI na JVM).

---

### Épico 1: Fundação Nativa & Motor Git (`:core:git`)
**Objetivo:** Estruturar o projeto Kotlin multimódulo (`com.kaell.kgit`) lado a lado com o app atual e expor o motor `libgit2` com bateria de testes em repositório real.

#### Story 1.1 — Setup Multimódulo Gradle (`com.kaell.kgit`) & Pipeline CI Dual-Target
- **Descrição:** Configurar os módulos `:app`, `:core:git`, `:core:storage`, `:core:sync`, `:feature:dashboard` e `:feature:settings` com Kotlin 2.x e Version Catalogs (`libs.versions.toml`).
- **Critérios de Aceite (AC):**
  - AC1: `applicationId "com.kaell.kgit"` configurado para instalar lado a lado sem conflitar com o app Flutter atual.
  - AC2: GitHub Actions configurada com dois jobs: (1) Testes unitários compilando o crate Rust para `linux-x86_64` e (2) Build de release compilando apenas `arm64-v8a`.
  - AC3: Detekt e Android Lint ativos na esteira de CI.

#### Story 1.2 — Implementação Completa da Ponte `:core:git`
- **Descrição:** Expor as operações essenciais de [`rust/src/api/git_manager.rs`](../../rust/src/api/git_manager.rs) na interface Kotlin `GitEngine` executando em `Dispatchers.IO`.
- **Critérios de Aceite (AC):**
  - AC1: Métodos expostos: `initRepo`, `cloneRepo`, `fetch`, `pull`, `push`, `commitAll`, `getStatus`, `getRecentCommits`, `getConflictingFiles`, `abortMerge`, `generateSshKey`, `isLocked`, `clearStaleLocks`.
  - AC2: Mapeamento de `git2::Error` para `sealed interface GitError` (NetworkError, AuthError, MergeConflict, LockContention, RepositoryCorrupted).
  - AC3: Preservação do mecanismo de file-locking nativo via `flock` ([`git_manager.rs:555`](../../rust/src/api/git_manager.rs)) como trava de última instância no filesystem.

#### Story 1.3 — Suíte de Testes de Integração `:core:git` (JUnit 5 + `@TempDir`)
- **Descrição:** Criar a bateria de testes automatizados JVM exercitando a biblioteca nativa `.so` (`linux-x86_64`) em repositórios Git temporários reais.
- **Critérios de Aceite (AC):**
  - AC1: Testes cobrindo `init` -> criação de nota `.md` -> `commitAll` -> leitura de `getRecentCommits`.
  - AC2: Testes cobrindo `pull` e `push` contra um repositório `bare` local em diretório temporário.
  - AC3: Testes cobrindo detecção de conflitos em edição simultânea da mesma linha e limpeza de locks órfãos (`clearStaleLocks`).

---

### Épico 2: Armazenamento Seguro, Credenciais & Migração de Backup (`:core:storage`)
**Objetivo:** Gerenciar configurações tipadas, credenciais GitHub/HTTPS/SSH com Google Tink + Android Keystore e importar backups do app legado.

#### Story 2.1 — Cofres e Preferências com Jetpack DataStore + Histórico Room
- **Descrição:** Implementar persistência reativa de configurações por cofre em `Proto/Preferences DataStore` e histórico de execuções/logs em `Room`.
- **Critérios de Aceite (AC):**
  - AC1: Modelo `VaultConfig` contendo caminho da pasta, URL remota, branch, tipo de provedor (`GITHUB`, `HTTPS`, `SSH`), flags de auto-sync ao abrir/fechar app e intervalo agendado.
  - AC2: Tabela Room `SyncLogEntry` registrando timestamp, cofre, gatilho (`MANUAL`, `OBSIDIAN_OPEN`, `OBSIDIAN_CLOSE`, `SCHEDULED`, `WIDGET`, `TILE`), duração, resultado e mensagem de erro detalhada.
  - AC3: Testes unitários validando persistência e retenção automática dos últimos 500 logs.

#### Story 2.2 — Cofre de Credenciais com DataStore + Google Tink (GitHub, HTTPS, SSH)
- **Descrição:** Armazenar tokens OAuth/PAT e chaves privadas SSH usando **Jetpack DataStore + Google Tink** com MasterKey no `AndroidKeyStore` (evitando a biblioteca descontinuada `EncryptedSharedPreferences`).
- **Critérios de Aceite (AC):**
  - AC1: Suporte completo a autenticação via **GitHub OAuth** (deep-link customizado), **HTTPS (Username/Token)** e **SSH (Ed25519/RSA)**.
  - AC2: Chaves privadas e tokens nunca são gravados em texto puro em disco ou exibidos em logs.
  - AC3: Testes unitários com MockK e Tink `CleartextKeysetHandle` (apenas em ambiente de teste) validando criptografia e descriptografia.

#### Story 2.3 — Permissões Android 14/15 & Importador de Backup Legado + `.kgitbackup`
- **Descrição:** Gerenciar a permissão `MANAGE_EXTERNAL_STORAGE` e suportar tanto o novo backup criptografado quanto a **importação direta do backup gerado pelo app Flutter atual**.
- **Critérios de Aceite (AC):**
  - AC1: Fluxo guiado para concessão de `Environment.isExternalStorageManager()`.
  - AC2: Compatibilidade de leitura/descriptografia com o arquivo de backup exportado pelo KGit Flutter atual (`repoManager` + `settingsManager`), permitindo migrar o cofre `palacio-mental` e as chaves SSH em 10 segundos sem reconfigurar manualmente.
  - AC3: Testes unitários validando a importação de um payload de backup legado de exemplo.

---

### Épico 3: Motor de Sincronização Resiliente & Obsidian Watcher (`:core:sync`)
**Objetivo:** Garantir sincronização rápida, atômica e dentro dos limites rígidos de background do Android 14/15, com observabilidade completa.

#### Story 3.1 — `SyncOrchestrator` (Mutex + `flock`) & Expedited WorkManager / FGS
- **Descrição:** Implementar o coordenador central de sync em processo único combinando `Mutex` por cofre no Kotlin com o `flock` nativo do Rust, usando **WorkManager Expedited (`OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST`)** para syncs rápidos e `ForegroundService` (`dataSync`) apenas para operações longas (ex: `clone`).
- **Critérios de Aceite (AC):**
  - AC1: Garantia de processo único no `AndroidManifest.xml` (nenhum receiver/service com `android:process` separado) + trava dupla (`Mutex` in-process + `flock` em disco).
  - AC2: Implementação obrigatória de `Service.onTimeout(int, int)` no `ForegroundService` para respeitar o limite de 6 horas do Android 15 (API 35) sem crashar com `RemoteServiceException`.
  - AC3: Testes com `kotlinx-coroutines-test` (`runTest`) provando que disparos simultâneos (ex: fechar Obsidian + toque no Widget) são deduplicados com segurança.

#### Story 3.2 — Obsidian Watcher Ultra-Leve em Memória (`AccessibilityService`)
- **Descrição:** Reescrever [`GitSyncAccessibilityService.kt`](../../android/app/src/main/kotlin/com/viscouspot/gitsync/GitSyncAccessibilityService.kt) para filtrar eventos diretamente em memória no Kotlin (`O(1)`), ignorando imediatamente teclado, launcher e apps não monitorados.
- **Critérios de Aceite (AC):**
  - AC1: O serviço lê um `Set<String>` volátil em memória alimentado pelo `Flow` do DataStore (ex: `setOf("md.obsidian")`).
  - AC2: Se `event.packageName` não pertencer ao conjunto monitorado nem representar a saída de um pacote monitorado, o método retorna imediatamente sem alocar `Intent` nem acionar serviços.
  - AC3: Máquina de estados com debounce configurável (ex: 3 segundos) para ignorar trocas rápidas (como abrir o seletor de arquivos ou teclado sobre o Obsidian).
  - AC4: Testes unitários puros em JUnit 5 validando a classe `AppTransitionTracker` contra sequências reais de eventos (`Obsidian -> Teclado -> Obsidian -> Home`).

#### Story 3.3 — Agendamento Periódico (`WorkManager`) & Notificações de Falha/Conflito
- **Descrição:** Implementar sincronização periódica automática (mínimo de 15 minutos imposto pelo `WorkManager` do Android) e alertas imediatos em caso de erro ou conflito.
- **Critérios de Aceite (AC):**
  - AC1: `PeriodicWorkRequest` com restrição `NetworkType.CONNECTED` e política de backoff exponencial.
  - AC2: **Observabilidade Ativa:** Se um sync em background falhar por conflito ou erro de autenticação, o app emite uma notificação acionável que leva direto à tela de resolução ou log do erro (nunca falha em silêncio).

---

### Épico 4: UI Zen em Jetpack Compose (`:feature:dashboard` & `:feature:settings`)
**Objetivo:** Construir a interface nativa em Jetpack Compose (120Hz, Material 3) refletindo o design limpo aprovado pelo Kaell.

#### Story 4.1 — Dashboard "Paz de Espírito" (MVI + Compose)
- **Descrição:** Implementar a tela principal em Jetpack Compose com hierarquia visual focada em status e rapidez.
- **Critérios de Aceite (AC):**
  - AC1: **Card de Status Superior:** Mostra estado claro (*"Cofre sincronizado"*, *"Alterações pendentes"* ou *"Conflito detectado"*), branch atual, mensagem/horário do último commit e botão para expandir o histórico de commits.
  - AC2: **Botão Master de Sync:** Pílula principal sólida em destaque (toque simples sincroniza; toque longo ou seta abre opções secundárias: Force Pull, Force Push).
  - AC3: **Barra de Ações Git Compacta:** Trio de botões de ícone (`Pull`, `Push`, `Commit`) com `PlainTooltip` nativo, sem texto truncado.
  - AC4: **Card do Cofre Unificado:** Exibe a pasta do cofre acompanhada do toggle de notificações e do atalho para configurações do cofre.
  - AC5: Testes de ViewModel com `Turbine` validando todas as transições de `DashboardUiState`.

#### Story 4.2 — Resolução Visual de Conflitos & Visualizador de Logs de Sync
- **Descrição:** Criar a tela de resolução rápida de conflitos para notas Markdown e o painel de diagnóstico/logs de sincronização.
- **Critérios de Aceite (AC):**
  - AC1: Lista arquivos conflitantes com ações de 1 toque: *"Manter versão deste celular (Local)"*, *"Manter versão da nuvem (Remoto)"* ou visualizar diff.
  - AC2: Tela de **Histórico de Sincronização (Diagnóstico)** exibindo as entradas do `SyncLogEntry` (Room) com botão de exportar/compartilhar log para debug rápido.

#### Story 4.3 — Configurações Globais e por Cofre em Material 3
- **Descrição:** Implementar as telas de configurações com componentes Material 3 (`Switch`, `SegmentedButton` para tema Claro/Sistema/Escuro), tipografia em Sentence Case (sem `ALL CAPS`) e seletor de apps para automação do Obsidian.
- **Critérios de Aceite (AC):**
  - AC1: Configuração rápida do gatilho do Obsidian (Sincronizar ao abrir / Sincronizar ao fechar).
  - AC2: Opção de ocultar o KGit da lista de apps recentes (`ActivityManager.AppTask.setExcludeFromRecents`).

---

### Épico 5: Ecossistema Android (Widgets Glance & Quick Settings)
**Objetivo:** Permitir sincronização manual e visualização de status direto da tela inicial ou barra de status do Galaxy A55.

#### Story 5.1 — Widgets Reativos em Jetpack Glance
- **Descrição:** Implementar os widgets de tela inicial usando Jetpack Glance conectados diretamente ao `SyncOrchestrator` e ao `DataStore`.
- **Critérios de Aceite (AC):**
  - AC1: Widget exibe nome do cofre, indicador visual de saúde (sincronizado / sincronizando / conflito) e horário do último sync.
  - AC2: Toque dispara o `SyncOrchestrator` em background sem abrir a Activity principal.

#### Story 5.2 — Quick Settings Tile Nativo
- **Descrição:** Conectar o `TileService` diretamente ao `SyncOrchestrator` para sincronizar com 1 toque na barra de controle do Android.
- **Critérios de Aceite (AC):**
  - AC1: O Tile atualiza seu subtítulo/estado para *"Sincronizando..."* durante a execução e *"Sincronizado"* ao concluir.

---

## 3. Estratégia de Qualidade e Testes Automatizados (Corrigida para Android)

| Camada | Runner & Ferramentas | Escopo de Teste |
| :--- | :--- | :--- |
| **Motor Git (`:core:git`)** | **JUnit 5** (JVM Host `linux-x86_64`) + `cargo test` + `@TempDir` | Operações reais do `libgit2` via UniFFI/JNI (commit, pull, push, conflitos e `flock`). |
| **Domínio & Watcher (`:core:sync`)** | **JUnit 5** + `MockK` + `kotlinx-coroutines-test` | Concorrência do `SyncOrchestrator`, máquina de estados `AppTransitionTracker` (`O(1)`) e debounce. |
| **ViewModels (`:feature:*`)** | **JUnit 5** + `Turbine` + `kotlinx-coroutines-test` | Emissão de estados MVI (`Loading`, `Synced`, `Conflict`, `Error`). |
| **Storage, Workers & UI Android** | **JUnit 4** + `Robolectric` + `Compose UI Test` + `WorkManagerTestInitHelper` | Testes que dependem de `Context` Android, Room, WorkManager e árvore de componentes Compose. |
