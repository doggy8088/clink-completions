local matchers = require('matchers')
local w = require('tables').wrap
local parser = clink.arg.new_parser

local csproj_files_matcher = matchers.create_files_matcher("*.csproj")
local nuget_files_matcher = matchers.create_files_matcher("*.config")

local function flags(...)
    local p = clink.arg.new_parser()
    p:set_flags(...)
    return p
end

-- https://stackoverflow.com/a/27028488/910074
local function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end
 
-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-new?tabs=netcore21

local template_list = {
    "console", 
    "classlib",
    "mstest", "xunit",
    "web", "mvc", "webapi",
    "page", "viewimports", "viewstart", "razor", "razorclasslib",
    "angular", "react", "reactredux", 
    "globaljson", "nugetconfig", "webconfig", "sln"
}

local function get_sdk_list()
    local res = w()

    local proc = io.popen("dotnet --list-sdks")
    if not proc then
        return res
    end

    for line in proc:lines() do
        local s = line:find(" ", 1, true)
        local version_name = line:sub(0, s-1)
        table.insert(res, version_name)
    end

    proc:close()

    -- print(dump(res))
    table.sort(res, function(a, b) return a > b end)
    -- print(dump(res))

    -- 要加上這段才能顯示的時候有排序！
    -- https://github.com/AmrEldib/cmder-powerline-prompt/blob/master/docs/clink.md
    clink.match_display_filter = function ()
        return res
    end

    return res
end

local function get_framework_list()
    -- local res = w()

    local res = {
        -- https://docs.microsoft.com/en-us/dotnet/standard/frameworks
        "netstandard2.0", "netcoreapp2.1", 
        "net472", "net471", "net47", "net462", "net461", "net46",  "net452", "net451", "net45"
    }

    table.sort(res, function(a, b) return a > b end)

    -- 要加上這段才能顯示的時候有排序！
    -- https://github.com/AmrEldib/cmder-powerline-prompt/blob/master/docs/clink.md
    clink.match_display_filter = function ()
        return res
    end

    return res
end

local DBCONTEXT_LIST
local DBCONTEXT_COUNT = 0
local function get_dbcontext_list()
    DBCONTEXT_COUNT=DBCONTEXT_COUNT+1
    -- 最多呼叫五次之後，就會重新再抓取 dbcontext 清單
    if DBCONTEXT_COUNT % 5 == 0 then DBCONTEXT_LIST = nil end

    if DBCONTEXT_LIST then return DBCONTEXT_LIST end

    local res = w()

    -- local proc = io.popen("dotnet ef dbcontext list --no-build")
    local proc = io.popen("dotnet ef dbcontext list")
    if not proc then
        return res
    end

    for line in proc:lines() do
        table.insert(res, line)
    end

    proc:close()

    table.sort(res, function(a, b) return a > b end)

    -- 要加上這段才能顯示的時候有排序！
    -- https://github.com/AmrEldib/cmder-powerline-prompt/blob/master/docs/clink.md
    clink.match_display_filter = function ()
        return res
    end

    DBCONTEXT_LIST = res

    return res
end

local new_flags = {
    "--force",
    "--install",
    "--language"..parser({"C#", "F#", "VB"}), -- "--lang",
    "--name", -- "-n",
    "--nuget-source", -- "-s",
    "--output"..parser({matchers.dirs}), -- "-o",
    "--uninstall", -- "-u",
    "--list", -- "-l",
    "--help"
}

