param(
  [string]$DataDir = "data",
  [string]$Mode = "smpl"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Set-Location (Join-Path $PSScriptRoot "..")

function Resolve-FullPath($Path) {
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Path))
}

$DataRoot = Resolve-FullPath $DataDir
$Mode = $Mode.ToLowerInvariant()
if ($Mode -notin @("smpl", "smplx")) {
  throw "Unknown mode '$Mode'. Use 'smpl' or 'smplx'."
}

function New-Directory($Path) {
  if ($Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Join-DataPath([string[]]$Parts) {
  $path = $DataRoot
  foreach ($part in $Parts) {
    $path = Join-Path $path $part
  }
  return $path
}

function Test-FileMinimum($Path, [int64]$MinBytes) {
  if (-not (Test-Path -LiteralPath $Path)) {
    return $false
  }
  return ((Get-Item -LiteralPath $Path).Length -ge $MinBytes)
}

function Test-AllFiles([object[]]$Specs) {
  foreach ($spec in $Specs) {
    if (-not (Test-FileMinimum $spec.OutFile $spec.MinBytes)) {
      return $false
    }
  }
  return $true
}

function Show-Skip($Name) {
  Write-Host "[skip] $Name is already complete."
}

function Read-PlainPassword($Prompt) {
  $secure = Read-Host -Prompt $Prompt -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  }
  finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

function Read-Account($Name) {
  Write-Host ""
  Write-Host "Please register at $Name before continuing."
  $username = Read-Host -Prompt "Username"
  $password = Read-PlainPassword "Password"
  @{ username = $username; password = $password }
}

function New-DownloadSpec($Domain, $SFile, $OutFile, [int64]$MinBytes) {
  @{
    Domain = $Domain
    SFile = $SFile
    OutFile = $OutFile
    MinBytes = $MinBytes
  }
}

function Invoke-PostDownload($Spec, $Account) {
  if (Test-FileMinimum $Spec.OutFile $Spec.MinBytes) {
    $len = (Get-Item -LiteralPath $Spec.OutFile).Length
    Write-Host ("[skip] {0} ({1:N0} bytes)" -f $Spec.OutFile, $len)
    return
  }

  if (Test-Path -LiteralPath $Spec.OutFile) {
    $len = (Get-Item -LiteralPath $Spec.OutFile).Length
    Write-Host ("[replace] {0} is only {1:N0} bytes; downloading again." -f $Spec.OutFile, $len)
    Remove-Item -Force -LiteralPath $Spec.OutFile
  }

  New-Directory (Split-Path $Spec.OutFile -Parent)
  $url = "https://download.is.tue.mpg.de/download.php?domain=$($Spec.Domain)&sfile=$($Spec.SFile)"
  Write-Host "[download] $($Spec.SFile)"
  Write-Host "           -> $($Spec.OutFile)"
  Invoke-WebRequest `
    -Uri $url `
    -Method Post `
    -Body @{ username = $Account.username; password = $Account.password } `
    -OutFile $Spec.OutFile `
    -MaximumRedirection 10 `
    -UseBasicParsing

  if (-not (Test-Path -LiteralPath $Spec.OutFile)) {
    throw "Downloaded file does not exist: $($Spec.OutFile)"
  }

  $downloadedBytes = (Get-Item -LiteralPath $Spec.OutFile).Length
  Write-Host ("[saved] {0:N0} bytes" -f $downloadedBytes)
  if ($downloadedBytes -lt $Spec.MinBytes) {
    throw "Downloaded file is smaller than expected minimum $($Spec.MinBytes) bytes. This usually means an authentication, license, or server error page was downloaded instead of the real file: $($Spec.OutFile)"
  }
}

function Invoke-AccountDownloads($Name, $AccountUrl, [object[]]$Specs) {
  if (Test-AllFiles $Specs) {
    Show-Skip $Name
    return
  }

  $account = Read-Account $AccountUrl
  foreach ($spec in $Specs) {
    Invoke-PostDownload $spec $account
  }
}

function Expand-ZipIfNeeded($Archive, $Destination, $ExpectedPath) {
  if (Test-Path -LiteralPath $ExpectedPath) {
    Write-Host "[skip] Extracted files already exist: $ExpectedPath"
    return
  }
  New-Directory $Destination
  Write-Host "[extract] $Archive"
  Expand-Archive -Force -LiteralPath $Archive -DestinationPath $Destination
}

function Ensure-CameraHMRSmplDemo {
  $specs = @(
    New-DownloadSpec "camerahmr" "SMPL_NEUTRAL.pkl" (Join-DataPath @("models", "SMPL", "SMPL_NEUTRAL.pkl")) 1000000
    New-DownloadSpec "camerahmr" "cam_model_cleaned.ckpt" (Join-DataPath @("pretrained-models", "cam_model_cleaned.ckpt")) 1000000
    New-DownloadSpec "camerahmr" "camerahmr_checkpoint_cleaned.ckpt" (Join-DataPath @("pretrained-models", "camerahmr_checkpoint_cleaned.ckpt")) 10000000
    New-DownloadSpec "camerahmr" "model_final_f05665.pkl" (Join-DataPath @("pretrained-models", "model_final_f05665.pkl")) 10000000
    New-DownloadSpec "camerahmr" "smpl_mean_params.npz" (Join-DataPath @("smpl_mean_params.npz")) 1000
  )
  Invoke-AccountDownloads "CameraHMR SMPL demo files" "https://camerahmr.is.tue.mpg.de/" $specs
}

function Ensure-Bedlam2Checkpoint {
  $specs = @(
    New-DownloadSpec "bedlam2" "checkpoints/camerahmr/bedlam_v1_v2.ckpt" (Join-DataPath @("pretrained-models", "bedlam_v1_v2.ckpt")) 10000000
  )
  Invoke-AccountDownloads "BEDLAM2 SMPL-X checkpoint" "https://bedlam2.is.tue.mpg.de/" $specs
}

function Ensure-SmplxLockedHead {
  $archive = Join-DataPath @("models", "smplx_lockedhead_20230207.zip")
  $expected = Join-DataPath @("models", "smplx_neutral_head", "models_lockedhead", "smplx")
  $specs = @(
    New-DownloadSpec "smplx" "smplx_lockedhead_20230207.zip" $archive 1000000
  )
  Invoke-AccountDownloads "SMPL-X locked-head model" "https://smpl-x.is.tue.mpg.de/" $specs
  Expand-ZipIfNeeded $archive (Join-DataPath @("models", "smplx_neutral_head")) $expected
}

Write-Host "[fetch] Downloading CameraHMR demo data"
Write-Host "[fetch] Data directory: $DataRoot"
Write-Host "[fetch] Mode: $Mode"

Ensure-CameraHMRSmplDemo
if ($Mode -eq "smplx") {
  Ensure-Bedlam2Checkpoint
  Ensure-SmplxLockedHead
}

Write-Host ""
Write-Host "[fetch] Done."
Write-Host "[fetch] Data directory: $DataRoot"
