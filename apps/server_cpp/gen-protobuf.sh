& "protobuf-3.20.3\cmake\build\Release\protoc.exe" `
  -I=proto `
  --cpp_out="tmp\" `
  packet.proto

Get-ChildItem "tmp\*.pb.cc" |
  Rename-Item -NewName { $_.Name -replace '\.pb\.cc$', '.pb.cpp' }

# Fix for cpp file
$protoPath = "proto\packet.proto"
$outDir    = "tmp"

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 1) Read proto, strip comments, collect bool fields
$protoText = [System.IO.File]::ReadAllText($protoPath, $utf8NoBom)
$protoText = [regex]::Replace($protoText, "/\*.*?\*/", "", [System.Text.RegularExpressions.RegexOptions]::Singleline)
$protoText = [regex]::Replace($protoText, "//.*?$", "", [System.Text.RegularExpressions.RegexOptions]::Multiline)

$boolFields = [regex]::Matches($protoText, "(?m)\bbool\s+([A-Za-z_][A-Za-z0-9_]*)\s*=") |
  ForEach-Object { $_.Groups[1].Value } |
  Sort-Object -Unique

if (-not $boolFields -or $boolFields.Count -eq 0) { throw "No bool fields found in $protoPath" }

Write-Host "Bool fields found:" ($boolFields -join ", ")

# 2) Patch generated pb.cpp files + normalize line endings to CRLF
Get-ChildItem -Path $outDir -Filter "*.pb.cpp" -File | ForEach-Object {
  $file = $_.FullName
  $text = [System.IO.File]::ReadAllText($file, $utf8NoBom)
  $original = $text

  foreach ($f in $boolFields) {
    $member = "${f}_"
    $pattern = "(?m)(\b" + [regex]::Escape($member) + "\s*=\s*)::PROTOBUF_NAMESPACE_ID::internal::ReadVarint64\(&ptr\)\s*;"
    $replacement = "`$1(::PROTOBUF_NAMESPACE_ID::internal::ReadVarint64(&ptr) != 0);"
    $text = [regex]::Replace($text, $pattern, $replacement)
  }

  if ($text -ne $original) {
    # Normalize ALL newline variants -> CRLF
    $text = [regex]::Replace($text, "\r\n|\n|\r", "`r`n")
    [System.IO.File]::WriteAllText($file, $text, $utf8NoBom)
    Write-Host "Patched+Normalized: $file"
  } else {
    Write-Host "No changes: $file"
  }
}


Move-Item tmp\* "proto\" -Force



  