local new_parser = parser({
    "console"..flags({
        "--no-restore",
        table.unpack(new_flags)
    }):loop(1),
    "angular"..flags({
        "--no-restore",
        table.unpack(new_flags)
    }):loop(1),
    "react"..flags({
        "--no-restore",
        table.unpack(new_flags)
    }):loop(1),
    "reactredux"..flags({
        "--no-restore",
        table.unpack(new_flags)
    }):loop(1),
    "razorclasslib"..flags({
        "--no-restore",
        table.unpack(new_flags)
    }):loop(1),
    "classlib"..flags({
        "--no-restore",
        "--framework"..parser({get_framework_list}), -- "-f",
        table.unpack(new_flags)
    }):loop(1),
    "mstest"..flags({
        "--enable-pack", -- "-p",
        "--no-restore",
        table.unpack(new_flags)
    }):loop(1),
    "xunit"..flags({
        "--enable-pack", -- "-p",
        "--no-restore",
        table.unpack(new_flags)
    }):loop(1),
    "globaljson"..flags({
        "--sdk-version"..parser({get_sdk_list}),
        table.unpack(new_flags)
    }),
    "web"..flags({
        "--use-launch-settings",
        "--no-restore",
        table.unpack(new_flags)
    }):loop(1),
    "webapi"..flags({
        "--auth"..parser({"None", "IndividualB2C", "SingleOrg", "Windows"}),
        "--aad-b2c-instance",
        "--susi-policy-id",
        "--aad-instance",
        "--client-id",
        "--domain",
        "--tenant-id",
        "--org-read-access", -- "-r",
        "--use-launch-settings",
        "--use-local-db", -- "-uld",
        "--no-https",
        "--no-restore",
        table.unpack(new_flags)
    }):loop(1),
    "mvc"..flags({
        "--auth"..parser({"None", "IndividualB2C", "SingleOrg", "Windows"}),
        "--aad-b2c-instance",
        "--susi-policy-id",
        "--aad-instance",
        "--client-id",
        "--domain",
        "--tenant-id",
        "--callback-path",
        "--org-read-access", -- "-r",
        "--use-launch-settings",
        "--use-browserlink",
        "--use-local-db", -- "-uld",
        "--no-https",
        "--no-restore",
        table.unpack(new_flags)
    }):loop(1),
    "razor"..flags({
        "--auth"..parser({"None", "IndividualB2C", "SingleOrg", "Windows"}),
        "--aad-b2c-instance",
        "--susi-policy-id",
        "--aad-instance",
        "--client-id",
        "--domain",
        "--tenant-id",
        "--callback-path",
        "--org-read-access", -- "-r",
        "--use-launch-settings",
        "--use-browserlink",
        "--use-local-db", -- "-uld",
        "--no-https",
        "--no-restore",
        table.unpack(new_flags)
    }):loop(1),
    "page"..flags({
        "--namespace", -- "-na",
        "--no-pagemodel", -- "-np",
        "--no-restore",
        table.unpack(new_flags)
    }):loop(1),
    "page"..flags({
        "--namespace", -- "-na",
        table.unpack(new_flags)
    }):loop(1)
}):loop(1)

