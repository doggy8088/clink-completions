local matchers = require('matchers')
local w = require('tables').wrap
local parser = clink.arg.new_parser

local sln_files_matcher = matchers.create_files_matcher("*.sln")
local csproj_files_matcher = matchers.create_files_matcher("*.csproj")
local nuget_files_matcher = matchers.create_files_matcher("*.config")
local dll_files_matcher = matchers.create_files_matcher("*.dll")

local function parser_flags(p, ...)
    p:set_flags(...)
    return p
end

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
        "netstandard1.0", "netstandard1.1", "netstandard1.2", "netstandard1.3", "netstandard1.4", "netstandard1.5", "netstandard1.6",
        "netstandard2.0", "netstandard2.1",
        "netcoreapp1.0", "netcoreapp1.1",
        "netcoreapp2.0", "netcoreapp2.1", "netcoreapp2.2", "netcoreapp3.0", "netcoreapp3.1",
        "net48", "net472", "net471", "net47", "net462", "net461", "net46",  "net452", "net451", "net45","net403", "net40",
        "net35", "net20", "net11"
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

local function get_sln_remove_list()
    local res = w()

    local proc = io.popen("dotnet sln list")
    if not proc then
        return res
    end

    local line_number = 1
    for line in proc:lines() do
        if line_number > 2 then
            table.insert(res, line)
        end
        line_number = line_number + 1
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



local new_flags = {
    "--force",
    "--language"..parser({"C#", "F#", "VB"}), -- "--lang",
    "--name", -- "-n",
    "--nuget-source", -- "-s",
    "--output"..parser({matchers.dirs}), "-o"..parser({matchers.dirs}),
    "--install",
    "--uninstall", -- "-u",
    "--type"..parser({"project", "item", "other"}),
    "--dry-run",
    "--list", -- "-l",
    "--update-check",
    "--update-apply",
    "--help"
}

