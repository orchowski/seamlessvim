# seamlessvim

Modularna konfiguracja Neovima (bez kickstarta), nastawiona na JVM, C/C++, Go,
PHP, Python i Node/TypeScript/React — z LSP, neotestem i debuggerem.

```
init.lua
├── lua/config/        # rdzeń edytora (bez pluginów)
│   ├── options.lua    # opcje vima
│   ├── keymaps.lua    # globalne skróty (bez zależności od pluginów)
│   ├── autocmds.lua   # autokomendy
│   ├── lazy.lua       # bootstrap lazy.nvim + import plugins
│   ├── parsers.lua    # lista parserów treesitter (używana też przez instalator)
│   └── health.lua     # :checkhealth config
├── lua/plugins/       # jeden plik = jeden obszar
│   ├── ui.lua         # motyw, which-key, statusline, indent, todo
│   ├── editor.lua     # guess-indent, autopairs, neo-tree, render-markdown, csv
│   ├── telescope.lua
│   ├── harpoon.lua    # harpoon 2
│   ├── git.lua        # gitsigns (+ skróty)
│   ├── completion.lua # blink.cmp + LuaSnip
│   ├── treesitter.lua
│   ├── lsp.lua        # mason + lspconfig + diagnostyka + skróty LSP
│   ├── formatting.lua # conform
│   ├── lint.lua       # nvim-lint (markdownlint)
│   ├── dap.lua        # nvim-dap + dap-ui (+ konfigi Go/PHP/Python/Node/C-C++)
│   ├── test.lua       # neotest + adaptery
│   └── lang/          # cięższe toolingi językowe (właściciele własnych klientów LSP)
│       ├── java.lua   # nvim-jdtls
│       ├── kotlin.lua # kotlin.nvim (JetBrains kotlin-lsp)
│       ├── scala.lua  # nvim-metals
│       ├── clojure.lua# conjure
│       └── go.lua     # gopher.nvim + :SetGoBuildTags
├── lua/util/          # moduły pomocnicze (nie są specyfikacjami pluginów)
│   ├── groovyls_classpath.lua     # podaje classpath do groovyls z Gradle
│   └── neotest_gradle_spock.lua   # Groovy/Spock dla neotest-gradle
├── install.sh         # bootstrap (Arch / Debian / macOS)
├── update.sh          # aktualizacja na wielu maszynach
└── test/              # weryfikacja w Dockerze (arch + debian)
```

## Instalacja

```sh
git clone git@github.com:orchowski/seamlessvim.git ~/.config/nvim
~/.config/nvim/install.sh
```

`install.sh` instaluje narzędzia systemowe (nvim ≥ 0.11, git, rg, fd, fzf,
luarocks, tree-sitter-cli ≥ 0.26, gcc/make), runtime'y języków (JDK 21, Go, PHP +
composer, Python, Node), markdownlint, coursier (dla metals/scalafmt), opcjonalnie
Nerd Font, a następnie bootstrapuje pluginy, LSP/DAP/adaptery (mason) i parsery
treesitter. Obsługuje Arch (pacman), Debian/Ubuntu (apt), macOS (brew).

Flagi: `--yes` (nieinteraktywnie), `--no-fonts`, `SEAMLESSVIM_SOURCE=/path`
(instalacja z lokalnego checkoutu zamiast klonowania).

## Aktualizacja

```sh
~/.config/nvim/update.sh
```

Robi `git pull`, `:Lazy restore/sync`, aktualizację pakietów Masona, parserów
treesitter i narzędzi coursier. `SEAMLESSVIM_NO_PULL=1` pomija git pull.

## LSP / neotest / debugger