new_parser:set_flags(table.unpack(new_flags))


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-restore?tabs=netcore2x
local restore_parser = parser({
    "--configfile"..parser({nuget_files_matcher, "NuGet.config"}),
    "--disable-parallel",
    "--force",
    "--help", -- "-h",
    "--ignore-failed-sources",
    "--no-cache",
    "--no-dependencies",
    "--packages"..parser({matchers.dirs}),
    "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
    "--source", -- "-s",
    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"})
}):loop(1)


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-build?tabs=netcore2x
local build_parser = parser({
    "--configuration"..parser({"Debug", "Release"}),
    "--framework"..parser({get_framework_list}), -- "-f",
    "--force",
    "--help", -- "-h",
    "--ignore-failed-sources",
    "--no-dependencies",
    "--no-incremental",
    "--no-restore",
    "--output"..parser({matchers.dirs}), -- "-o",
    "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
    "--version-suffix"
}):loop(1)


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-publish?tabs=netcore21
local publish_parser = parser({
    "--configuration"..parser({"Debug", "Release"}),
    "--framework"..parser({get_framework_list}), -- "-f",
    "--force",
    "--help", -- "-h",
    "--manifest"..parser({matchers.files}),
    "--no-build",
    "--no-dependencies",
    "--no-restore",
    "--output"..parser({matchers.dirs}), -- "-o",
    "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
    "--version-suffix"
}):loop(1)


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-run?tabs=netcore21
local run_parser = parser({
    "--",
    "--configuration"..parser({"Debug", "Release"}),
    "--framework"..parser({get_framework_list}), -- "-f",
    "--force",
    "--help", -- "-h",
    "--launch-profile"..parser({"Development", "Staging", "Production"}),
    "--no-build",
    "--no-dependencies",
    "--no-launch-profile",
    "--no-restore",
    "--project"..parser({matchers.dirs}), -- "-p",
    "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"})
}):loop(1)


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-test?tabs=netcore21
local test_parser = parser({
    "--test-adapter-path", -- "-a",
    "--blame",
    "--configuration"..parser({"Debug", "Release"}),
    "--collect",
    "--diag"..parser({matchers.files}),
    "--framework"..parser({get_framework_list}), -- "-f",
    "--filter", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-test?tabs=netcore21#filter-option-details
    "--help", -- "-h",
    "--logger",
    "--no-build",
    "--no-restore",
    "--output"..parser({matchers.dirs}), -- "-o",
    "--results-directory"..parser({matchers.dirs}), -- "-r",
    "--settings"..parser({matchers.files}), -- "-s",
    "--list-tests",
    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}) -- "-v"
}):loop(1)


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-vstest?tabs=netcore21
local vstest_parser = parser({
    "--Settings"..parser({matchers.files}),
    "--Tests",
    "--TestAdapterPath"..parser({matchers.dirs}),
    "--Platform"..parser({"x86", "x64", "ARM"}),
    "--Framework"..parser({".NETFramework,Version=v4.6", ".NETCoreApp,Version=v1.0", "Framework35", "Framework40", "Framework45", "FrameworkCore10", "FrameworkUap10"}),
    "--Parallel",
    "--TestCaseFilter",
    "--Help", "-?",
    "--logger",
    "--ListTests",
    "--ParentProcessId",
    "--Port",
    "--Diag",
    "--Blame",
    "--InIsolation"
}):loop(1)


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-pack?tabs=netcore2x
local pack_parser = parser({
    "--configuration"..parser({"Debug", "Release"}),
    "--force",
    "--help", -- "-h",
    "--include-source",
    "--include-symbols",
    "--no-build",
    "--no-dependencies",
    "--no-restore",
    "--output"..parser({matchers.dirs}), -- "-o",
    "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
    "--results-directory"..parser({matchers.dirs}), -- "-r",
    "--serviceable", -- https://aka.ms/nupkgservicing
    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
    "--version-suffix"
}):loop(1)


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-migrate
local migrate_parser = parser({
    "--format-report-file-json"..parser({matchers.files}),
    "--help", -- "-h",
    "--report-file"..parser({matchers.files}),
    "--skip-project-references"..parser({"Debug", "Release"}),
    "--skip-backup",
    "--template-file"..parser({matchers.files}),
    "--sdk-package-version"..parser({get_sdk_list}),
    "--xproj-file"..parser({matchers.files})
}):loop(1)


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-clean?tabs=netcore2x
local clean_parser = parser({
    "--configuration"..parser({"Debug", "Release"}),
    "--framework"..parser({get_framework_list}), -- "-f",
    "--help", -- "-h",
    "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"})
}):loop(1)


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-sln
local sln_parser = parser({
    "add"..parser({matchers.files, "**/*.csproj"}),
    "remove"..parser({matchers.files, "**/*.csproj"}),
    "list"
}):loop(1)


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-store
local store_parser = parser({
    "--framework"..parser({get_framework_list}), -- "-f",
    "--help", -- "-h",
    "--output"..parser({matchers.dirs}), -- "-o",
    "--skip-optimization",
    "--skip-symbols",
    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
    "--working-dir"..parser({matchers.dirs})
}):loop(1)