local new_parser = parser({
    "tool-manifes",     -- Dotnet local tool manifest file
    "console"..flags({  -- Console Application
        "--no-restore",
        "--langVersion"..parser({"7.0", "7.1", "7.2", "7.3", "8.0"}),
        table.unpack(new_flags)
    }),
    "winforms"..flags({  -- Windows Forms (WinForms) Application
        "--no-restore",
        "--langVersion"..parser({"7.0", "7.1", "7.2", "7.3", "8.0"}),
        table.unpack(new_flags)
    }),
    "winformslib"..flags({  -- Windows Forms (WinForms) Class library
        "--no-restore",
        "--langVersion"..parser({"7.0", "7.1", "7.2", "7.3", "8.0"}),
        table.unpack(new_flags)
    }),
    "wpf"..flags({  -- WPF Application
        "--no-restore",
        "--langVersion"..parser({"7.0", "7.1", "7.2", "7.3", "8.0"}),
        table.unpack(new_flags)
    }),
    "wpflib"..flags({  -- WPF Class library
        "--no-restore",
        "--langVersion"..parser({"7.0", "7.1", "7.2", "7.3", "8.0"}),
        table.unpack(new_flags)
    }),
    "wpfcustomcontrollib"..flags({  -- WPF Custom Control Library
        "--no-restore",
        "--langVersion"..parser({"7.0", "7.1", "7.2", "7.3", "8.0"}),
        table.unpack(new_flags)
    }),
    "wpfusercontrollib"..flags({  -- WPF User Control Library
        "--no-restore",
        "--langVersion"..parser({"7.0", "7.1", "7.2", "7.3", "8.0"}),
        table.unpack(new_flags)
    }),
    "angular"..flags({  -- ASP.NET Core with Angular
        "--auth"..parser({"None", "Individual"}),
        "--exclude-launch-settings",
        "--use-local-db",
        "--framework"..parser({"netcoreapp3.0", "netcoreapp2.1"}),
        "--no-https",
        "--no-restore",
        table.unpack(new_flags)
    }),
    "vue"..flags({      -- ASP.NET Core with Vue.js
        "--no-restore",
        table.unpack(new_flags)
    }),
    "aurelia"..flags({  -- ASP.NET Core with Aurelia
        "--no-restore",
        table.unpack(new_flags)
    }),
    "Knockout"..flags({ -- ASP.NET Core with Knockout.js
        "--no-restore",
        table.unpack(new_flags)
    }),
    "react"..flags({    -- ASP.NET Core with React.js
        "--auth"..parser({"None", "Individual"}),
        "--exclude-launch-settings",
        "--use-local-db",
        "--framework"..parser({"netcoreapp3.0", "netcoreapp2.1"}),
        "--no-https",
        "--no-restore",
        table.unpack(new_flags)
    }),
    "reactredux"..flags({-- ASP.NET Core with React.js and Redux
        "--exclude-launch-settings",
        "--use-local-db",
        "--framework"..parser({"netcoreapp3.0", "netcoreapp2.1"}),
        "--no-https",
        "--no-restore",
        table.unpack(new_flags)
    }),
    "razorclasslib"..flags({ -- Razor Class Library
        "--support-pages-and-views", "-s",
        "--no-restore",
        table.unpack(new_flags)
    }),
    "classlib"..flags({     -- Class library
        "--no-restore",
        "--framework"..parser({"netcoreapp3.0", "netcoreapp2.1", "netstandard2.1", "netstandard2.0"}),
        "--langVersion"..parser({"7.0", "7.1", "7.2", "7.3", "8.0"}),
        table.unpack(new_flags)
    }),
    "mstest"..flags({       -- Unit Test Project
        "--framework"..parser({"netcoreapp3.0", "netcoreapp2.1", "netstandard2.1", "netstandard2.0"}),
        "--enable-pack", "-p",
        "--no-restore",
        table.unpack(new_flags)
    }),
    "xunit"..flags({        -- xUnit Test Project
        "--framework"..parser({"netcoreapp3.0", "netcoreapp2.1", "netstandard2.1", "netstandard2.0"}),
        "--enable-pack","-p",
        "--no-restore",
        table.unpack(new_flags)
    }),
    "nunit"..flags({        -- NUnit 3 Test Project
        "--framework"..parser({
            "netcoreapp3.0", "netcoreapp2.2", "netcoreapp2.1", "netcoreapp2.0", "netcoreapp1.1", "netcoreapp1.0",
            "net35", "net40", "net45", "net451", "net452", "net46", "net461", "net462", "net47", "net471", "net472", "net48"
        }),
        "--enable-pack","-p",
        "--no-restore",
        table.unpack(new_flags)
    }),
    "nunit-test"..flags({   -- NUnit 3 Test Project
        table.unpack(new_flags)
    }),
    "globaljson"..flags({   -- global.json file
        "--sdk-version"..parser({get_sdk_list}),
        table.unpack(new_flags)
    }),
    "worker"..flags({          -- Worker Service
        "--exclude-launch-settings",
        "--no-restore",
        table.unpack(new_flags)
    }),
    "web"..flags({          -- ASP.NET Core Empty
        "--exclude-launch-settings",
        "--framework"..parser({"netcoreapp3.0", "netcoreapp2.1"}),
        "--no-https",
        "--no-restore",
        table.unpack(new_flags)
    }),
    "webapi"..flags({       -- ASP.NET Core Web API
        "--auth"..parser({"None", "IndividualB2C", "SingleOrg", "Windows"}),
        -- use with IndividualB2C auth
        "--aad-b2c-instance",
        "--susi-policy-id", "-ssp",
        -- use with SingleOrg auth
        "--aad-instance",
        -- use with SingleOrg or IndividualB2C auth
        "--client-id",
        "--domain",
        -- use with SingleOrg auth
        "--tenant-id",
        -- only applies to SingleOrg auth
        "--org-read-access", "-r",

        "--exclude-launch-settings",
        "--use-local-db", "-uld",
        "--framework"..parser({"netcoreapp3.0", "netcoreapp2.1"}),
        "--no-https",
        "--no-restore",
        table.unpack(new_flags)
    }),
    "mvc"..flags({      -- ASP.NET Core Web App (Model-View-Controller)
        "--auth"..parser({"None", "Individual", "IndividualB2C", "SingleOrg", "MultiOrg", "Windows"}),
        -- use with IndividualB2C auth
        "--aad-b2c-instance",
        "--susi-policy-id", "-ssp",
        "--reset-password-policy-id", "-rp",
        "--edit-profile-policy-id", "-ep",
        -- use with SingleOrg or MultiOrg auth
        "--aad-instance",
        -- use with IndividualB2C, SingleOrg or MultiOrg auth
        "--client-id",
        -- use with SingleOrg or IndividualB2C auth
        "--domain",
        "--callback-path", -- Default: /signin-oidc
        -- use with SingleOrg auth
        "--tenant-id",
        -- only applies to SingleOrg or MultiOrg aut
        "--org-read-access", "-r",

        "--exclude-launch-settings",
        "--use-local-db", "-uld",
        "--framework"..parser({"netcoreapp3.0", "netcoreapp2.1"}),
        "--no-https",
        "--no-restore",
        "--use-browserlink",
        table.unpack(new_flags)
    }),
    -- 以前叫做 "razor" (現在還是可以用)
    "webapp"..flags({    -- ASP.NET Core Web App
        "--auth"..parser({"None", "Individual", "IndividualB2C", "SingleOrg", "MultiOrg", "Windows"}),
        -- use with IndividualB2C auth
        "--aad-b2c-instance",
        "--susi-policy-id", "-ssp",
        "--reset-password-policy-id", "-rp",
        "--edit-profile-policy-id", "-ep",
        -- use with SingleOrg or MultiOrg auth
        "--aad-instance",
        -- use with IndividualB2C, SingleOrg or MultiOrg auth
        "--client-id",
        -- use with SingleOrg or IndividualB2C auth
        "--domain",
        "--callback-path", -- Default: /signin-oidc
        -- use with SingleOrg auth
        "--tenant-id",
        -- only applies to SingleOrg or MultiOrg aut
        "--org-read-access", "-r",

        "--exclude-launch-settings",
        "--use-local-db", "-uld",
        "--framework"..parser({"netcoreapp3.0", "netcoreapp2.1"}),
        "--no-https",
        "--no-restore",
        "--use-browserlink",
        table.unpack(new_flags)
    }),
    "mvc"..flags({      -- ASP.NET Core Web App (Model-View-Controller)
        "--auth"..parser({"None", "Individual", "IndividualB2C", "SingleOrg", "MultiOrg", "Windows"}),
        -- use with IndividualB2C auth
        "--aad-b2c-instance",
        "--susi-policy-id", "-ssp",
        "--reset-password-policy-id", "-rp",
        "--edit-profile-policy-id", "-ep",
        -- use with SingleOrg or MultiOrg auth
        "--aad-instance",
        -- use with IndividualB2C, SingleOrg or MultiOrg auth
        "--client-id",
        -- use with SingleOrg or IndividualB2C auth
        "--domain",
        "--callback-path", -- Default: /signin-oidc
        -- use with SingleOrg auth
        "--tenant-id",
        -- only applies to SingleOrg or MultiOrg aut
        "--org-read-access", "-r",

        "--exclude-launch-settings",
        "--use-local-db", "-uld",
        "--framework"..parser({"netcoreapp3.0", "netcoreapp2.1"}),
        "--no-https",
        "--no-restore",
        "--use-browserlink",
        table.unpack(new_flags)
    }),
    "blazorserver"..flags({    -- Blazor Server App
        "--auth"..parser({"None", "Individual", "IndividualB2C", "SingleOrg", "MultiOrg", "Windows"}),
        -- use with IndividualB2C auth
        "--aad-b2c-instance",
        "--susi-policy-id", "-ssp",
        "--reset-password-policy-id", "-rp",
        "--edit-profile-policy-id", "-ep",
        -- use with SingleOrg or MultiOrg auth
        "--aad-instance",
        -- use with IndividualB2C, SingleOrg or MultiOrg auth
        "--client-id",
        -- use with SingleOrg or IndividualB2C auth
        "--domain",
        "--callback-path", -- Default: /signin-oidc
        -- use with SingleOrg auth
        "--tenant-id",
        -- only applies to SingleOrg or MultiOrg aut
        "--org-read-access", "-r",

        "--exclude-launch-settings",
        "--use-local-db", "-uld",
        "--no-https",
        "--no-restore",
        table.unpack(new_flags)
    }),
    "page"..flags({     -- Razor Page
        "--namespace", -- "-na",
        "--no-pagemodel", -- "-np",
        "--no-restore",
        table.unpack(new_flags)
    }),
    "razorcomponent"..flags({   -- Razor Page (C#)
        table.unpack(new_flags)
    }),
    "nugetconfig"..flags({      -- NuGet Config
        table.unpack(new_flags)
    }),
    "viewstart"..flags({        -- Web Config
        table.unpack(new_flags)
    }),
    "viewimports"..flags({        -- Web Config
        "--namespace", "-na", -- Default: MyApp.Namespace
        table.unpack(new_flags)
    }),
    "webconfig"..flags({        -- Web Config
        table.unpack(new_flags)
    }),
    "gitignore"..flags({        -- dotnet gitignore file
        table.unpack(new_flags)
    }),
    "sln"..flags({              -- Solution File
        table.unpack(new_flags)
    }),
    "grpc"..flags({             -- ASP.NET Core gRPC Service
        "--exclude-launch-settings",
        "--no-restore",
        table.unpack(new_flags)
    }),
    "proto"..flags({            -- Protocol Buffer File
        "--namespace", "-na", -- Default: MyApp.Namespace
        table.unpack(new_flags)
    })
})

new_parser:set_flags(table.unpack(new_flags))


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-restore?tabs=netcore2x
local restore_parser = parser({
    matchers.ext_files('*.csproj'), matchers.ext_files('*.sln')
})

local restore_flags = {
    "--configfile"..parser({nuget_files_matcher, "NuGet.config"}),
    "--disable-parallel",
    "--force",
    "--ignore-failed-sources",
    "--no-cache",
    "--no-dependencies",
    "--packages"..parser({matchers.dirs}),
    "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
    "--source", -- "-s",
    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}), "-v"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
	"--interactive",
	"--use-lock-file",
	"--locked-mode",
	"--lock-file-path"..parser({matchers.dirs}),
	"--force-evaluate",
    "--help"
}

