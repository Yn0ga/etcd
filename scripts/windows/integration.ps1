#Requires -Version 5.0

$ErrorActionPreference = 'Stop'

Import-Module -WarningAction Ignore -Name "$PSScriptRoot\scripts\windows\utils.psm1"

$SRC_PATH = (Resolve-Path "$PSScriptRoot\..").Path
Push-Location $SRC_PATH

Invoke-Expression -Command "$SRC_PATH\tests\integration\integration_suite_test.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-LogFatal "integration test failed"
    exit $LASTEXITCODE
}

Pop-Location
