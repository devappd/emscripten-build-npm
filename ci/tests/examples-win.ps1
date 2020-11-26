Write-Output @"
########################################################################
# tests\examples-win.ps1
#
# For each example project, install emscripten-build, then build,
# then check if *.js and *.wasm exist in ./dist
########################################################################
"@

# Windows can't find NPM without the full path.
#
# At this point, Travis has called NVS and added the Node location
# as the first element in PATH. The PATH is consistent between
# PowerShell and Bash.
if ($env:APPVEYOR -eq $true) {
    # If AppVeyor, then the PATH is already set
    $nodePath = ""
    $commit="$env:APPVEYOR_REPO_COMMIT"
} else {
    $nodePath = "$("$env:PATH".Split(";")[0])\"
    $commit="$env:TRAVIS_COMMIT"
}

# Assumes package.json value https://github.com/marcolovescode/emscripten-build-npm/archive/master.tar.gz
$EMSCRIPTEN_BUILD_SEARCH = "master.tar.gz"
$EMSCRIPTEN_BUILD_REPLACE = "$commit.tar.gz"

Write-Host @"
########################################################################
# Setting up tests...
########################################################################
"@

$failed = $false
$passCount = 0

$examples = @(
    "Example-01-HelloWorld",
    "Example-04-CMake",
    "Example-05-Library"
)

Start-Process -FilePath 'git' -ArgumentList ('clone','https://github.com/marcolovescode/emscripten-npm-examples') -Wait -NoNewWindow

Set-Location .\emscripten-npm-examples
$testRepoRoot = (Get-Location).Path

foreach ($example in $examples) {
    Write-Output @"
########################################################################
# BUILD TEST - $example
########################################################################
"@

    Set-Location "$testRepoRoot\$example"

    # Replace dependency in package.json
    $packageJson = "$testRepoRoot\$example\package.json"
    (Get-Content "$packageJson" -Raw).replace("$EMSCRIPTEN_BUILD_SEARCH", "$EMSCRIPTEN_BUILD_REPLACE") | Set-Content "$packageJson"

    # Clean the committed build output folder
    Remove-Item -Recurse -Force .\dist\*
    
    # Node 11.x does not have npm.ps1, so run CMD
    Start-Process -FilePath 'cmd.exe' -ArgumentList ("/c", "$($nodePath)npm.cmd", 'install', '--emsdk="C:\emsdk"') -Wait -NoNewWindow
    Start-Process -FilePath 'cmd.exe' -ArgumentList ("/c", "$($nodePath)npm.cmd", 'run', 'build') -Wait -NoNewWindow

    # Count build outputs
    $countJs = (Get-ChildItem .\dist\*.js | measure).Count
    $countWasm = (Get-ChildItem .\dist\*.wasm | measure).Count
    $hasArtifacts = ($countJs -eq 1 -and $countWasm -eq 1)

    Write-Output ""
    Write-Output "Build Output"
    Get-ChildItem .\dist

    If ($hasArtifacts -eq $true) {
        $message = "BUILD PASSED!"
        $passCount++
    } else {
        $message = "BUILD FAILED!"
        $failed = $true
    }

    Write-Output @"
########################################################################
# $message $example
########################################################################
"@
}

If ($failed -eq $true) {
    Write-Output @"
########################################################################
# BUILD FAILED! ($passCount/$($examples.Count))
# Check above to see which build failed.
########################################################################
"@
    # fail Travis build
    exit 1
} Else {
    Write-Output @"
########################################################################
# ALL BUILDS PASSED! ($passCount/$($examples.Count))
########################################################################
"@
    exit 0
}