restore_parser:set_flags(table.unpack(restore_flags))


local build_server_shutdown_parser = parser({
})

local build_server_shutdown_flags = {
    "--msbuild",
    "--vbcscompiler",
    "--razor",
    "--help"
}

build_server_shutdown_parser:set_flags(table.unpack(build_server_shutdown_flags))

local build_server_parser = parser({
    "shutdown"..build_server_shutdown_parser
})

local build_server_flags = {
    "--help"
}

build_server_parser:set_flags(table.unpack(build_server_flags))


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-build?tabs=netcore2x
local build_parser = parser({
    matchers.ext_files('*.csproj'), matchers.ext_files('*.sln')
})

local build_flags = {
    "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),
    "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
    "--force",
    "--ignore-failed-sources",
    "--no-dependencies",
    "--no-incremental",
	"--nologo",
    "--no-restore",
	"--interactive",
    "--output"..parser({matchers.dirs}), "-o"..parser({matchers.dirs}),
    "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}), "-v"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
    "--version-suffix",
    "--help"
}

build_parser:set_flags(table.unpack(build_flags))


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-publish?tabs=netcore21
local publish_parser = parser({
    matchers.ext_files('*.csproj'), matchers.ext_files('*.sln')
})

local publish_flags = {
    "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),
    "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
    "--force",
    "--manifest"..parser({matchers.files}),
    "--version-suffix",
    "--no-build",
    "--self-contained",
    "--no-self-contained",
    "--nologo",
    "--interactive",
    "--no-restore",
    "--output"..parser({matchers.dirs}), "-o"..parser({matchers.dirs}),
    "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}), "-v"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
    "--no-dependencies",
    "--help"
}