-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-add-package
local add_package_parser = flags({
    "--help", -- "-h"
    "--framework"..parser({get_framework_list}), -- "-f",
    "--no-restore",
    "--package-directory"..parser({matchers.dirs}),
    "--source"..parser({matchers.dirs}),
    "--version"
}):loop(1)
-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-add-reference
local add_reference_parser = parser({matchers.files}, {
    "--help", -- "-h",
    "--framework"..parser({get_framework_list}), -- "-f"
}):loop(1)

local add_parser = parser({csproj_files_matcher, "package"..add_package_parser, "reference"..add_reference_parser, "--help"}, {
    "package"..add_package_parser,
    "reference"..add_reference_parser,
    "--help", -- "-h"
}):loop(1)


-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-remove-package
local remove_package_parser = flags({
    "--help", -- "-h"
    "--framework"..parser({get_framework_list}), -- "-f",
    "--no-restore",
    "--package-directory"..parser({matchers.dirs}),
    "--source"..parser({matchers.dirs}),
    "--version"
}):loop(1)
-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-remove-reference
local remove_reference_parser = parser({matchers.files}, {
    "--help", -- "-h",
    "--framework"..parser({get_framework_list}), -- "-f"
}):loop(1)

local remove_parser = parser({csproj_files_matcher, "package"..remove_package_parser, "reference"..remove_reference_parser, "--help"}, {
    "package"..remove_package_parser,
    "reference"..remove_reference_parser,
    "--help", -- "-h"
}):loop(1)


-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-list-reference
local list_parser = parser({
    "reference",
    "--help", -- "-h"
}):loop(1)

-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-nuget-delete?tabs=netcore21
local nuget_delete_parser = parser({
    "--force-english-output",
    "--help", -- "-h"
    "--api-key"..parser({""}),
    "--no-service-endpoint",
    "--non-interactive",
    "--source"..parser({"http://www.nuget.org", "http://www.nuget.org/api/v3", "http://www.nuget.org/api/v2/package", "%hostname%/api/v3"}),
}):loop(1)

-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-nuget-locals
local nuget_locals_parser = parser({
    "all",
    "http-cache",
    "global-packages",
    "temp",
    "--help", -- "-h"
}):loop(1)

nuget_locals_parser:set_flags("--force-english-output", "--help", "-h", "--clear", "-c", "--list", "-l")

-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-nuget-push?tabs=netcore21
local nuget_push_parser = parser({matchers.dirs}, {
    "--disable-buffering",
    "--force-english-output",
    "--help", -- "-h"
    "--api-key"..parser({""}), -- "-k",
    "--no-symbols",
    "--no-service-endpoint",
    "--source"..parser({"http://www.nuget.org", "http://www.nuget.org/api/v3", "http://www.nuget.org/api/v2/package", "%hostname%/api/v3"}),
    "--symbol-api-key"..parser({""}), -- "-sk",
    "--symbol-source"..parser({""}), -- "-ss",
    "--timeout"..parser({"0", "60", "300", "600"}), -- "-t",
}):loop(1)

nuget_locals_parser:set_flags("--force-english-output", "--help", "-h", "--clear", "-c", "--list", "-l")

local nuget_parser = parser({
    "delete"..nuget_delete_parser,
    "locals"..nuget_locals_parser,
    "push"..nuget_push_parser,
    "--help", -- "-h"
}):loop(1)

-- Configuring HTTPS in ASP.NET Core 2.1
-- https://asp.net-hacker.rocks/2018/07/05/aspnetcore-ssl.html
-- 套件位址: https://www.nuget.org/packages/dotnet-dev-certs
local dev_certs_parser = parser({
    "https"..flags({
        "--export-path"..parser({matchers.dirs}),
        "--password",
        "--check",
        "--clean",
        "--trust",
        "--verbose",
        "--quiet",
        "--help",
    }):loop(1),
    "--help", -- "-h"
}):loop(1)

