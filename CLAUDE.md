# CLAUDE.md

This file provides guidance for AI assistants (Claude Code) working in this repository.

## What this is

**MaxPage** is a Ruby on Rails engine (packaged as the `maxpage` gem) that mounts a simple
"status page" into a host Rails app. Consumers define a DSL of `metric`s (arbitrary Ruby blocks
that return a value), optionally attach `verify` rules (`min`/`max`/exact match/boolean), and
MaxPage renders them on a page and can email a status report via a rake task.

There is no host application here — `test/dummy` is a minimal Rails app that exists only to
exercise the engine in tests.

## Repository layout

```
lib/maxpage.rb              # Entry point: MaxPage.setup { ... } / MaxPage.config
lib/max_page/
  configuration.rb          # The DSL: title, metric, group, before_action,
                             # success_message/warning_message, email_* settings
  metric.rb                 # Metric model: name, description, verify, block, #run, #ok?
  group.rb                  # Simple struct: name + metrics
  engine.rb                 # Rails::Engine, isolate_namespace MaxPage;
                             # loads config/initializers/maxpage.rb after_initialize
  version.rb                # MaxPage::VERSION
lib/tasks/maxpage_tasks.rake  # `rake maxpage:check` — runs metrics, emails a report

app/controllers/max_page/
  application_controller.rb # Base controller for the engine
  metrics_controller.rb     # #index: runs all metrics, evaluates before_action, builds view data
app/helpers/max_page/
  metrics_helper.rb         # format_metric_value: trims decimals for numeric metric values
app/mailers/max_page/
  application_mailer.rb
  status_mailer.rb          # #status_report: builds failed-metrics summary email
app/views/max_page/
  metrics/index.html.erb, metrics/_metric.html.erb
  status_mailer/status_report.html.erb
app/views/layouts/max_page/application.html.erb, mailer.html.erb

config/routes.rb            # Engine routes: root -> metrics#index (mounted by host app)

test/                       # Minitest suite (Rails engine test conventions)
  dummy/                    # Minimal Rails app used only as a test harness — do not treat as
                             # a real consumer app; config here should stay minimal
  maxpage_test.rb           # Core DSL/Configuration/Metric behavior
  controllers/max_page/metrics_controller_test.rb  # Integration tests via Engine.routes.url_helpers
  mailers/status_mailer_test.rb                    # Email content/formatting tests
  integration/navigation_test.rb                   # currently empty scaffold
```

## Core concepts (the DSL)

Everything is configured once via `MaxPage.setup { ... }`, which builds a fresh
`MaxPage::Configuration` (calling `setup` again replaces the previous config — see
`lib/maxpage.rb`). Inside the block (`instance_eval`'d against `Configuration`):

- `metric(name, description: nil, verify: nil, &block)` — registers a `Metric`. The block is
  lazily run (`Metric#run` memoizes `@value`); it is *not* executed at setup time.
- `verify:` accepts `true`/a specific value (exact match), or a `Hash` with `:min`/`:max` keys.
  Any other hash key raises `RuntimeError` (validated eagerly in `Metric#verify=`).
- `group(name=nil, &block)` — metrics defined inside are added to both the group and the
  top-level `metrics` list (see `Configuration#metric`/`#group`); groups can be anonymous.
- `before_action(&block)` — evaluated in the controller's instance context in
  `MetricsController#before_index`, so Devise's `authenticate_x!`, Pundit's `authorize`, etc. work.
- `title`, `success_message`, `warning_message` — getter/setter-in-one methods (`nil` arg = getter).
- `email_to`, `email_from`, `email_send_on` — email settings, each falls back to an
  `MAXPAGE_EMAIL_*` env var (see `Configuration`) with `email_send_on` defaulting to
  `:only_failures`.

`MaxPage::Engine` auto-loads `config/initializers/maxpage.rb` from the **host app** after Rails
initialization (`config.after_initialize`) — this repo's own dummy app has no such initializer by
default, so tests call `MaxPage.setup` directly per-test instead of relying on that file.

## Development workflow

This is a gem developed against its own bundled dummy Rails app — there is no separate "install
and run" step.

```bash
bundle install                      # install gem + dummy app dependencies
bin/rails test                      # run the full test suite (Rails engine test runner)
bin/rails test test/maxpage_test.rb # run a single test file
bin/rails server                    # boots test/dummy with the engine mounted, for manual poking
```

`Rakefile` wires in `test/dummy`'s Rakefile plus `rails/tasks/engine.rake` and
`bundler/gem_tasks`, so standard gem tasks (`rake build`, `rake release`) and Rails engine tasks
are both available via `rake -T`.

There is no CI workflow and no linter (no `.rubocop.yml`) configured in this repo — rely on the
test suite.

## Conventions

- All engine code lives under the `MaxPage` module and `isolate_namespace MaxPage` — don't leak
  engine classes/routes into the host app's top-level namespace.
- `Configuration` methods follow a getter-when-nil-arg / setter-when-arg pattern
  (`title`, `success_message`, `email_to`, etc.) — keep new config options consistent with this.
- Metric values are formatted for display via `MetricsHelper#format_metric_value`, which strips
  insignificant decimals; see `test/mailers/status_mailer_test.rb` for the expected precision
  (`4.9`, not `4.8999999999999995`).
- Tests call `MaxPage.setup` at the start of each test (or in `setup`) rather than relying on an
  initializer file, since each call replaces `MaxPage.config` wholesale.
- Integration tests for the controller use `include Engine.routes.url_helpers` to get
  `metrics_index_url` inside `ActionDispatch::IntegrationTest`.
- README.md is the primary user-facing documentation (installation, DSL usage, email
  notifications, real-world metric examples) — keep it in sync with `Configuration` when adding
  DSL options.
- Version bumps: update `lib/max_page/version.rb` (`MaxPage::VERSION`); recent history bumps this
  in its own commit after a feature lands (see `git log`).

## Gotchas

- `Metric#run` memoizes into `@value`; `Metric#ok?` only calls `run` if `value` is falsy, so a
  metric whose block returns `false`/`nil` will re-run on every `ok?` call — this is existing
  behavior, not a bug to "fix" incidentally.
- `Configuration#metric` and `#group` both push onto the *same* `@metrics` array whether or not a
  group is active; `@groups` is separate. `MetricsController` uses
  `@metrics.reject(&:group)` to get ungrouped metrics for the view.
- `email_send_on` recognizes `:always`, `:only_failures`, `:never`; anything else falls back to
  `:only_failures` behavior in the rake task (see `lib/tasks/maxpage_tasks.rake`).