publish_parser:set_flags(table.unpack(publish_flags))

-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-run?tabs=netcore21
local run_parser = parser({
    "--"
})

local run_flags = {
    "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),
    "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
	"-f"..parser({get_framework_list}),
    "--force",
    "--launch-profile"..parser({"Development", "Staging", "Production"}),
    "--no-launch-profile",
    "--no-build",
	"--interactive",
    "--no-restore",
    "--no-dependencies",
    "--project"..parser({matchers.ext_files('*.csproj')}),"-p"..parser({matchers.ext_files('*.csproj')}),
    "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}), "-v"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
    "--help"
}

run_parser:set_flags(table.unpack(run_flags))


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-test?tabs=netcore21
local test_parser = parser({
    matchers.ext_files('*.csproj'), matchers.ext_files('*.sln')
})


local test_flags = {
    "--",

    "--settings"..parser({matchers.files}), "-s"..parser({matchers.files}),

	"--list-tests", "-t",
    "--filter", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-test?tabs=netcore21#filter-option-details

    "--test-adapter-path"..parser({matchers.dirs}),
	"-a"..parser({matchers.dirs}),

    "--logger"..parser({"console", "trx", "html"}),

    "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),

    "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),

	"--runtime",

    "--output"..parser({matchers.dirs}), "-o"..parser({matchers.dirs}),

    "--diag"..parser({matchers.files}),  "-d"..parser({matchers.files}),

    "--no-build",

    "--results-directory"..parser({matchers.dirs}), "-r"..parser({matchers.dirs}),

    "--collect", -- https://aka.ms/vstest-collect
    "--blame",
    "--nologo",

    "--no-restore",
	"--interactive",

    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}), "-v"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
    "--help"
}

test_parser:set_flags(table.unpack(test_flags))



-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-vstest?tabs=netcore21
local vstest_parser = parser({
	matchers.ext_files('*.dll')
}):loop(1)


local vstest_flags = {
    "--",

    "--Settings:"..parser({matchers.files}),
    "--Tests:",
    "--TestCaseFilter:",
    "--TestAdapterPath:"..parser({matchers.dirs}),
    "--Platform:x86",
	"--Platform:x64",
	"--Platform:ARM",
    "--Framework:.NETFramework,Version=v4.6",
    "--Framework:.NETCoreApp,Version=v1.0",
    "--Framework:.NETCoreApp,Version=v1.1",
    "--Framework:.NETCoreApp,Version=v2.0",
    "--Framework:.NETCoreApp,Version=v2.1",
    "--Framework:.NETCoreApp,Version=v2.2",
    "--Framework:.NETCoreApp,Version=v3.0",
	"--Framework:.NETCoreApp,Version=v3.1",
    "--Framework:Framework35",
    "--Framework:Framework40",
    "--Framework:Framework45",
    "--Framework:FrameworkCore10",
    "--Framework:FrameworkUap10",
    "--Parallel",
    "--logger:",
    "--ListTests",
    "--ParentProcessId",
    "--Port",
    "--Diag:",
    "--Blame:",
	"--ResultsDirectory:",
    "--InIsolation",
    "--Help", "-?",
}

vstest_parser:set_flags(table.unpack(vstest_flags))


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-pack?tabs=netcore2x
local pack_parser = parser({
	matchers.ext_files('*.csproj')
})

local pack_flags = {
    "--output"..parser({matchers.dirs}), "-o"..parser({matchers.dirs}),

    "--no-build",
    "--include-symbols",
    "--include-source",

    "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),

    "--version-suffix",
    "--serviceable", -- https://aka.ms/nupkgservicing
    "--nologo",
    "--interactive",
    "--no-restore",

    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}), "-v"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),

    "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
    "--no-dependencies",
    "--force",
    "--help"
}