-- EF Core.NET 命令列工具
-- https://docs.microsoft.com/zh-tw/ef/core/miscellaneous/cli/dotnet
local ef_database_parser = parser({
    "drop"..parser({
        "--force",
        "--dry-run",
        "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
        "--project"..parser({csproj_files_matcher}),
        "--startup-project"..parser({csproj_files_matcher}),
        "--framework"..parser({get_framework_list}), -- "-f",
        "--configuration"..parser({"Debug", "Release"}),
        "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
        "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
        "--no-build",
        "--help", -- "-h"
        "--verbose",
        "--no-color",
        "--prefix-output",
    }):loop(1),
    "update"..flags({
        "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
        "--project"..parser({csproj_files_matcher}),
        "--startup-project"..parser({csproj_files_matcher}),
        "--framework"..parser({get_framework_list}), -- "-f",
        "--configuration"..parser({"Debug", "Release"}),
        "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
        "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
        "--no-build",
        "--help", -- "-h"
        "--verbose",
        "--no-color",
        "--prefix-output",
    }):loop(1),
    "--help", -- "-h"
    "--verbose",
    "--no-color",
    "--prefix-output",
}):loop(1)
local ef_dbcontext_parser = parser({
    "info"..flags({
        "--json",
        "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
        "--project"..parser({csproj_files_matcher}),
        "--startup-project"..parser({csproj_files_matcher}),
        "--framework"..parser({get_framework_list}), -- "-f",
        "--configuration"..parser({"Debug", "Release"}),
        "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
        "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
        "--no-build",
        "--help", -- "-h"
        "--verbose",
        "--no-color",
        "--prefix-output",
    }):loop(1),
    "list"..flags({
        "--json",
        "--project"..parser({csproj_files_matcher}),
        "--startup-project"..parser({csproj_files_matcher}),
        "--framework"..parser({get_framework_list}), -- "-f",
        "--configuration"..parser({"Debug", "Release"}),
        "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
        "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
        "--no-build",
        "--help", -- "-h"
        "--verbose",
        "--no-color",
        "--prefix-output",
    }):loop(1),
    "scaffold"..parser({
        "Server=(localdb)\\MSSQLLocalDB;Database=DBName;Trusted_Connection=True;MultipleActiveResultSets=true"..parser({
            "Microsoft.EntityFrameworkCore.SqlServer"..flags({
                "--data-annotations", -- "-d"
                "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
                "--context-dir"..parser({matchers.dirs}),
                "--force",
                "--output-dir"..parser({matchers.dirs}),
                "--schema"..parser({""}),
                "--table"..parser({""}),
                "--use-database-names",
                "--json",
                "--project"..parser({csproj_files_matcher}),
                "--startup-project"..parser({csproj_files_matcher}),
                "--framework"..parser({get_framework_list}), -- "-f",
                "--configuration"..parser({"Debug", "Release"}),
                "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
                "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
                "--no-build",
                "--help", -- "-h"
                "--verbose",
                "--no-color",
                "--prefix-output",
            })
        })
    }):loop(1),
    "--help", -- "-h"
    "--verbose",
    "--no-color",
    "--prefix-output",
}):loop(1)
local ef_migrations_parser = parser({
    "add"..parser({"MigrationName"}, {
        "--output-dir"..parser({matchers.dirs}),
        "--json",
        "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
        "--project"..parser({csproj_files_matcher}),
        "--startup-project"..parser({csproj_files_matcher}),
        "--framework"..parser({get_framework_list}), -- "-f",
        "--configuration"..parser({"Debug", "Release"}),
        "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
        "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
        "--no-build",
        "--help", -- "-h"
        "--verbose",
        "--no-color",
        "--prefix-output",
    }):loop(1),
    "list"..parser({
        "--json",
        "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
        "--project"..parser({csproj_files_matcher}),
        "--startup-project"..parser({csproj_files_matcher}),
        "--framework"..parser({get_framework_list}), -- "-f",
        "--configuration"..parser({"Debug", "Release"}),
        "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
        "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
        "--no-build",
        "--help", -- "-h"
        "--verbose",
        "--no-color",
        "--prefix-output",
    }):loop(1),
    "remove"..parser({
        "--force",
        "--json",
        "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
        "--project"..parser({csproj_files_matcher}),
        "--startup-project"..parser({csproj_files_matcher}),
        "--framework"..parser({get_framework_list}), -- "-f",
        "--configuration"..parser({"Debug", "Release"}),
        "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
        "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
        "--no-build",
        "--help", -- "-h"
        "--verbose",
        "--no-color",
        "--prefix-output",
    }):loop(1),
    "script"..parser({
        "--output"..parser({matchers.files}),
        "--idempotent", -- "-i"
        "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
        "--project"..parser({csproj_files_matcher}),
        "--startup-project"..parser({csproj_files_matcher}),
        "--framework"..parser({get_framework_list}), -- "-f",
        "--configuration"..parser({"Debug", "Release"}),
        "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
        "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
        "--no-build",
        "--help", -- "-h"
        "--verbose",
        "--no-color",
        "--prefix-output",
    }):loop(1),
    "--help", -- "-h"
    "--verbose",
    "--no-color",
    "--prefix-output",
}):loop(1)
local ef_parser = parser({
    "database"..ef_database_parser,
    "dbcontext"..ef_dbcontext_parser,
    "migrations"..ef_migrations_parser,
    "--help", -- "-h"
    "--version", -- "-h"
    "--verbose",
    "--no-color",
    "--prefix-output",
}):loop(1)