| Język | LSP | neotest | DAP |
|---|---|---|---|
| Java | `nvim-jdtls` (bundly java-debug/java-test z Masona) | `neotest-java` | java-debug (przez jdtls) |
| Kotlin | `kotlin.nvim` (kotlin-lsp) | `neotest-gradle` | kotlin.nvim |
| Groovy/Spock | `groovyls` (classpath z Gradle) | `neotest-gradle` (patch Spock) | — |
| Gradle | pliki `build.gradle` obsługuje `groovyls`, `*.gradle.kts` → Kotlin | — | — |
| Scala | `nvim-metals` | (metals test UI) | metals |
| Clojure | `clojure_lsp` (+ conjure) | — | — |
| C / C++ | `clangd` | `neotest-gtest` | `codelldb` |
| Go | `gopls` | `neotest-golang` | `delve` (nvim-dap-go) |
| PHP | `phpactor` | `neotest-phpunit` | php-debug-adapter (Xdebug/docker) |
| Python | `jedi_language_server` | `neotest-python` (pytest, `.venv`) | `debugpy` |
| TS/React/JS | `vtsls` | `neotest-vitest` / `neotest-jest` | js-debug-adapter |

Serwery/adaptory wymagające brakującego runtime'u są pomijane przy instalacji
(nie wywalają startu). Po zmianie runtime uruchom `update.sh`.

Uwagi:
- Java/Kotlin/Scala mają własnych właścicieli klienta LSP (jdtls / kotlin.nvim /
  metals) — nie są włączane przez `vim.lsp.enable` w `lsp.lua`.
- PHP nie jest formatowany przy zapisie (świadomie, jak wcześniej).
- Java/Kotlin/Go formatują się przez LSP lub dedykowane narzędzia (patrz
  `formatting.lua`).

## Skróty klawiaturowe

`<leader>` = spacja, `<localleader>` = `'`.

### Rdzeń

| Skrót | Tryb | Akcja |
|---|---|---|
| `<Esc>` | n | wyczyść podświetlenie wyszukiwania |
| `<leader>q` | n | diagnostyka → quickfix |
| `<Esc><Esc>` | t | wyjście z trybu terminala |
| `<C-h>` / `<C-l>` / `<C-j>` / `<C-k>` | n | fokus na okno |
| `<leader>yp` | n | skopiuj ścieżkę względną (rejestry `"` i `+`) |
| `<leader>cp` | n | skopiuj ścieżkę względną do schowka |
| `<leader>dh` / `<leader>ds` | n | ukryj / pokaż virtual text diagnostyki |

### Telescope

| Skrót | Akcja |
|---|---|
| `<leader>sh` | help |
| `<leader>sk` | keymapy |
| `<leader>sf` | pliki |
| `<leader>ss` | pickery telescope |
| `<leader>sw` | bieżące słowo |
| `<leader>sg` | live grep |
| `<leader>sd` | diagnostyka |
| `<leader>sr` | wznów |
| `<leader>s.` | ostatnie pliki |
| `<leader><leader>` | bufory |
| `<leader>/` | fuzzy w bieżącym buforze |
| `<leader>s/` | live grep w otwartych plikach |
| `<leader>sn` | pliki konfiguracji Neovima |

### LSP (bufor lokalnie)

| Skrót | Tryb | Akcja |
|---|---|---|
| `gtR` | n | zmiana nazwy |
| `gta` | n,x | akcja kodu |
| `gtr` | n | referencje |
| `gti` | n | implementacje |
| `gtd` | n | definicja |
| `gtD` | n | deklaracja |
| `gO` | n | symbole dokumentu |
| `gW` | n | symbole workspace |
| `gtt` | n | definicja typu |
| `<leader>th` | n | przełącz inlay hints |

### Formatowanie

| Skrót | Akcja |
|---|---|
| `<leader>f` | sformatuj bufor (`conform`, wszystkie tryby) |

### Git (gitsigns, bufor lokalnie)

| Skrót | Tryb | Akcja |
|---|---|---|
| `]c` / `[c` | n | następny / poprzedni hunk |
| `<leader>hs` | n,v | stage hunk |
| `<leader>hr` | n,v | reset hunk |
| `<leader>hS` | n | stage bufor |
| `<leader>hu` | n | undo stage hunk |
| `<leader>hR` | n | reset bufor |
| `<leader>hP` | n | preview hunk |
| `<leader>hb` | n | blame line |
| `<leader>hd` | n | diff względem indeksu |
| `<leader>hD` | n | diff względem ostatniego commita |
| `<leader>tb` | n | przełącz blame line |
| `<leader>tD` | n | preview usuniętych linii |