pack_parser:set_flags(table.unpack(pack_flags))


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-clean?tabs=netcore2x
local clean_parser = parser({
    matchers.ext_files('*.csproj'), matchers.ext_files('*.sln')
})


local clean_flags = {
    "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),
    "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),

    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}), "-v"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),

    "--nologo",
    "--interactive",
    "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
    "--help"
}

clean_parser:set_flags(table.unpack(clean_flags))



-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-sln
local sln_parser = parser({
    matchers.ext_files('*.sln'),
    "add"..parser({matchers.ext_files('*.csproj')}),
    "remove"..parser({get_sln_remove_list}),
    "list"
    }, {
        "add"..parser({matchers.ext_files('*.csproj')}),
        "remove"..parser({get_sln_remove_list}),
        "list"
    })

local sln_flags = {
    "--help"
}

sln_parser:set_flags(table.unpack(sln_flags))


-- https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-store
local store_parser = parser({
})

local store_flags = {
    "--manifest"..parser({matchers.ext_files('*.xml')}),
    "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
    "--framework-version", -- TODO: <FRAMEWORK_VERSION> The Microsoft.NETCore.App package version that will be used to run the assemblies.
    "--runtime",
    "--output"..parser({matchers.dirs}), "-o"..parser({matchers.dirs}),
    "--working-dir"..parser({matchers.dirs}), "-w"..parser({matchers.dirs}),
    "--skip-optimization",
    "--skip-symbols",
    "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}), "-v"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
    "--help"
}

store_parser:set_flags(table.unpack(store_flags))



-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-add-package
local add_package_parser = flags({
    "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
    "--no-restore",
    "--package-directory"..parser({matchers.dirs}),
    "--source"..parser({matchers.dirs}),
    "--interactive",
    "--version",
    "--help"
})

-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-add-reference
local add_reference_parser = parser({
    matchers.dirs
},
    flags({
        "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
        "--interactive",
        "--help"
    })
)

local add_parser = parser({
    matchers.ext_files('*.csproj'),
    "package"..add_package_parser,
    "reference"..add_reference_parser,
    "--help"
}, {
    "package"..add_package_parser,
    "reference"..add_reference_parser,
    "--help"
})


-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-remove-package
local remove_package_parser = flags({
    "--interactive",
    "--help"
})

-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-remove-reference
local remove_reference_parser = parser({matchers.files}, {
    "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
    "--help"
})

local remove_parser = parser({
    matchers.ext_files('*.csproj'),
    "package"..remove_package_parser,
    "reference"..remove_reference_parser,
    "--help"
}, {
    "package"..remove_package_parser,
    "reference"..remove_reference_parser,
    "--help"
})


-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-list-reference
local list_parser = parser({
    matchers.ext_files('*.csproj'), matchers.ext_files('*.sln'),
    "package",
    "reference"
})

local list_flags = {
    "--outdated",
    "--deprecated",
    "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
    "--include-transitive",
    "--include-prerelease",
    "--highest-patch",
    "--highest-minor",
    "--config"..parser({matchers.files}),
    "--source",
    "--interactive",
    "--help"
}

list_parser:set_flags(table.unpack(list_flags))


-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-nuget-delete?tabs=netcore21
local nuget_delete_parser = flags({
    "--force-english-output",
    "--source"..parser({"http://www.nuget.org", "http://www.nuget.org/api/v3", "http://www.nuget.org/api/v2/package", "%hostname%/api/v3"}),
    "--non-interactive",
    "--api-key"..parser({""}),
    "--no-service-endpoint",
    "--interactive",
    "--help"
})

-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-nuget-locals
local nuget_locals_parser = parser({
    "all",
    "http-cache",
    "global-packages",
    "temp"
})

local nuget_locals_flags = {
    "--force-english-output",
    "--clear", "-c",
    "--list", "-l",
    "--help"
}

nuget_locals_parser:set_flags(table.unpack(nuget_locals_flags))

-- https://docs.microsoft.com/zh-tw/dotnet/core/tools/dotnet-nuget-push?tabs=netcore21
local nuget_push_parser = parser({matchers.dirs})

local nuget_push_flags = {
    "--force-english-output",
    "--source"..parser({"http://www.nuget.org", "http://www.nuget.org/api/v3", "http://www.nuget.org/api/v2/package", "%hostname%/api/v3"}),
    "--symbol-source"..parser({""}), -- "-ss",
    "--timeout"..parser({"0", "60", "300", "600"}), -- "-t",
    "--api-key"..parser({""}), -- "-k",
    "--symbol-api-key"..parser({""}), -- "-sk",
    "--disable-buffering",
    "--no-symbols",
    "--no-service-endpoint",
    "--interactive",
    "--help"
}

nuget_push_parser:set_flags(table.unpack(nuget_push_flags))

local nuget_parser = parser({
    "delete"..nuget_delete_parser,
    "locals"..nuget_locals_parser,
    "push"..nuget_push_parser
})

