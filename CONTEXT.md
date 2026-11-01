# seamlessvim — dump kontekstu (stan prac)

> Zapisz/aktualizuj ten plik jako notatkę o stanie projektu i sesji. Ostatnia
> aktualizacja: 2026-11-01.

## Cel projektu

Przepisać config Neovima od zera (bez kickstarta), **zachowując wszystkie
skróty klawiaturowe i funkcjonalność**, z naciskiem na:

- LSP dla JVM: java, kotlin, groovy, gradle, scala, clojure
- LSP dla: C/C++, Go, PHP, Python, Node/TS/React
- **neotest + debugger** dla tych języków
- telescope + harpoon (istotne)
- czysta, modularna struktura; łatwe aktualizacje
- skrypty instalacyjno-aktualizacyjne: macOS + Arch + Debian
- **weryfikacja w Dockerze: arch + debian**

## Struktura repo (`/home/alex/projects/seamlessvim`)

```
init.lua
lua/config/{options,keymaps,autocmds,lazy,parsers,health}.lua
lua/plugins/{ui,editor,telescope,harpoon,git,completion,treesitter,lsp,
             formatting,lint,dap,test}.lua
lua/plugins/lang/{java,kotlin,scala,clojure,go}.lua
lua/util/{groovyls_classpath,neotest_gradle_spock}.lua
install.sh, update.sh, README.md, .gitignore, lazy-lock.json
test/{docker,fixtures,spec,integration}
```

- `lua/config/` — rdzeń edytora (bez pluginów)
- `lua/plugins/` — lazy.nvim: jeden plik = jeden obszar
- `lua/plugins/lang/` — właściciele własnych klientów LSP (jdtls, kotlin.nvim,
  metals, gopher, conjure)
- `lua/util/` — moduły pomocnicze (nie-specy)

## Kluczowe decyzje architektoniczne

- Harpoon 2; telescope z custom `path_display` (2 katalogi + nazwa) i layoutem
  vertical; blink.cmp + LuaSnip; nvim-treesitter branch `main` (rewrite).
- Właściciele klientów LSP:
  - Java → `nvim-jdtls` (bundles java-debug + java-test z Masona)
  - Kotlin → `kotlin.nvim` (kotlin-lsp)
  - Scala → `nvim-metals` (coursier)
  - reszta → `vim.lsp.config` + `vim.lsp.enable` w `lua/plugins/lsp.lua`
- `vtsls` (TS/React), `jedi_language_server` (Python), `phpactor` (PHP),
  `groovyls` (Groovy), `clangd`, `gopls`, `clojure_lsp`.
- **`gradle_ls` wyrzucony** — jar z Masona nie ma manifestu (`java -jar` nie
  działa). `build.gradle` obsługuje `groovyls`, `*.gradle.kts` → Kotlin.
- Skróty 1:1 z poprzedniej konfiguracji + 2 świadome zmiany:
  - `<leader>hP` = preview hunk (harpoon trzyma `<leader>hp` = prev mark),
  - `<leader>hu` = `undo_stage_hunk` (fix buga).

## Weryfikacja w Dockerze

Harness: `test/docker/{Dockerfile,run.sh,inside.sh}` + `test/fixtures/*` +
`test/spec/*_spec.lua` + `test/integration/*.lua`.

Uruchomienie: `test/docker/run.sh both` (albo `arch` / `debian`).

Wynik (oba obrazy): **`PASS: all specs green`**

- `01_install_spec` 53/0 — narzędzia, pakiety Masona, parsery treesitter
- `02_keymaps_spec` 80/0 — komplet skrótów (globalne + gitsigns + CSV)
- `03_lsp_spec` 21/0 — attach LSP na fixture dla 11 stacków + mapy `gt*`
- `05_dap_spec` 16/0 — adaptery/konfiguracje DAP + smoke delve/debugpy
- `test/integration/neotest_{go,python,php,discovery}.lua` — realne uruchomienie
  testów + discovery adapterów + patch Spock (jako plain skrypty, bo neotest
  używa korutyn `nio`, które zakleszczają się w testach plenary-busted).

Uwaga: przy uruchomieniu testów lokalnie (nie w Dockerze) LSP (jdtls/metals)
tworzy artefakty build w `test/fixtures/**` — są w `.gitignore`.

## Stan Git

- Repo ma commit `56f2e2e seamless vim 2.0`.
- **Niezacommitowane** (w repo i w `~/.config/nvim`):
  - `lua/plugins/dap.lua`
  - `lua/util/groovyls_classpath.lua`

## Przełączenie lokalnego configu

`~/.config/nvim` = kopia repo (backup WIP-a: `~/.config/nvim-backup-20261101065004.tar.gz`).

Zainstalowane: lazy pluginy, 37 parserów treesitter, 32 pakiety Mason,
`metals`/`scalafmt` (coursier). Systemowych pakietów nie ruszano (bez sudo) —
braki doinstalować przez `~/.config/nvim/install.sh --yes`.