> Dwie świadome zmiany względem poprzedniej konfiguracji:
> `<leader>hP` = preview hunk (harpoon zachowuje `<leader>hp` = poprzedni mark),
> a `<leader>hu` faktycznie robi `undo_stage_hunk` (wcześniej wołał `stage_hunk`).

### Harpoon

| Skrót | Akcja |
|---|---|
| `<leader>ha` | dodaj plik |
| `<leader>hh` | menu |
| `<leader>h1` … `<leader>h4` | skok do marka |
| `<leader>hn` / `<leader>hp` | następny / poprzedni mark |

### Pliki (neo-tree)

| Skrót | Akcja |
|---|---|
| `<C-n>` | przełącz neo-tree |
| `<A-s>` | reveal |

### Debugger (nvim-dap)

| Skrót | Akcja |
|---|---|
| `<F5>` | start / kontynuuj |
| `<F1>` / `<F2>` / `<F3>` | step into / over / out |
| `<leader>b` | przełącz breakpoint |
| `<leader>B` | breakpoint warunkowy |
| `<F7>` | przełącz dap-ui |

### Testy (neotest)

| Skrót | Akcja |
|---|---|
| `<leader>tn` | najbliższy test |
| `<leader>tf` | test w pliku |
| `<leader>td` | debug testu |
| `<leader>ts` | summary |
| `<leader>to` | output |
| `<leader>tp` | panel outputu |
| `<leader>tw` / `<leader>tW` | watch najbliższego / pliku |
| `<leader>ta` | wszystkie testy projektu |

### Go (gopher.nvim)

| Skrót | Akcja |
|---|---|
| `<leader>ggi` | wstaw if err |
| `<leader>ggt` | tag json |
| `<leader>gga` | przełącz impl/test |
| `<leader>ggr` | uruchom bieżący test |
| `<leader>ggf` | uruchom test z pliku |

Polecenie `:SetGoBuildTags unit integration` ustawia `GOFLAGS` i restartuje gopls.

### JVM (bufor lokalnie)

| Skrót | Bufor | Akcja |
|---|---|---|
| `<leader>co` | Java/Scala | organize imports |
| `<leader>cv` | Java | extract variable |
| `<leader>cc` | Java | extract constant |
| `<leader>cm` | Java | extract method |
| `<leader>ci` | Scala | import build |
| `<leader>cr` | Scala | restart metals |

### CSV (csvview)

| Skrót | Tryb | Akcja |
|---|---|---|
| `if` / `af` | o,x | obiekt tekstowy pole |
| `<Tab>` / `<S-Tab>` | n,v | następne / poprzednie pole |
| `<Enter>` / `<S-Enter>` | n,v | następny / poprzedni wiersz |

## Weryfikacja

`test/` zawiera harness Dockerowy (Arch + Debian), który instaluje konfigurację
od zera (`install.sh --yes`) i sprawdza:

- `test/spec/01_install_spec.lua` — narzędzia systemowe, pakiety Masona,
  parsery treesitter, narzędzia coursier.
- `test/spec/02_keymaps_spec.lua` — komplet skrótów (globalne + gitsigns + CSV).
- `test/spec/03_lsp_spec.lua` — attach LSP na fixture dla każdego stacku
  (lua, go, python, ts, php, c, clojure, groovy, java, kotlin, scala) + mapy `gt*`.
- `test/spec/05_dap_spec.lua` — adaptery/konfiguracje DAP + smoke breakpointów
  (delve, debugpy).
- `test/integration/neotest_*.lua` — realne uruchomienie testów Go/Python/PHP,
  discovery adapterów oraz patch Spock. (Uruchamiane jako zwykłe skrypty, bo
  neotest używa korutyn `nio`, które zakleszczają się w testach busted.)

```sh
test/docker/run.sh arch      # lub: debian, both
```

Wynik: oba dystrybucje przechodzą cały zestaw (install → fixture → wszystkie
specy → `update.sh`). Na końcu: `PASS: all specs green`.
