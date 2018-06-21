local parser = clink.arg.new_parser

local function flags(...)
    local p = clink.arg.new_parser()
    p:set_flags(...)
    return p
end

-- https://github.com/angular/angular-cli/wiki/build
local build_parser = flags({
    "--aot",
    "--base-href",
    "--build-optimizer", 
    "--common-chunk",
    "--configuration", -- "-c",
    "--delete-output-path",
    "--deploy-url",
    "--eval-source-map",
    "--extract-css",
    "--extract-licenses",
    "--fork-type-checker",
    "--i18n-file",
    "--i18n-format",
    "--i18n-locale",
    "--i18n-missing-translation",
    "--index",
    "--main",
    "--named-chunks",
    "--ngsw-config-path",
    "--optimization",
    "--output-hashing",
    "--output-path",
    "--poll",
    "--polyfills",
    "--preserve-symlinks",
    "--prod",
    "--progress",
    "--no-progress",
    "--service-worker",
    "--show-circular-dependencies",
    "--skip-app-shell",
    "--source-map",
    "--stats-json",
    "--subresource-integrity",
    "--ts-config",
    "--vendor-chunk",
    "--verbose",
    "--watch", "-w"
})

-- https://github.com/angular/angular-cli/wiki/generate
local generate_parser = parser({
    -- "cl",
    "class" .. flags(
        "--force", 
        "--project", 
        "--spec", 
        "--type",
        "--dry-run"
    ),

    -- "c",
    "component" .. flags(
        "--change-detection", 
        "--export",
        "--flat",
        "--inline-style",
        "--inline-template",
        "--module",
        "--prefix",
        "--project",
        "--selector",
        "--skip-import",
        "--spec",
        "--styleext",
        "--view-encapsulation" .. parser({ "None", "Emulated", "Native" }),
        "--force",
        "--dry-run"
    ),

    -- "d",
    "directive" .. flags(
        "--export",
        "--flat",
        "--module",
        "--prefix",
        "--project",
        "--selector",
        "--skip-import",
        "--spec",
        "--force",
        "--dry-run"
    ), 
    -- "e",
    "enum" .. flags(
        "--project",
        "--force",
        "--dry-run"
    ), 
    -- "g",
    "guard" .. flags(
        "--flat",
        "--project",
        "--spec",
        "--force",
        "--dry-run"
    ),
    -- "i",
    "interface" .. flags(
        "--prefix",
        "--project",
        "--force",
        "--dry-run"
    ),
    -- "m",
    "module" .. flags(
        "--flat",
        "--module",
        "--project",
        "--routing",
        "--routing-scope",
        "--spec",
        "--force",
        "--dry-run"
    ),
    -- "p",
    "pipe" .. flags(
        "--export",
        "--flat",
        "--module",
        "--project",
        "--skip-import",
        "--spec",
        "--force",
        "--dry-run"
    ),
    -- "s",
    "service" .. flags(
        "--flat",
        "--project",
        "--spec",
        "--force",
        "--dry-run"
    ),
    "application" .. flags(
        "--inline-style",
        "--inline-template",
        "--prefix",
        "--routing",
        "--skip-package-json",
        "--skip-tests",
        "--style",
        "--view-encapsulation" .. parser({ "None", "Emulated", "Native" }),
        "--force",
        "--dry-run"
    ),
    "library" .. flags(
        "--entry-file",
        "--prefix",
        "--skip-package-json",
        "--skip-ts-config",
        "--force",
        "--dry-run"
    ),
    "universal" .. flags(
        "--app-dir",
        "--app-id",
        "--client-project",
        "--main",
        "--root-module-class-name",
        "--root-module-file-name",
        "--skip-install",
        "--test",
        "--test-tsconfig-file-name",
        "--tsconfig-file-name",
        "--force",
        "--dry-run"
    ),
    "appShell" .. flags(
        "--app-dir",
        "--app-id",
        "--client-project",
        "--index",
        "--main",
        "--name",
        "--out-dir",
        "--root",
        "--root-module-class-name",
        "--root-module-file-name",
        "--route",
        "--source-dir", "-D",
        "--test",
        "--test-tsconfig-file-name",
        "--tsconfig-file-name",
        "--universal-project",
        "--force",
        "--dry-run"
    )
})

