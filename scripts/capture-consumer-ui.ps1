param([Parameter(Mandatory=$true)][ValidatePattern('^[a-z0-9-]+$')][string]$Name)
$ErrorActionPreference = 'Stop'
$hdcPath = 'D:\Coding\IDEs\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
$reviewDir = Join-Path $PSScriptRoot '../output/consumer-review'
New-Item -ItemType Directory -Force -Path $reviewDir | Out-Null
& $hdcPath -t 127.0.0.1:5555 shell uitest dumpLayout -p /data/local/tmp/consumer-review.json | Out-Null
& $hdcPath -t 127.0.0.1:5555 file recv /data/local/tmp/consumer-review.json (Join-Path $reviewDir "$Name.json") | Out-Null
& $hdcPath -t 127.0.0.1:5555 shell snapshot_display -f /data/local/tmp/consumer-review.jpeg | Out-Null
& $hdcPath -t 127.0.0.1:5555 file recv /data/local/tmp/consumer-review.jpeg (Join-Path $reviewDir "$Name.jpeg") | Out-Null
function Show-ConsumerNode($node) {
  if ($node.attributes.text -or $node.attributes.type -eq 'TextInput' -or $node.attributes.type -eq 'Search') {
    $node.attributes | Select-Object text,type,bounds
  }
  foreach ($child in $node.children) { Show-ConsumerNode $child }
}
$tree = Get-Content (Join-Path $reviewDir "$Name.json") -Raw | ConvertFrom-Json
Show-ConsumerNode $tree
