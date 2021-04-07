# https://github.com/majkinetor/posh/blob/master/MM_Admin/Invoke-Environment.ps1
function Invoke-Environment {
    param (
        # Any cmd shell command, normally a configuration batch file.
        [Parameter(Mandatory = $true)]
        [string] $Command
    )
    $Command = "`"" + $Command + "`""
    cmd /c "$Command >nul 2>&1 && set" | . { process {
            if ($_ -match '^([^=]+)=(.*)') {
                [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
            }
        } }
}

if ($null -eq $Env:VSCMD_VER) {
    $VsInstallDir = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community"
    Invoke-Environment "$VsInstallDir\VC\Auxiliary\Build\vcvars64.bat"
}

$BasePath = $PSScriptRoot;
$RepositoryPath = "$BasePath\.";

if (!(Test-Path "$RepositoryPath\bin")) {
    New-Item -Path $RepositoryPath -Name "bin" -ItemType Directory
}
"Win32", "x64" | ForEach-Object {
    $Platform = $_
    if (!(Test-Path "$RepositoryPath\bin\$Platform-build")) {
        New-Item -Path "$RepositoryPath\bin" -Name "$Platform-build" -ItemType Directory
    }
    Set-Location "$RepositoryPath\bin\$Platform-build"
    Write-Host "Running CMake for Platform $Platform"
    $Cmake = Start-Process "cmake" -ArgumentList "-G ""Visual Studio 16 2019"" -A $Platform ""$RepositoryPath"" -D MSVC_RUNTIME=dll" -PassThru -Wait -NoNewWindow
    $ExitCode = $Cmake.ExitCode
    Write-Host "CMake ExitCode $ExitCode"
    if ($ExitCode -ne 0) {
        throw "Failed to run CMake, Platform $Platform"
    }
    if (!(Test-Path "$RepositoryPath\bin\$Platform")) {
        New-Item -Path "$RepositoryPath\bin" -Name "$Platform" -ItemType Directory
    }
    Set-Location $BasePath
    "Debug", "Release" | ForEach-Object {
        $Configuration = $_
        Write-Host "Running CMake build for Configuration $Configuration, Platform $Platform"
        $Cmake = Start-Process "cmake" -ArgumentList "--build ""bin\$Platform-build"" --config $Configuration" -PassThru -Wait -NoNewWindow
        $ExitCode = $Cmake.ExitCode
        Write-Host "CMake ExitCode $ExitCode"
        if ($ExitCode -ne 0) {
            throw "Failed to run CMake build, Configuration $Configuration, Platform $Platform"
        }
        if (!(Test-Path "$RepositoryPath\bin\$Platform\$Configuration")) {
            New-Item -Path "$RepositoryPath\bin\$Platform" -Name "$Configuration" -ItemType Directory
        }
        $Source = "$RepositoryPath\bin\$Platform-build"
        $Destination = "$RepositoryPath\bin\$Platform\$Configuration"
        $Files = @("libwebm.lib")
        if($Configuration -eq "Debug") {
            $Files += @("libwebm.pdb")
        }
        $Files | ForEach-Object {
            Copy-Item "$Source\$Configuration\$_" -Destination $Destination
        }
        if($Configuration -eq "Debug") {
            $Files = @("mkvmuxer.pdb")
            $Files | ForEach-Object {
                Copy-Item "$Source\mkvmuxer.dir\$Configuration\$_" -Destination $Destination
            }
        }
    }
}

Set-Location $BasePath
Start-Process "git" -ArgumentList "log -32 --pretty=oneline" -PassThru -Wait -NoNewWindow -WorkingDirectory "$RepositoryPath" -RedirectStandardOutput "bin\git-log.txt"