-- https://github.com/angular/angular-cli/wiki/new
local new_parser = flags({
    "--collection", -- "-c",
    "--directory",
    "--dry-run", -- "--dryRun", "-d",
    "--force", -- "-f",
    "--inline-style", -- "-s",
    "--inline-template", -- "-t",
    "--new-project-root",
    "--prefix", -- "-p",
    "--routing",
    "--skip-git", -- "-g",
    "--skip-install",
    "--skip-tests", -- "-S",
    "--style", "--style=sass", "--style=scss", "--style=less",
    "--verbose", "-v",
    "--view-encapsulation" .. parser({ "None", "Emulated", "Native" })
}):loop(1)

-- https://github.com/angular/angular-cli/wiki/serve
local serve_parser = flags({
    "--aot",
    "--base-href",
    "--browser-target",
    "--common-chunk",
    "--configuration", -- "-c",
    "--deploy-url",
    "--disable-host-check",
    "--eval-source-map",
    "--hmr",
    "--hmr-warning",
    "--host",
    "--live-reload",
    "--open", "-o",
    "--optimization",
    "--poll",
    "--port",
    "--prod",
    "--progress",
    "--no-progress",
    "--proxy-config",
    "--public-host",
    "--serve-path",
    "--serve-path-default-warning",
    "--source-map",
    "--ssl",
    "--ssl-cert",
    "--ssl-key",
    "--vendor-chunk",
    "--watch"
})

-- https://github.com/angular/angular-cli/wiki/update
local update_parser = flags({
    "--all", 
    "--dry-run", 
    "--force", 
    "--from", 
    "--migrate-only", 
    "--next", 
    "--registry", 
    "--to"
})

-- https://github.com/angular/angular-cli/wiki/test
local test_parser = flags({
    "--browsers",
    "--code-coverage",
    "--configuration", -- "-c",
    "--environment",
    "--karma-config",
    "--main",
    "--poll",
    "--polyfills",
    "--preserve-symlinks",
    "--prod",
    "--progress",
    "--no-progress",
    "--source-map",
    "--ts-config",
    "--watch"
})

-- https://github.com/angular/angular-cli/wiki/e2e
local e2e_parser = flags({
    "--base-url",
    "--configuration", -- "-c",
    "--dev-server-target",
    "--element-explorer",
    "--host",
    "--port",
    "--prod",
    "--protractor-config",
    "--suite",
    "--webdriver-update"
})

-- https://github.com/angular/angular-cli/wiki/lint
local lint_parser = flags({
    "--configuration", -- "-c",
    "--tslint-config",
    "--fix",
    "--type-check",
    "--force",
    "--silent",
    "--format"
})
-- https://github.com/angular/angular-cli/wiki/serve
local serve_parser = flags({
    "--aot",
    "--base-href",
    "--browser-target",
    "--common-chunk",
    "--configuration", -- "-c",
    "--deploy-url",
    "--disable-host-check",
    "--eval-source-map",
    "--hmr",
    "--hmr-warning",
    "--host",
    "--live-reload",
    "--open", "-o",
    "--optimization",
    "--poll",
    "--port",
    "--prod",
    "--progress",
    "--no-progress",
    "--proxy-config",
    "--public-host",
    "--serve-path",
    "--serve-path-default-warning",
    "--source-map",
    "--ssl",
    "--ssl-cert",
    "--ssl-key",
    "--vendor-chunk",
    "--watch"
})

-- https://github.com/angular/angular-cli/wiki/xi18n
local xi18n_parser = flags({
    "--browser-target",
    "--configuration", -- "-c",
    "--i18n-format",
    "--i18n-locale",
    "--out-file",
    "--output-path"
})

-- https://github.com/angular/angular-cli/wiki/run
local run_parser = flags({
    "--configuration" --, "-c"
})

-- https://github.com/angular/angular-cli/wiki/config
local config_parser = parser({
    "--global" --, "-g"
})

local ng_parser = parser({
    "add", -- TODO: auto-detect installed collections
    "new"..new_parser,
    "generate"..generate_parser, --"g"..generate_parser,
    "update"..update_parser,
    "build"..build_parser, --"b"..build_parser,
    "serve"..serve_parser, --"server"..serve_parser, "s"..serve_parser,
    "test"..test_parser, --"t"..test_parser,
    "e2e"..e2e_parser,
    "lint"..lint_parser,
    "xi18n"..xi18n_parser,
    "run"..run_parser,
    "eject",
    "config"..config_parser,
    "help",
    "version",
    "doc",
    "make-this-awesome"
})

clink.arg.register_parser("ng", ng_parser)