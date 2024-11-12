Set-StrictMode -Version latest

class CSVMaker {
    static [System.Object[]]$ALIGNMENTS = @('top', 'right', 'bottom', 'left', 'center', 'top-right', 'top-left', 'bottom-right', 'bottom-left')

    hidden static [string] randString([int32]$charsCount) {
        return @(0..$charsCount | % { [char](Get-Random -Minimum 65 -Maximum 90) }) -join ''
    }

    hidden static [float] randPosition([int32]$min, [int32]$max) {
        [float]$randNum = (Get-Random -Minimum 0 -Maximum 9999) / 100
        return ("{0:N2}" -f $randNum)
    }

    hidden static [System.Object]generateRow([int32]$index) {
        return [ordered]@{
            id             = $index
            article_number = (Get-Random -Minimum 1000 -Maximum 9999)
            name           = [string]::Concat([CSVMaker]::randString(3), '-', (Get-Random -Minimum 1000 -Maximum 9999))
            x              = [CSVMaker]::randPosition(5, 99)
            y              = [CSVMaker]::randPosition(5, 99)
            z              = [CSVMaker]::randPosition(5, 99)
            jig_name       = [string]::Concat((Get-Random -Minimum 1000 -Maximum 9999), '_', ([CSVMaker]::randString(7)) )
            alignment      = [CSVMaker]::ALIGNMENTS[(Get-Random -Minimum 0 -Maximum ([CSVMaker]::ALIGNMENTS.Count))]
        }
    }

    hidden static [string] generateTextContent($rowsCount) {
        $firstRow = [CSVMaker]::generateRow(0)
        $csvText = "$($firstRow.Keys -join ',')`n$($firstRow.Values -join ',')`n"
        for ($i = 1; $i -lt $rowsCount; $i++) {
            $textRow = [CSVMaker]::generateRow($i).Values -join ','
            $csvText = [string]::Concat($csvText, $textRow, "`n")
        }
        return $csvText
    }

    static [void] generateData([int32]$rowsCount, [string]$path) {
        $text = [CSVMaker]::generateTextContent($rowsCount)
        [void](New-Item $path -Force)
        $text >> $path
    }
}

function generateCsvData([int32]$rows, [string]$path) {
    [CSVMaker]::generateData(100, $path)
}