param(
    # overwrite upstream param
    [String]$upstream = "caoli5288/scoop-bucket:master"
)

if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Convert-Path (scoop prefix scoop) }
$autopr = "$env:SCOOP_HOME/bin/auto-pr.ps1"
$dir = "$PSScriptRoot/../bucket" # checks the parent dir
& $autopr -Dir $dir -Upstream $Upstream @Args