local nuget_flags = {
    "--version",
    "--verbosity"..parser({"Debug", "Verbose", "Information", "Minimal", "Warning", "Error"}), "-v"..parser({"Debug", "Verbose", "Information", "Minimal", "Warning", "Error"}),
    "--help"
}

nuget_parser:set_flags(table.unpack(nuget_flags))


-- https://aka.ms/global-tools

local common_global_tools = {
    "PACKAGE_ID",
    "dotnet-aspnet-codegenerator",      -- https://github.com/aspnet/Scaffolding
    "dotnet-ef",                        -- https://github.com/aspnet/EntityFrameworkCore
    "dotnet-format",                    -- https://github.com/dotnet/format
    "dotnet-outdated",                  -- https://github.com/jerriep/dotnet-outdated
    "dotnet-search",                    -- https://github.com/billpratt/dotnet-search
    "dotnet-serve",                     -- https://github.com/natemcmaster/dotnet-serve
    "dotnet-sonarscanner",              -- https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-msbuild/
    "dotnet-sql-cache",                 -- https://docs.microsoft.com/en-us/aspnet/core/performance/caching/distributed?view=aspnetcore-3.0
    "dotnet-suggest",                   -- https://github.com/dotnet/command-line-api/wiki/dotnet-suggest
    "dotnet-t4",                        -- https://github.com/mono/t4
    "dotnet-try",                       -- https://github.com/dotnet/try
    "entityframeworkcore.generator",    -- https://github.com/loresoft/EntityFrameworkCore.Generator
    "microsoft.web.librarymanager.cli", -- https://github.com/aspnet/LibraryManager/wiki/Using-LibMan-CLI
    "dotnetsay"                         -- https://github.com/dotnet/core/tree/master/samples/dotnetsay
}

local tool_parser = parser_flags(parser({
    "list"..flags({
        "--global", "-g",
        "--local",
        "--tool-path"..parser({matchers.dirs}),
        "--help"
    }),
    "restore"..flags({
        "--configfile"..parser({nuget_files_matcher, "NuGet.config"}),
        "--add-source"..parser({"ADD_SOURCE"}),
        "--tool-manifest"..parser({matchers.dirs}),
        "--disable-parallel",
        "--ignore-failed-sources",
        "--no-cache",
        "--interactive",
        "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}), "-v"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
        "--help"
    }),
    "install"..parser_flags(parser({common_global_tools}), {
        "--global", "-g",
        "--local",
        "--tool-path"..parser({matchers.dirs}),
        "--version"..parser({"VERSION"}),
        "--configfile"..parser({nuget_files_matcher, "NuGet.config"}),
        "--add-source"..parser({"ADD_SOURCE"}),
        "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
        "--disable-parallel",
        "--ignore-failed-sources",
        "--no-cache",
        "--interactive",
        "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}), "-v"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
        "--help"
    }),
    "uninstall"..parser_flags(parser({common_global_tools}), {
        "--global", "-g",
        "--local",
        "--tool-path"..parser({matchers.dirs}),
        "--tool-manifest"..parser({matchers.dirs}),
        "--help"
    }),
    "update"..parser_flags(parser({common_global_tools}), {
        "--global", "-g",
        "--local",
        "--tool-path"..parser({matchers.dirs}),
        "--tool-manifest"..parser({matchers.dirs}),
        "--version"..parser({"VERSION"}),
        "--configfile"..parser({nuget_files_matcher, "NuGet.config"}),
        "--add-source"..parser({"ADD_SOURCE"}),
        "--framework"..parser({get_framework_list}),
        "--disable-parallel",
        "--ignore-failed-sources",
        "--no-cache",
        "--interactive",
        "--verbosity"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}), "-v"..parser({"quiet", "minimal", "normal", "detailed", "diagnostic"}),
        "--help"
    }),
}), {
    "--help"
})

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
        "--help"
    }),
    "--help"
})


-- 使用 SQL Server 分散式快取
-- https://docs.microsoft.com/zh-tw/aspnet/core/performance/caching/distributed?view=aspnetcore-2.1#using-a-sql-server-distributed-cache
-- 套件位址: https://www.nuget.org/packages/dotnet-sql-cache/

local sql_cache_create_parser = parser({
    "Server=(localdb)\\MSSQLLocalDB;Database=DBName;Trusted_Connection=True"..parser({
        "dbo"..parser({
            "TableName"
        }),
    })
})

local sql_cache_create_flags = {
    "--verbose",
    "--help"
}

sql_cache_create_parser:set_flags(table.unpack(sql_cache_create_flags))

local sql_cache_parser = parser({
    "create"..sql_cache_create_parser
})

local sql_cache_flags = {
    "--version",
    "--verbose",
    "--help"
}

sql_cache_parser:set_flags(table.unpack(sql_cache_flags))