-- 使用 SQL Server 分散式快取
-- https://docs.microsoft.com/zh-tw/aspnet/core/performance/caching/distributed?view=aspnetcore-2.1#using-a-sql-server-distributed-cache
-- 套件位址: https://www.nuget.org/packages/dotnet-sql-cache/
local sql_cache_parser = parser({
    "create"..parser({
        "Server=(localdb)\\MSSQLLocalDB;Database=DBName;Trusted_Connection=True;MultipleActiveResultSets=true"..parser({
            "dbo"..parser({
                "TableName"
            }),
        }),
        "--help", -- "-h"
        "--verbose",
    }),
    "--help", -- "-h"
    "--version", -- "-h"
    "--verbose",
}):loop(1)


-- https://docs.microsoft.com/zh-tw/aspnet/core/security/app-secrets?view=aspnetcore-2.1&tabs=windows
local user_secrets_parser = parser({
    "clear"..parser({
        "--help", -- "-h"
        "--verbose",
        "--project"..parser({csproj_files_matcher}),
        "--configuration"..parser({"Debug", "Release"}),
        "--id",
    }):loop(1),
    "list"..parser({
        "--help", -- "-h"
        "--json",
        "--verbose",
        "--project"..parser({csproj_files_matcher}),
        "--configuration"..parser({"Debug", "Release"}),
        "--id",
    }):loop(1),
    "remove"..parser({"SecretName"}, {
        "--help", -- "-h"
        "--verbose",
        "--project"..parser({csproj_files_matcher}),
        "--configuration"..parser({"Debug", "Release"}),
        "--id",
    }):loop(1),
    -- 這樣也可以執行
    -- type .\secrets.json | dotnet user-secrets set
    "set"..parser({
        "SecretName"..parser({
            "SecretValue"..parser({
                "--help", -- "-h"
                "--verbose",
                "--project"..parser({csproj_files_matcher}),
                "--configuration"..parser({"Debug", "Release"}),
                "--id",
            }):loop(1)
        })
    }),
    "--help", -- "-h"
    "--version", -- "-h"
    "--verbose",
    "--project"..parser({csproj_files_matcher}),
    "--configuration"..parser({"Debug", "Release"}),
    "--id",
}):loop(1)
local watch_parser = parser({
    "run"..run_parser,
    "test"..test_parser,
    "--help", -- "-h"
    "--project"..parser({csproj_files_matcher}),
    "--quiet", -- "-q"
    "--verbose",
    "--list",
    "--version",
}):loop(1)


