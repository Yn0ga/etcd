#Requires -Version 5.0
# param (
#     [Parameter(Mandatory = $true)]
#     [String]
#     [ValidateNotNullOrEmpty()]
#     $Version
# )
$ErrorActionPreference = 'Stop'

Import-Module -WarningAction Ignore -Name "$PSScriptRoot\utils.psm1"


function Build {
    # [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Version,
        [parameter()]
        [string]
        $BuildPath,
        [parameter()]
        [string]
        $Commit,
        [parameter()]
        [string]
        $Output        
    )
    $linkFlags = '-s -w -gcflags=all=-dwarf=false -extldflags "-static"'

    if ($env:DEBUG) {
        $linkFlags = '-v -gcflags=all="-N -l"'
        Write-Host ('Debug flag passed, changing ldflags to {0}' -f $linkFlags)
        # go install github.com/go-delve/delve/cmd/dlv@latest
    }

    $linkerFlags = ('{0} -X=go.etcd.io/etcd/pkg/defaults.GitSHA={1}' -f $linkerFlags, $Commit)
    if ($env:DEBUG){
        Write-Host "[DEBUG] Running command: go build -o $Output -ldflags $linkerFlags $BuildPath"
    }
    go build -o $Output -ldflags $linkerFlags $BuildPath
    if (-Not $?) {
        Write-LogFatal "go build for $BuildPath failed!"
    }
}

trap {
    Write-Host -NoNewline -ForegroundColor Red "[ERROR]: "
    Write-Host -ForegroundColor Red "$_"

    Pop-Location
    exit 1
}

Invoke-Script -File "$PSScriptRoot\version.ps1"

$SRC_PATH = (Resolve-Path "$PSScriptRoot\..\..").Path
Push-Location $SRC_PATH
if ($env:DEBUG) {
    Write-Host "[DEBUG] Build Path: $SRC_PATH"
}

# Remove-Item -Path "$SRC_PATH\bin\*.exe" -Force -ErrorAction Ignore
$null = New-Item -Type Directory -Path bin -ErrorAction Ignore
$env:GOARCH = $env:ARCH
$env:GOOS = 'windows'
$env:CGO_ENABLED = 0

Build -BuildPath "server/main.go" -Commit $env:COMMIT -Output "..\bin\etcd.exe" -Version $env:VERSION
Build -BuildPath "etcdctl/main.go" -Commit $env:COMMIT -Output "..\bin\etcdctl.exe" -Version $env:VERSION

Pop-Location