Aktualizacja później: `~/.config/nvim/update.sh`.

## Skrypty

- `install.sh` — Arch (pacman), Debian/Ubuntu (apt), macOS (brew). Flagi:
  `--yes`, `--no-fonts`; env: `SEAMLESSVIM_SOURCE` (instalacja z lokalnego
  checkoutu), `SEAMLESSVIM_TARGET`, `SEAMLESSVIM_REPO`.
  - Debian: nvim z GitHub releases, tree-sitter-cli z GitHub releases (apt za
    stare), openjdk-25, Go z upstream (delve wymaga ≥1.25), PHP: php-xml/
    php-mbstring/php-curl/php-zip, Clojure CLI z oficjalnego instalatora.
  - Arch: włącza `extension=iconv` (phpactor), ustawia najnowszy JDK jako
    domyślny (jdtls wymaga ≥25).
  - macOS: brew openjdk/go/php/composer/python/node, tree-sitter.
- `update.sh` — git pull → `Lazy restore/sync` → `MasonToolsUpdateSync` →
  `TSUpdate` → `cs install metals scalafmt`.

## Naprawy po drodze (zweryfikowane)

### LSP

- **Groovy (groovyls)** — `lua/util/groovyls_classpath.lua`.
  groovyls **ignoruje katalogi klas** (w `CompilationUnitFactory.getClasspathList`
  przepuszcza tylko `.jar`). Feeder: buduje `jar` modułu (`gradlew jar`), do
  classpath dokłada **jary zależności** + katalog `build/libs` (groovyls czyta
  jary z katalogu), pushuje przez `workspace/didChangeConfiguration`.
  Zweryfikowane na `peakydevel/java`: diagnostyka „unable to resolve class App"
  znikła (`diagnostics: 0`, definition/hover OK).

### Debugger Python — `lua/plugins/dap.lua`

Problem: debugpy startował debuggee systemowym pythonem i bez `sys.path` roota.

Fix (dla `dap.configurations.python`):
1. `python` = venv: `VIRTUAL_ENV`/`CONDA_PREFIX` → `.venv`/`venv`/`env` w rootcie
   projektu → `python3`.
2. `cwd` + `PYTHONPATH` = root projektu (fix `import app` z podkatalogów).
3. Auto tryb modułu: jeśli plik leży w pakiecie (`<root>/<top>/__init__.py`
   istnieje) → `module = "pkg.mod"` (fix **względnych** importów `from .x`),
   inaczej `program = ${file}`.

Zweryfikowane na `~/projects/peakydevel/eru`:
```
exe = .../eru/.venv/bin/python
cryptography 46.0.3 (z venv), app = ok, from app import config = ok
```
Działa bez `source .venv/bin/activate` (fallback na `.venv`) i z aktywacją.

## W TOKU: DAP dla Groovy/Spock

- Ustalone: `weilbith/neotest-gradle` **nie ma** strategii dap → `<leader>td`
  nie zadziała dla testów Spocka.
- Zweryfikowane, że działa: `./gradlew test --tests <Klasa> --debug-jvm`
  (zawiesza test JVM, nasłuch na 127.0.0.1:5005) + attach przez java-debug
  (adapter `java` z `nvim-jdtls`) → `ATTACH initialized: true`.
- Do dodania (niedokończone):
  1. `lua/plugins/lang/java.lua` — markery roota + `build.gradle.kts`,
     `settings.gradle.kts`.
  2. `lua/plugins/dap.lua` — globalna rejestracja adaptera java
     (`require('jdtls').setup_dap`), `dap.configurations.groovy` (attach 5005),
     komenda `:GradleDebugTest` (spawn `gradlew test --tests <K> --debug-jvm` +
     auto-attach po otwarciu portu).
- Ograniczenie: adapter `java` (java-debug) wymaga klienta jdtls z attached
  buforem w projekcie → w praktyce trzeba mieć otwarty jakiś plik `.java` w
  projekcie (albo doimplementować auto-start jdtls dla Groovy).

## Skróty DAP

| Klawisz | Akcja |
|---|---|
| `<F5>` | start / continue |
| `<F1>` | step into |
| `<F2>` | step over |
| `<F3>` | step out |
| `<leader>b` | toggle breakpoint |
| `<leader>B` | breakpoint warunkowy |
| `<F7>` | toggle dap-ui (Scopes/Stack/Watches/Breakpoints/REPL) |

## Wbudowane komendy DAP (nieprzypisane)

`:lua require('dap').run()`, `:DapContinue`, `:DapToggleRepl`, `:DapTerminate`,
`:DapRestart`.

## Następny krok

Dokończyć DAP dla Groovy (pkt 1–2 wyżej), przetestować `:GradleDebugTest` na
`peakydevel/java`, potem finalnie przepuścić `test/docker/run.sh both`.
Na koniec zdecydować o commicie (`dap.lua`, `groovyls_classpath.lua`).
