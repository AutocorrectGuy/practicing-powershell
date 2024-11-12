Set-StrictMode -version latest

function merge([System.Collections.ArrayList]$left, [System.Collections.ArrayList]$right) {
  $arr = [System.Collections.ArrayList]::new()
  [int32]$i, [int32]$j = 0

  while (($i -lt $left.Count) -and ($j -lt $right.Count)) {
    if ($left[$i] -lt $right[$j]) { [void]$arr.Add($left[$i++]) } 
    else { [void]$arr.Add($right[$j++]) }
  }
  while ($i -lt $left.Count) { [void]$arr.Add($left[$i++]) }
  while ($j -lt $right.Count) { [void]$arr.Add($right[$j++]) }

  return $arr
}

function mergeSort([System.Collections.ArrayList]$arr) {
  if ($arr.Count -lt 2) { return ,$arr } 
  
  [int32]$center = [System.Math]::Floor($arr.Count / 2)
  $left = mergeSort -arr ([System.Collections.ArrayList]::new($arr[0..($center - 1)]))
  $right = mergeSort -arr ([System.Collections.ArrayList]::new($arr[$center..($arr.Count - 1)]))

  return merge -left $left -right $right
}

$inputs = [System.Collections.ArrayList]::new((0..20 | %{ Get-Random -Minimum (-99) -Maximum 99 }))
$output = mergeSort -arr $inputs

Write-Host "Input:  $inputs"
Write-Host "Output: $output"
