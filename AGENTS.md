# Code Guidelines

## Quién usa esta gema

empieza2 la instala desde GitHub, sin `ref` ni `tag`:

```ruby
gem 'survey_engine', git: 'https://github.com/gsanchezd/survey_engine'
```

Su `Gemfile.lock` queda fijado en un commit (`revision:`) hasta que alguien corre
`bundle update survey_engine` allá, y entonces se trae **lo que haya en `main` en ese momento**. Un
push a `main` no despliega nada por sí solo, pero es lo próximo que va a recibir empieza2. Por eso
`main` tiene que estar siempre en condiciones de instalarse.

Dos consecuencias de convivir con empieza2:

- **empieza2 tiene sus propios `::Question` y `::Answer`.** Toda relación del engine nombra la clase
  con su módulo (`class_name: "SurveyEngine::Question"`). Con `"Question"` a secas Rails busca
  primero `::Question` y en empieza2 apunta al modelo de quizzes (ver 0.1.19 en el `CHANGELOG.md`).
  La app dummy no tiene esos modelos, así que los tests normales no lo ven:
  `test/models/survey_engine/question_class_name_test.rb` define uno para reproducirlo. Un modelo
  nuevo del engine con un nombre común (`Option`, `Response`, `Participant`) tiene el mismo riesgo.
- **Ruby y Rails van al paso de empieza2.** El gemspec acepta `rails >= 7.1.0`, pero los tests
  corren contra una sola versión, la de los `Gemfile.lock`. Hay que mantener esa versión igual a la de
  empieza2, que es donde la gema corre de verdad.

## Flujo de ramas

Trunk based: todo cambio sale de `main` en una rama corta y vuelve a `main` con un merge local y un
push. No hay `develop` ni `staging`.

| Rama | Para qué | Versión |
| --- | --- | --- |
| `feat/<nombre>` | Funcionalidad nueva | Sube el dígito del medio (0.1.19 → 0.2.0) |
| `fix/<nombre>` | Corrección de algo que funciona mal | Sube el último dígito (0.1.19 → 0.1.20) |
| `chore/<nombre>` | Mantenimiento sin cambio funcional: upgrade de Ruby, Rails o gemas, CI | Sube el último dígito |
| `docs/<nombre>` | Solo documentación: `AGENTS.md`, `CLAUDE.md`, `README.md` | Sin bump; entrada en `CHANGELOG.md` bajo `[Sin versión]` |

Si un cambio mezcla documentación con código, lleva el tipo del código. Nombres en minúsculas, sin
caracteres especiales (solo `/` y `_`).

**Antes de cada push se corren estas cuatro revisiones en local, y si algo falla no se pushea:**

```bash
bin/rails test                                  # siempre
bin/rubocop                                     # siempre
brakeman -q --no-pager                          # siempre; avisos de seguridad en el código
bundle-audit check --update                     # siempre; avisos de seguridad en las gemas
(cd test/dummy && bundle-audit check)           # la dummy tiene su propio Gemfile.lock
```

- **RuboCop:** una infracción nueva se arregla, no se deja para después. Ojo con `-A`: varias
  correcciones "inseguras" cambian el comportamiento, como `map { }.compact` → `filter_map`, que
  descarta también los `false`. `-a` solo aplica las seguras.
- **Brakeman:** una advertencia nueva se arregla. Si de verdad es un falso positivo, se agrega a
  `config/brakeman.ignore` con `brakeman -I` y una nota que diga por qué, nunca sin nota.
- **bundler-audit:** compara cada `Gemfile.lock` contra la base pública de avisos (por eso el
  `--update`). Hay que revisar los dos lockfiles: se resuelven por separado y uno puede quedar
  vulnerable aunque el otro esté limpio. Se arregla actualizando la gema. Ignorar un aviso es la
  excepción y va con un comentario que diga por qué.

Pasos:

1. Crear la rama desde `main` actualizado:
   ```bash
   git fetch origin
   git checkout -b fix/<nombre> origin/main
   ```
2. Hacer los cambios y commitearlos.
3. Bump de versión en la rama, **recién antes de mergear**:
   - `lib/survey_engine/version.rb`
   - `bundle install` en la raíz **y** en `test/dummy`: los dos `Gemfile.lock` guardan la versión de
     la gema. Es fácil olvidar el segundo: después del bump a 0.1.19 la dummy siguió diciendo 0.1.18.
   - `CHANGELOG.md`: entrada nueva al tope con versión, fecha y descripción. Las entradas son prosa
     que explica el porqué y las trampas, no una lista de commits (la de 0.1.19 es el modelo).

   Una rama `docs/` no sube la versión: su entrada va bajo `## [Sin versión]` al tope del
   `CHANGELOG.md` (se crea si no existe). La próxima rama con número cambia ese encabezado por
   `## [X.Y.Z] - fecha` y suma su entrada en esa misma sección.
4. Correr las revisiones de arriba. Después mergear en `main` en local y pushear:
   ```bash
   git checkout main && git pull --ff-only
   git merge --no-ff fix/<nombre>
   git push origin main
   ```
5. Borrar la rama: `git branch -d fix/<nombre>`.

## Versión de Ruby

Se fija en dos archivos y hay que cambiar los dos juntos:

- `mise.toml`: **es el que manda en local**. mise lo lee antes que `.ruby-version`, así que si solo
  se cambia `.ruby-version`, todo sigue corriendo con la versión anterior sin avisar. Pasó con el
  commit "Ruby 3.4.13 (parche de seguridad)": cambió solo `.ruby-version` y en local se siguió
  usando 3.4.4 hasta que se corrigió `mise.toml`.
- `.ruby-version`: lo lee el CI (`ruby-version: .ruby-version` en `.github/workflows/ci.yml`), así
  que el CI no tiene la versión escrita y no hay que tocarlo.

Después de cambiar la versión, una terminal que ya estaba abierta puede seguir con el Ruby anterior
en el `PATH`. `mise current ruby` dice qué versión corresponde y `ruby -v` cuál se está usando;
si no coinciden, abrir una terminal nueva. Con la versión correcta, `bundle install` en la raíz y
en `test/dummy`.