-- https://aka.ms/global-tools

local common_global_tools = {
    "PACKAGE_ID", 
    "dotnetsay", 
    -- https://github.com/jerriep/dotnet-outdated
    "dotnet-outdated",
    -- https://github.com/natemcmaster/dotnet-serve
    "dotnet-serve",
}

local tool_parser = parser({
    "list"..parser({
        "--global", "-g",
        "--tool-path"..parser({matchers.dirs}),
        "--help", "-h"
    }):loop(1),
    "install"..parser({common_global_tools,
        "--global", "-g",
        "--tool-path"..parser({matchers.dirs}),
        "--version"..parser({"VERSION"}),
        "--configfile"..parser({nuget_files_matcher, "NuGet.config"}),
        "--add-source"..parser({"ADD_SOURCE"}),
        "--framework"..parser({get_framework_list}), -- "-f",
        "--help", "-h",
        "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"})
    }):loop(1),
    "uninstall"..parser({common_global_tools,
        "--global", "-g",
        "--tool-path"..parser({matchers.dirs}),
        "--help", "-h",
    }):loop(1),
    "update"..parser({common_global_tools,
        "--global", "-g",
        "--tool-path"..parser({matchers.dirs}),
        "--configfile"..parser({nuget_files_matcher, "NuGet.config"}),
        "--add-source"..parser({"ADD_SOURCE"}),
        "--framework"..parser({get_framework_list}), -- "-f",
        "--help", "-h",
        "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
        "--help", -- "-h"
    }):loop(1),
}):loop(1)


local dotnetcli2_parser = parser({
    "new"..new_parser,
    "restore"..restore_parser,
    "build"..build_parser,
    "publish"..publish_parser,
    "run"..run_parser,
    "test"..test_parser,
    "vstest"..vstest_parser,
    "pack"..pack_parser,
    "migrate"..migrate_parser,
    "clean"..clean_parser,
    "sln"..sln_parser,
    "help",
    "store..store_parser",

    "add"..add_parser,
    "remove"..remove_parser,
    "list"..list_parser,

    "nuget"..nuget_parser,

    -- Additional tools
    "dev-certs"..dev_certs_parser,
    "ef"..ef_parser,
    "sql-cache"..sql_cache_parser,
    "user-secrets"..user_secrets_parser,
    "watch"..watch_parser,

    "tool"..tool_parser,
    
})

dotnetcli2_parser:set_flags(
  -- SDK Options:
  "--version",
  "--info",
  "--list-sdks",
  "--list-runtimes",
  "--diagnostics", -- "-d"

  -- Runtime Options:
  "--additionalprobingpath"..parser({matchers.dirs}),
  "--fx-version"..parser({get_framework_list}),
  "--roll-forward-on-no-candidate-fx",
  "--additional-deps"..parser({matchers.dirs})
)


clink.arg.register_parser("dotnet", dotnetcli2_parser)





-- -- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-install-script
-- local install_parser = parser({
--     "-Channel"..parser({"Current", "LTS", "master", "X.Y"}),
--     "-Version"..parser({"latest", "coherent", "X.Y.Z"}),
--     "-InstallDir"..parser({matchers.dirs}),
--     "-Architecture"..parser({"x86", "x64", "auto"}),
--     "-SharedRuntime",
--     "-DryRun",
--     "-NoPath",
--     "-AzureFeed"..parser({"https://dotnetcli.azureedge.net/dotnet"}),
--     "-ProxyAddress",
--     "--verbose",
--     "--help", -- "-h"
-- }):loop(1)