-- https://docs.microsoft.com/zh-tw/aspnet/core/security/app-secrets?view=aspnetcore-2.1&tabs=windows
local user_secrets_parser = parser({
    "init"..flags({
        "--verbose",
        "--project"..parser({matchers.ext_files('*.csproj')}),
        "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),
        "--id",
        "--help"
    }),
    "clear"..flags({
        "--verbose",
        "--project"..parser({matchers.ext_files('*.csproj')}),
        "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),
        "--id",
        "--help"
    }),
    "list"..flags({
        "--json",
        "--verbose",
        "--project"..parser({matchers.ext_files('*.csproj')}),
        "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),
        "--id",
        "--help"
    }),
    "remove"..parser_flags(
        parser({"SecretName"}),
        {
            "--verbose",
            "--project"..parser({matchers.ext_files('*.csproj')}),
            "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),
            "--id",
            "--help"
        }),
    -- 這樣也可以執行
    -- type .\secrets.json | dotnet user-secrets set
    "set"..parser({
        "SecretName"..parser({
            "SecretValue"..parser({
                "--verbose",
                "--project"..parser({matchers.ext_files('*.csproj')}),
                "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),
                "--id",
                "--help"
            }):loop(1)
        })
    })
})

local user_secrets_flags = {
    "--id",
    "--version",
    "--verbose",
    "--project"..parser({matchers.ext_files('*.csproj')}),
    "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),
    "--help"
}

user_secrets_parser:set_flags(table.unpack(user_secrets_flags))


-- https://docs.microsoft.com/en-us/aspnet/core/tutorials/dotnet-watch?view=aspnetcore-3.0
-- https://github.com/aspnet/AspNetCore/tree/master/src/Tools/dotnet-watch
local watch_parser = parser({
    "run"..run_parser,
    "test"..test_parser,
    "msbuild"
})

local watch_flags = {
    "--project"..parser({matchers.ext_files('*.csproj')}),
    "--quiet", "-q",
    "--verbose", "-v",
    "--list",
    "--version",
    "--help"
}

watch_parser:set_flags(table.unpack(watch_flags))


-- EF Core.NET 命令列工具
-- https://docs.microsoft.com/en-us/ef/core/miscellaneous/cli/dotnet
local ef_database_parser = parser_flags(parser({
    "update"..parser_flags(parser({
        "MigrationName", "0"
        }), {
            "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
            "--project"..parser({matchers.ext_files('*.csproj')}),
            "--startup-project"..parser({csproj_files_matcher}),
            "--framework"..parser({get_framework_list}),
            "--configuration"..parser({"Debug", "Release"}),
            "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
            "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
            "--no-build",
            "--verbose",
            "--no-color",
            "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
            "--help"
    }),
    "drop"..flags({
        "--force",
        "--dry-run",
        "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
        "--project"..parser({matchers.ext_files('*.csproj')}),
        "--startup-project"..parser({csproj_files_matcher}),
        "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
        "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),
        "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
        "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
        "--no-build",
        "--verbose",
        "--no-color",
        "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
        "--help"
    })
}), {
    "--verbose",
    "--no-color",
    "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
    "--help"
})

local ef_dbcontext_parser = parser_flags(parser({
    "info"..flags({
        "--json",
        "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
        "--project"..parser({matchers.ext_files('*.csproj')}),
        "--startup-project"..parser({csproj_files_matcher}),
        "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
        "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),
        "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
        "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
        "--no-build",
        "--verbose",
        "--no-color",
        "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
        "--help"
    }),
    "list"..flags({
        "--json",
        "--project"..parser({matchers.ext_files('*.csproj')}),
        "--startup-project"..parser({csproj_files_matcher}),
        "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
        "--configuration"..parser({"Debug", "Release"}), "-c"..parser({"Debug", "Release"}),
        "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
        "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
        "--no-build",
        "--verbose",
        "--no-color",
        "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
        "--help"
    }),
    "scaffold"..parser({
        "Server=(localdb)\\MSSQLLocalDB;Database=DBName;Trusted_Connection=True;MultipleActiveResultSets=true"..parser_flags(
            parser({ "Microsoft.EntityFrameworkCore.SqlServer" }),
            {
                "--data-annotations", "-d",
                "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
                "--context-dir"..parser({matchers.dirs}),
                "--force", "-f",
                "--output-dir"..parser({matchers.dirs}), "-o"..parser({matchers.dirs}),
                "--schema"..parser({"dbo"}),
                "--table"..parser({""}),
                "--use-database-names",
                "--json",
                "--project"..parser({matchers.ext_files('*.csproj')}),
                "--startup-project"..parser({csproj_files_matcher}),
                "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
                "--configuration"..parser({"Debug", "Release"}),
                "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
                "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
                "--no-build",
                "--verbose",
                "--no-color",
                "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
                "--help"
            }),
        "Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=ORCLCDB.localdomain)));User Id=OT;Password=yourpassword;"..parser_flags(
            parser({ "Oracle.EntityFrameworkCore" }),
            {
                "--data-annotations", "-d",
                "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
                "--context-dir"..parser({matchers.dirs}),
                "--force", "-f",
                "--output-dir"..parser({matchers.dirs}), "-o"..parser({matchers.dirs}),
                "--schema"..parser({"dbo"}),
                "--table"..parser({""}),
                "--use-database-names",
                "--json",
                "--project"..parser({matchers.ext_files('*.csproj')}),
                "--startup-project"..parser({csproj_files_matcher}),
                "--framework"..parser({get_framework_list}), "-f"..parser({get_framework_list}),
                "--configuration"..parser({"Debug", "Release"}),
                "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
                "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
                "--no-build",
                "--verbose",
                "--no-color",
                "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
                "--help"
            })
        })
    }), {
    "--verbose",
    "--no-color",
    "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
    "--help"
})

