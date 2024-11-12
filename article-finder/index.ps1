Set-StrictMode -Version latest
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Import-Module './generateCsvData.psm1'

class Utils {
  static [int] center([int]$parentSize, [int]$elementSize) {
    return ($parentSize - $elementSize) -shr 1
  }
}

class WindowForm {
  $form

  WindowForm() {
    $this.form = New-Object System.Windows.Forms.Form
    $this.form.Text = 'Find Article'
    $this.form.Size = New-Object System.Drawing.Size -ArgumentList 1300, 800
    # [System.Windows.Forms.FormStartPosition]::CenterScreen = 1
    $this.form.StartPosition = 1
  }

  [void] open() {
    $this.form.ShowDialog()
    $this.form.Dispose()
  }
}

class NavigationTop {    
  $size
  [DropdownButton]$dropdownButton
  $form
  $panel
  [Input]$input

  NavigationTop($appInstance) {
    $this.form = $appInstance.form
    $this.size = New-Object System.Drawing.Size -ArgumentList $this.form.Width, 32
       
    # Panel
    $this.panel = New-Object System.Windows.Forms.Panel
    $this.panel.Size = $this.size
    $this.panel.Location = New-Object System.Drawing.Point -ArgumentList 0, 0
    $this.panel.BackColor = '#1e293b'
    $appInstance.form.Controls.Add($this.panel)

    # Input field
    $inputSize = New-Object System.Drawing.Size -ArgumentList 200, 20
    $inputPos = New-Object System.Drawing.Point -ArgumentList ([Utils]::center($this.size.Width, $inputSize.Width)), ([Utils]::center($this.size.Height, $inputSize.Height))
    $this.input = [Input]::new($inputSize, $inputPos, $appInstance)
    $this.panel.Controls.Add($this.input.textBox)

    # dropdown button
    $dropdownButtonSize = New-Object System.Drawing.Size -ArgumentList 100, 22
    $dropdownButtonPos = New-Object System.Drawing.Point -ArgumentList ($this.input.textBox.Right + 10), ([Utils]::center($this.size.Height, $dropdownButtonSize.Height))
    $this.dropdownButton = [DropdownButton]::new(
      $dropdownButtonSize,
      $dropdownButtonPos,
      $appInstance
    )
    $this.panel.Controls.Add($this.dropdownButton.button)
  }
}

class Input {
  $textBox
  [App] $appInstance

  Input(
    $size,
    $pos,
    $appInstance
  ) {
    $that = $this
    $this.appInstance = $appInstance
    $this.textBox = New-Object System.Windows.Forms.TextBox
    $this.textBox.Size = $size
    $this.textBox.Location = $pos

    #styles
    $this.textBox.BackColor = '#1e293b'
    $this.textBox.ForeColor = '#bae6fd'

    # enable select all on ctrl + a
    $this.textBox.Add_KeyDown({
        if (($_.Control) -and ($_.KeyCode -eq 'A')) {
          $this.SelectAll()
          # Mark event as handled to remove beep sound
          $_.Handled = $true
          $_.SuppressKeyPress = $true
        }
        # [System.Windows.Forms.Keys]::Escape
        if ($_.KeyCode -eq 27) {
          # Mark event as handled to remove beep sound
          $_.Handled = $true
          $_.SuppressKeyPress = $true
        }
      })
   
    # add change event listener and attach handler
    $this.textBox.add_TextChanged({ $that.filterEntries() }.GetNewClosure())
  }

  [void] filterEntries() {
    [string]$inputText = $this.textBox.Text
    [string]$entryText = ''
    $this.appInstance.foundArticlesIds.Clear()

    for ($i = 0; $i -lt $this.appInstance.csvData.count; $i++) {
      $entryText = $this.appInstance.csvData[$i].($this.appInstance.selectedColumn)
      if ($entryText -match ".*$($inputText).*") {
        $id = $this.appInstance.csvData[$i].id
        $this.appInstance.foundArticlesIds.Add($id)
      }
    }
    $this.appInstance.table.RefreshTable()
  }
}

class DropdownButton {
  $button
  $menu
  [App]$appInstance

  DropdownButton(
    $size,
    $pos,
    [App]$appInstance
  ) {
    $that = $this
    $this.appInstance = $appInstance
    $this.button = New-Object System.Windows.Forms.Button
    $this.button.Text = $this.appInstance.selectedColumn
    $this.button.Size = $size
    $this.button.Location = $pos

    # Create a ContextMenuStrip (dropdown menu)
    $this.menu = New-Object System.Windows.Forms.ContextMenuStrip

    # add menu items
    $this.appInstance.columnNames.ForEach({
        $columnName = $_
        $menuItem = $that.menu.Items.Add($columnName)
        $menuItem.Add_Click({
            $that.appInstance.selectedColumn = $columnName
            $that.button.Text = $columnName
          }.GetNewClosure())

        # add styles
        $menuItem.BackColor = '#0284c7'
        $menuItem.ForeColor = '#e0f2fe'
      })

    $this.button.Add_Click({ $that.menu.Show($that.button, (New-Object System.Drawing.Point -ArgumentList 0, 0)) }.GetNewClosure())

    # add styles
    $this.button.BackColor = '#0284c7'
    $this.button.ForeColor = '#e0f2fe'
  }
}