local ef_migrations_parser = parser_flags(parser({
    "add"..parser_flags(
        parser({"MigrationName"}),
        {
            "--output-dir"..parser({matchers.dirs}),

            "--json",
            "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
            "--project"..parser({matchers.ext_files('*.csproj')}),
            "--startup-project"..parser({csproj_files_matcher}),
            "--framework"..parser({get_framework_list}),
            "--configuration"..parser({"Debug", "Release"}),
            "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
            "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
            "--no-build",
            "--verbose",
            "--no-color",
            "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
            "--help"
        }
    ),
    "list"..flags({
        "--json",
        "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
        "--project"..parser({matchers.ext_files('*.csproj')}),
        "--startup-project"..parser({csproj_files_matcher}),
        "--framework"..parser({get_framework_list}),
        "--configuration"..parser({"Debug", "Release"}),
        "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
        "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
        "--no-build",
        "--verbose",
        "--no-color",
        "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
        "--help"
    }),
    "remove"..parser({
        "--force",

        "--json",
        "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
        "--project"..parser({matchers.ext_files('*.csproj')}),
        "--startup-project"..parser({csproj_files_matcher}),
        "--framework"..parser({get_framework_list}),
        "--configuration"..parser({"Debug", "Release"}),
        "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
        "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
        "--no-build",
        "--verbose",
        "--no-color",
        "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
        "--help"
    }),
    "script"..parser_flags(
        parser({
            "FromName"..parser({"ToName"}),
            "0"..parser({"ToName"})
        }),
        {
            "--output"..parser({matchers.files}), "-o"..parser({matchers.files}),
            "--idempotent", "-i",

            "--context"..parser({get_dbcontext_list}), "-c"..parser({get_dbcontext_list}),
            "--project"..parser({matchers.ext_files('*.csproj')}),
            "--startup-project"..parser({csproj_files_matcher}),
            "--framework"..parser({get_framework_list}),
            "--configuration"..parser({"Debug", "Release"}),
            "--runtime", -- "-r", -- TODO: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
            "--msbuildprojectextensionspath"..parser({matchers.dirs, "obj"}),
            "--no-build",
            "--verbose",
            "--no-color",
            "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
            "--help"
        }
    )
}), {
    "--verbose", "-v",
    "--no-color",
    "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
    "--help"
})

local ef_parser = parser({
    "database"..ef_database_parser,
    "dbcontext"..ef_dbcontext_parser,
    "migrations"..ef_migrations_parser,
})

local ef_flags = {
    "--version",
    "--verbose", "-v",
    "--no-color",
    "--prefix-output", -- https://github.com/aspnet/EntityFrameworkCore/blob/master/src/ef/Reporter.cs#L14
    "--help"
}

ef_parser:set_flags(table.unpack(ef_flags))



local dotnetcli2_parser = parser({
    matchers.ext_files('*.dll'),

    "new"..new_parser,
    "restore"..restore_parser,
    "build"..build_parser,
    "build-server"..build_server_parser,
    "msbuild",  -- TODO: Run Microsoft Build Engine (MSBuild) commands.
    "publish"..publish_parser,
    "run"..run_parser,
    "test"..test_parser,
    "vstest"..vstest_parser,
    "pack"..pack_parser,
    "clean"..clean_parser,
    "sln"..sln_parser,
    "store"..store_parser,
    "tool"..tool_parser,

    "add"..add_parser,
    "remove"..remove_parser,
    "list"..list_parser,

    "nuget"..nuget_parser,

    -- Additional tools
    "dev-certs"..dev_certs_parser,
    "sql-cache"..sql_cache_parser,
    "user-secrets"..user_secrets_parser,
    "watch"..watch_parser,

    "ef"..ef_parser,

    "help"
})

dotnetcli2_parser:set_flags(
  -- SDK Options:
  "--version",
  "--info",
  "--list-sdks",
  "--list-runtimes",
  "--diagnostics", "-d",

  -- Runtime Options:
  "--additionalprobingpath"..parser({matchers.dirs}),
  "--additional-deps"..parser({matchers.dirs}),
  "--fx-version"..parser({get_framework_list}),
  "--roll-forward"..parser({"LatestPatch", "Minor", "LatestMinor", "Major", "LatestMajor", "Disable"})
)

clink.arg.register_parser("dotnet", dotnetcli2_parser)