class Table {
  [App]$appInstance
  $dataGridView
  $panel

  Table(
    [App]$appInstance,
    $pos,
    $size
  ) {
    $this.appInstance = $appInstance
    $this.initializeTableLayout($pos, $size)
    $this.RenderData()
  }

  [void] initializeTableLayout($pos, $size) {
    $this.panel = New-Object System.Windows.Forms.Panel
    $this.panel.Size = $size
    $this.panel.Location = $pos
    $this.dataGridView = New-Object System.Windows.Forms.DataGridView
    # [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill = 6
    # [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize = 2
    $this.dataGridView.AutoSizeColumnsMode = 16
    $this.dataGridView.ColumnHeadersHeightSizeMode = 2
    # 16 px offset for scrollbar width
    $this.dataGridView.Size = New-Object System.Drawing.Size -ArgumentList ($this.panel.Size.Width - 16), $this.panel.Size.Height
    $this.dataGridView.AllowUserToAddRows = $false
    $this.panel.Controls.Add($this.dataGridView)
    $this.appInstance.form.Controls.Add($this.panel)
  }

  [void] RefreshTable() {
    $this.dataGridView.Rows.Clear()
    $this.dataGridView.Columns.Clear()
    #populates data, adds rows
    $this.RenderData()
  }

  [void] RenderData() {
    # Clear existing columns and rows before adding new data
    $this.dataGridView.Columns.Clear()
    $this.dataGridView.Rows.Clear()

    # Render table headers
    foreach ($header in $this.appInstance.columnNames) {
      $null = $this.dataGridView.Columns.Add($header, $header)
    }

    # Render table rows based on found IDs
    foreach ($id in $this.appInstance.foundArticlesIds) {
      # Find the row in csvData where the ID matches
      $row = $this.appInstance.csvData | Where-Object { $_.id -eq $id }
       
      if ($row) {
        # Prepare the row values based on the column names
        $values = @()
        foreach ($header in $this.appInstance.columnNames) {
          $value = if ($row.PSObject.Properties[$header]) { $row.$header } else { $null }
          $values += $value
        }
        $this.dataGridView.Rows.Add($values)
      }
    }
  }
}

class App {
  # articles data
  [string]$csvDataPath
  [System.Collections.IEnumerable]$csvData
  [System.Collections.ArrayList]$columnNames
  [System.Collections.ArrayList]$foundArticlesIds
  [int]$MAX_ROWS = 40 #TODO: add pagination
  [string]$selectedColumn


  # form layout
  [WindowForm]$windowForm
  $form
  [NavigationTop]$navigationTop
  [Table]$table
   
  App([string]$csvDataPath) {
    # Read (or generate and read) csv content 
    if(-not (Test-Path $csvDataPath)) {
      generateCsvData -rows 100 -path $csvDataPath
    }
    $this.csvData = Import-Csv -Path $csvDataPath

    # Store column names from the first row
    $this.columnNames = [System.Collections.ArrayList]::new()
    if ($this.csvData.Count -gt 0) {
      $this.columnNames.AddRange($this.csvData[0].PSObject.Properties.Name)
      # select 1st column
      $this.selectedColumn = $this.columnNames[0]
    }

    # store found article ids in array. Initially store them all (till ceiling value)
    # TODO: implement pagination. That's why I there is a ceiling value
    $this.foundArticlesIds = [System.Collections.ArrayList]::new()
    $visibleRowsCount = [math]::Min($this.MAX_ROWS, $this.csvData.Count)
    for ($i = 0; $i -lt $visibleRowsCount; $i++) {
      $this.foundArticlesIds.Add($this.csvData[$i].ID)
    }
       
    # prepare form
    $this.windowForm = [WindowForm]::new()
    $this.form = $this.windowForm.form
    $this.navigationTop = [NavigationTop]::new($this)
    $this.table = [Table]::new(
      $this,
      (New-Object System.Drawing.Point -ArgumentList 0, $this.navigationTop.panel.Height),
      (New-Object System.Drawing.Size -ArgumentList $this.form.Width, ($this.form.Height - $this.navigationTop.panel.Height))
    )  
  }

  [void] run() {
    $this.windowForm.open()
  }
}

$app = [App]::new('./data.csv')
$app.run()