 <#
    .SYNOPSIS

        This script runs a GUI to interact with the Atomic Red Team Invoke-AtomicRedTeam Powershell Framework (see: https://atomicredteam.io/ )

        Author: Emily Wright ( emily.wright.mi@gmail.com )
		Last updated: July 2020
        Required Dependencies: powershell, yaml, Atomic Red Team Invoke-AtomicRedTeam Powershell Framework

    .PARAMETER AtomicFolderPath

        Specifies the path where Atomic Red Team Invoke-AtomicRedTeam Powershell Framework is installed
		Defualt: $Env:HOMEDRIVE + "\AtomicRedTeam"

    .EXAMPLE

        Run Atomic Red Team GUI
        PS> IART_GUI.ps1 -AtomicFolderPath C:\Users\JohnSmith\AtomicRedTeam

#>

$global:DepHash = @{}
$global:InputHash = @{}
$global:AtomicTest = $null

################################ Event Handling Functions ################################

# Opens file browser to atomics folder and updates text box with selected technique
Function ListTechniques ($BoxToUpdate)
{
    $AtomicsBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $AtomicsBrowser.SelectedPath = $AtomicsPath
    $AtomicsBrowser.ShowNewFolderButton = $false
    $AtomicsBrowser.Description = "Browse the atomics folder to select a technique"

    if ($AtomicsBrowser.ShowDialog() -eq "OK")
    {
		$BoxToUpdate.Text = $AtomicsBrowser.SelectedPath.split("\\")[-1]
		$AtomicsBrowser.Dispose()
	} 
	else
    {
		$AtomicsBrowser.Dispose()
		return
    }
}

# Checks whether technqiue name in textbox is listed in atomics folder
Function ValidateTechnique($BoxToValidate)
{
	$ValidTechniques = @()
	Get-ChildItem -Path $AtomicsPath -Recurse -Directory | 
	ForEach-Object {If($_.Name -match '^T\d{4}(-\d{3})?'){$ValidTechniques += $_.Name}}
	return $ValidTechniques.Contains($BoxToValidate.Text)
	
}

# Calls New-AtomicTechnique with parameters from form
Function CreateTech()
{
	try
	{
		$AtomicTech = New-AtomicTechnique -AttackTechnique $AttackTech_TextBox.Text -DisplayName $AttackDispName_TextBox.Text -AtomicTests @($global:AtomicTest)
		$TechniqueFile = $AttackTech_TextBox.Text + ".yaml"
		$FolderPath = Join-Path $AtomicsPath $AttackTech_TextBox.Text 
		$TechExists = Test-Path $FolderPath
		If ($TechExists -eq $false)
		{
		    md $FolderPath
		    $FilePath = New-Item -Path $FolderPath -Name $TechniqueFile
		    $AtomicTech | ConvertTo-Yaml | Out-File $FilePath
            
            Write-Host "Added test " $global:AtomicTest.name " to new attack technique " $AttackTech_TextBox.Text -BackgroundColor Black -ForegroundColor Magenta
		    [System.Windows.Forms.MessageBox]::Show("Added test " + $global:AtomicTest.name + " to new attack technique " + $AttackTech_TextBox.Text, 'Success!')
		    ReturnHome2
		}
		Else
		{
	 	    [System.Windows.Forms.MessageBox]::Show("Technique already exists.`r`nPlease enter a new technique number or add the test to an existing technique.", 'Error')
		}
	}
	catch { [System.Windows.Forms.MessageBox]::Show("Error creating technique: " + $_, 'Error') }
}

# Adds AtomicTest to existing AtomicTechnique by modifying yaml file directly
Function AddToTech()
{
	If (ValidateTechnique($Attack_TextBox2))
	{
		$TechniqueFile = $Attack_TextBox2.Text + ".yaml"
		$FolderPath = Join-Path $AtomicsPath $Attack_TextBox2.Text
		$FilePath = Join-Path $FolderPath $TechniqueFile
		$AtomicTech = Get-Content -Path $FilePath | ConvertFrom-Yaml -Ordered
		$NewAtomicTest = $global:AtomicTest | ConvertTo-Yaml | ConvertFrom-Yaml -Ordered
		$ExistingNames = @()
		$AtomicTech.atomic_tests | ForEach-Object {$ExistingNames += $_.name}

		If ($NewAtomicTest.name -in $ExistingNames)
		{
			[System.Windows.Forms.MessageBox]::Show("Attack technique " + $Attack_TextBox2.Text + "has existing test with name " + $NewAtomicTest.name `
													+ "`r`nPlease return and change the test name or create a new technique", 'Error')
			
		}
		Else
		{
			$AtomicTech.atomic_tests = $AtomicTech.atomic_tests + $NewAtomicTest
			$AtomicTech | ConvertTo-Yaml | Out-File $FilePath
            Write-Host "Added test " $global:AtomicTest.name " to attack technique " $AttackTech_TextBox2.Text -BackgroundColor Black -ForegroundColor Magenta
			[System.Windows.Forms.MessageBox]::Show("Added test " + $NewAtomicTest.name + " to attack technique " + $Attack_TextBox2.Text, 'Success!')
			ReturnHome2
		}
	}
	Else
	{
		[System.Windows.Forms.MessageBox]::Show("Technique does not exist.`r`nPlease browse existing techniques.", 'Error')
	}
}

# Closes AddTest form (which returns focus to NewTest form)
Function ReturnHome2()
{	
    $AtomicTech = $null
    $NewAtomicTest = $null
	$AddTestForm.Dispose()
}

# Resets controls in NewTest form and clears variables
Function ClearTestParameters()
{

    $global:AtomicTest = $null
    $NewTestCmd = ""

	$TestName_TextBox.Text = ""
	$TestDesc_TextBox.Text = ""
	$Input_ListBox.Items.Clear()
	$global:InputHash = @{}
	$Dep_ListBox.Items.Clear()
	$global:DepHash = @{}
	
	$ExecPanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.RadioButton]) {$_.Checked = $false}}
	For ($i=0; $i -le 2; $i++) {$SuppPlats_CheckBox.SetItemChecked($i,$false)}
	$SupportedPlatforms = @()
	
	$Elevation_CheckBox.Checked = $false
	$ExecCmd_TextBox.Text = ""
	$CleanCmd_TextBox.Text = ""
	$ExecSteps_TextBox.Text = ""
	
	ClearInputParameters
	ClearDepParameters
}

# Resets controls in InputPanel and clears variables
Function ClearInputParameters()
{
	$InputName_TextBox.Text = ""
	$InputDesc_TextBox.Text = ""
	$InputDefault_TextBox.Text = ""
	$InputType_ComboBox.SelectedIndex = 0
	$Input1_Hash = @{}
}

# Resets controls in DepPanel and clears variables
Function ClearDepParameters()
{
	$DepDesc_TextBox.Text = ""
	$PrereqCmd_TextBox.Text = ""
	$GetPrereqCmd_TextBox.Text = ""
	$Dep1_Hash = @{}
}

# Reads current attack technique and lists associated tests
Function ListTests()
{
	Param([System.Windows.Forms.ComboBox]$ToUpdate, [System.Windows.Forms.TextBox]$ToRead)
    $ToUpdate.Items.Clear()
    $ToUpdate.Items.Add('All')
    $ToUpdate.SelectedIndex = 0
    
	If (ValidateTechnique($ToRead))
	{	
		$TechniqueFile = $ToRead.Text + ".yaml"
		$FolderPath = Join-Path $AtomicsPath $ToRead.Text
		$FilePath = Join-Path $FolderPath $TechniqueFile
		$CurrentTech = Get-Content -Path $FilePath | ConvertFrom-Yaml -Ordered
		$CurrentTech.atomic_tests | ForEach-Object {[void] $ToUpdate.Items.Add($_.Name)}
		$ToUpdate.SelectedIndex = 0
	}
	
}

# Checks to see if textboxes are filled
Function CheckParameters($required_vars)
{
	foreach ($var in $required_vars)
	{
		if ($var.Text -eq "")
		{
			return $false
		}
	}
	return $true
}

# Fills CreateTest form with parameters from existing test
Function LoadTest()
{
	If (ValidateTechnique($Attack_TextBox3))
	{
		ClearTestParameters
		$TechniqueFile = $Attack_TextBox3.Text + ".yaml"
		$FolderPath = Join-Path $AtomicsPath $Attack_TextBox3.Text
		$FilePath = Join-Path $FolderPath $TechniqueFile
		$AtomicTech = Get-Content -Path $FilePath | ConvertFrom-Yaml -Ordered
		$global:AtomicTest = $AtomicTech.atomic_tests | Where-Object -FilterScript {$_.Name -eq $Test_ComboBox2.Text}
		
		$TestName_TextBox.Text = $global:AtomicTest.Name
		$TestDesc_TextBox.Text = $global:AtomicTest.Description
		$ExecType = $global:AtomicTest.executor.name -Replace "_",""
		$ExecPanel.Controls | ForEach-Object {If (($_ -is [System.Windows.Forms.RadioButton]) -and ($_.Text -eq $ExecType)) {$_.Checked = $true}}
		$SupportedPlatforms = $global:AtomicTest.supported_platforms
		For ($i=0; $i -le 2; $i++) {If ($SupportedPlatforms.Contains($SuppPlats_CheckBox.Items[$i].ToString().ToLower())) {$SuppPlats_CheckBox.SetItemChecked($i,$true)}}
		
		If ($global:AtomicTest.Contains("executor"))
		{
			If ($global:AtomicTest.executor.Contains("command"))
			{
				$ExecCmd_TextBox.Text = $global:AtomicTest.executor.command
			}
			If ($global:AtomicTest.executor.Contains("cleanup_command"))
			{
				$CleanCmd_TextBox.Text = $global:AtomicTest.executor.cleanup_command
			}
			If ($global:AtomicTest.executor.Contains("steps"))
			{
				$ExecSteps_TextBox.Text = $global:AtomicTest.executor.steps
			}
		}
		
		If ($global:AtomicTest.Contains("input_arguments"))
		{
			$global:InputHash = $global:AtomicTest.input_arguments
            $global:InputHash.GetEnumerator() | ForEach-Object {$Input_ListBox.Items.Add($_.Key)}

		}
		If ($global:AtomicTest.Contains("dependencies"))
		{
			$global:AtomicTest.dependencies.GetEnumerator() | ForEach-Object { $global:DepHash.Add($_.description,$_); $Dep_ListBox.Items.Add($_.description) }
		}
		If ($global:AtomicTest.Contains("ExecutorElevationRequired"))
		{
			If ($global:AtomicTest.ExecutorElevationRequired -eq $true)
			{
				$Elevation_CheckBox.Checked = $true
			}
		}
		$global:AtomicTest = $null
		
	}
	Else
	{
		[System.Windows.Forms.MessageBox]::Show("Technique does not exist.`r`nPlease browse existing techniques.", 'Error')
	}

}

# Calls New-AtomicTestInputArgument, New-AtomicTestDependency, and New-AtomicTest with parameters from form
Function CreateTest()
{
	$SupportedPlatforms = @()
	foreach($CheckedPlat in $SuppPlats_CheckBox.CheckedItems)
	{
		$SupportedPlatforms += $CheckedPlat.ToString()
	}
	
	$ExecType = $ExecPanel.Controls | Where-Object -FilterScript {$_.Checked -and $_ -is [System.Windows.Forms.RadioButton]}
	$DepExecType = $DepPanel.Controls | Where-Object -FilterScript {$_.Checked -and $_ -is [System.Windows.Forms.RadioButton]}
	
	[ AtomicInputArgument[] ]$AtomicInputs = @()

	$Inputs_ToCreate = $global:InputHash.GetEnumerator() 
	ForEach ($Input_ToCreate in $Inputs_ToCreate)
	{ 
		If ($Input_ToCreate -ne $null)
		{
		try {$AtomicInputs += New-AtomicTestInputArgument `
				-Name $Input_ToCreate.key `
				-Description $Input_ToCreate.value.description `
				-Type $Input_ToCreate.value.type `
				-Default $Input_ToCreate.value.default}
		catch { [System.Windows.Forms.MessageBox]::Show("Error creating input: " + $_, 'Error'); return }
		}
	}

	[ AtomicDependency[] ]$AtomicDeps = @()

	$Deps_ToCreate = $global:DepHash.GetEnumerator()
	ForEach ($Dep_ToCreate in $Deps_ToCreate)
	{ 
		If ($Dep_ToCreate -ne $null)
		{
		try 
        {
            $AtomicDeps += New-AtomicTestDependency `
				-Description $Dep_ToCreate.Key `
				-PrereqCommand $Dep_ToCreate.value.prereq_command `
				-GetPrereqCommand $Dep_ToCreate.value.get_prereq_command 
        }
		catch { [System.Windows.Forms.MessageBox]::Show("Error creating dependency: " + $_, 'Error'); return }
		}

	}
	
	$NewTestCmd = '$global:AtomicTest = New-AtomicTest `
					-Name $TestName_TextBox.Text `
					-Description $TestDesc_TextBox.Text `
					-SupportedPlatforms $SupportedPlatforms'
	If ($AtomicInputs -ne @())
	{
		$NewTestCmd += ' -InputArguments $AtomicInputs'
	}
	If ($AtomicDeps -ne @())
	{
		$NewTestCmd += ' -Dependencies $AtomicDeps'
	}

	If (CheckParameters(@($TestName_TextBox,$TestDesc_TextBox,$ExecType,$ExecCmd_TextBox)) and ($SupportedPlatforms -ne @()))
	{
		# Option: Executor command
		$NewTestCmd += ' -ExecutorType $ExecType.Text `
				         -ExecutorCommand $ExecCmd_TextBox.Text'

		If ($DepExecType)
		{
			$NewTestCmd += ' -DependencyExecutorType $DepExecType.Text'
		}
		If ($CleanCmd_TextBox.Text)
		{
			$NewTestCmd += ' -ExecutorCleanupCommand $CleanCmd_TextBox.Text'
		}
		If ($Elevation_CheckBox.Checked)
		{
			$NewTestCmd += ' -ExecutorElevationRequired'
		}

		Try { Invoke-Expression $NewTestCmd 
			$NewTestForm.WindowState = 'Minimized'
			AddAtomicTestForm
			$NewTestForm.WindowState = 'Maximized'
		}
		Catch { [System.Windows.Forms.MessageBox]::Show("Error creating test: " + $_, 'Error') }
	}
	ElseIf (CheckParameters(@($TestName_TextBox,$TestDesc_TextBox,$ExecSteps_TextBox)) and ($SupportedPlatforms -ne @()))
	{
		# Option: Executor steps
		$NewTestCmd += ' -ExecutorSteps $ExecSteps_TextBox.text'

		If ($DepExecType)
		{
			$NewTestCmd += ' -DependencyExecutorType $DepExecType.Text'
		}
		If ($CleanCmd_TextBox.Text)
		{
			$NewTestCmd += ' -ExecutorCleanupCommand $CleanCmd_TextBox.Text'
		}
		If ($Elevation_CheckBox.Checked)
		{
			$NewTestCmd += ' -ExecutorElevationRequired'
		}

        $NewTestCmd += '; $global:AtomicTest.executor.name = "manual"'

		Try { Invoke-Expression $NewTestCmd 
			$NewTestForm.WindowState = 'Minimized'
			AddAtomicTestForm
			$NewTestForm.WindowState = 'Maximized'
		}
		Catch { [System.Windows.Forms.MessageBox]::Show("Error creating test: " + $_, 'Error') }
	}
	Else
	{
		[System.Windows.Forms.MessageBox]::Show('Missing required value for creating test', 'Error')
	}
}

# Resets NewTest controls and closes NewTest form (returns focus to Home form)
Function ReturnHome()
{
	ClearTestParameters
	$NewTestForm.Dispose()
}

# Fills Input Panel with information from existing input (can be modified)
Function ShowInput()
{
	If ($Input_ListBox.SelectedItem)
	{
	$InputName = $Input_ListBox.SelectedItem.ToString()

	$InputName_TextBox.Text = $InputName
	$InputDesc_TextBox.Text = $global:InputHash.Item($InputName).description
	$InputType_ComboBox.SelectedItem = $global:InputHash.Item($InputName).type
	$InputDefault_TextBox.Text = $global:InputHash.Item($InputName).default
	}
}

# Adds inputs to hash with parameters from form
# Displays input name in listbox for user convenience
Function AddInput()
{
	if (CheckParameters(@($InputName_TextBox,$InputDesc_TextBox,$InputDefault_TextBox)))
	{
		if (!$Input_ListBox.Items.Contains($InputName_TextBox.Text))
		{
			if ($InputName_TextBox.Text -match '^(?-i:[0-9a-z_]+)$')
			{
					if ($InputType_ComboBox.Text -in @('Path','Url','String','Integer','Float','Override Type'))
					{
					$Input_ListBox.Items.Add($InputName_TextBox.Text)
					
					$Input1_Hash = 
					@{
					description = $InputDesc_TextBox.Text; 
					type = $InputType_ComboBox.Text;
					default = $InputDefault_TextBox.Text
					}
					
					$global:InputHash.Add($InputName_TextBox.Text, $Input1_Hash)
					
					ClearInputParameters
					}
					else
					{
						[System.Windows.Forms.MessageBox]::Show('Input Type must be Path, Url, String, Integer, or Float. Please select a supported type.', 'Error')
					}
			}
			else
			{
				[System.Windows.Forms.MessageBox]::Show('Input name must be lowercase and optionally, contain underscores. Please enter a new name.', 'Error')
			}
		}
		else
		{
			[System.Windows.Forms.MessageBox]::Show('Input with that name already exists. Please enter a new name.', 'Error')
		}
	}
	else
	{
		[System.Windows.Forms.MessageBox]::Show('Missing required value for creating input' , 'Error')
	}
	
}

# Removes selected input from hash
# Removes input name from listbox for user convenience
Function RemoveInput()
{
	$global:InputHash.Remove($Input_ListBox.SelectedItem)
	$Input_ListBox.Items.Remove($Input_ListBox.SelectedItem)
	ClearInputParameters
}

# Updates existing input with values from form
Function UpdateInput()
{
	If ($Input_ListBox.SelectedItem)
	{
	$global:InputHash.Remove($Input_ListBox.SelectedItem)
	$Input_ListBox.Items.Remove($Input_ListBox.SelectedItem)
	}
	AddInput
}

# Fills Dependency Panel with information from existing input (can be modified)
Function ShowDep()
{
	If ($Dep_ListBox.SelectedItem)
	{
	$DepDesc = $Dep_ListBox.SelectedItem.ToString()
	
	$DepDesc_TextBox.Text = $DepDesc
	$PrereqCmd_TextBox.Text = $global:DepHash.Item($DepDesc).prereq_command
	$GetPrereqCmd_TextBox.Text = $global:DepHash.Item($DepDesc).get_prereq_command
	}
}

# Adds dependencies to hash with parameters from form
# Displays dependency description in listbox for user convenience
Function AddDependency()
{
	
	if (CheckParameters(@($DepDesc_TextBox,$PrereqCmd_TextBox,$GetPrereqCmd_TextBox)))
	{
		if (!$Dep_ListBox.Items.Contains($DepDesc_TextBox.Text))
		{
			$Dep_ListBox.Items.Add($DepDesc_TextBox.Text)

			$Dep1_Hash = 
			@{
			description = $DepDesc_TextBox.Text;
			prereq_command = $PrereqCmd_TextBox.Text;
			get_prereq_command = $GetPrereqCmd_TextBox.Text
			}

			$global:DepHash.Add($DepDesc_TextBox.Text, $Dep1_Hash)
			
			ClearDepParameters
		}
		else
		{
			[System.Windows.Forms.MessageBox]::Show('Dependcy with that description already exists. Please enter a new description.', 'Error')
		}
	}
	else
	{
		[System.Windows.Forms.MessageBox]::Show('Missing required value for creating dependency' , 'Error')
	}
}

# Removes selected deoendency from hash
# Removes dependency description from listbox for user convenience
Function RemoveDependency()
{
	$Dep_Hash.Remove($Dep_ListBox.SelectedItem)
	$Dep_ListBox.Items.Remove($Dep_ListBox.SelectedItem)
	ClearDepParameters
}

# Updates existing dependency with values from form
Function UpdateDep()
{
	If ($Dep_ListBox.SelectedItem)
	{
	$global:DepHash.Remove($Dep_ListBox.SelectedItem)
	$Dep_ListBox.Items.Remove($Dep_ListBox.SelectedItem)
	}
	AddDependency
}

# Resets controls in Home form and clears variables
Function ClearHomeParameters()
{
	$Input_DataGridView.Rows.Clear()
	$Test_ComboBox.Items.Clear()
	$Test_ComboBox.Items.Add('All')
	$Test_ComboBox.SelectedIndex = 0
    $Action_ComboBox.SelectedIndex = 0
	
	$global:InputHash = @{}
	$global:DepHash = @{}
	$global:AtomicTest = $null
	$Attack_TextBox.Text = ""
	$InvokeCmd = ""
}

# Prints inputs for selected test to screen to be customized
Function ListInputs()
{
	Param([System.Windows.Forms.TextBox]$ToRead)

	If (ValidateTechnique($ToRead))
	{	
	
		$Input_DataGridView.Rows.Clear()
		$global:InputHash = @{}
		$TechniqueFile = $ToRead.Text + ".yaml"
		$FolderPath = Join-Path $AtomicsPath $ToRead.Text
		$FilePath = Join-Path $FolderPath $TechniqueFile
		$Current_Tech = Get-Content -Path $FilePath | ConvertFrom-Yaml -Ordered
		$Current_Tech.atomic_tests | Where-Object -FilterScript {$_.Name -eq $Test_ComboBox.Text} | ForEach-Object {If ($_.input_arguments) {$global:InputHash += $_.input_arguments}}
		
		foreach($Key in $global:InputHash.Keys)
		{
            Try
            {
			    $Name = $Key
			    $Default = $global:InputHash.Item($Key).default
			    $Input_DataGridView.Rows.Add($Name, $Default)
			    $Input_DataGridView.CommitEdit
            }
            Catch [System.ArgumentException]
            {
                continue
            }
		}

	}
	
}

# Creates customized invoke command, uses new powershell process to run, and prints results to form
Function Invoke()
{
	If (ValidateTechnique($Attack_TextBox))
	{
		$InvokeCmd = ""	
		$InvokeOutput_TextBox.Text = "Calling Invoke Atomic Red Team module on " + $Attack_TextBox.Text + " with parameter " + $Action_ComboBox.Text + "...`r`n`r`n"
		If ($Test_ComboBox.Text -eq 'All')
		{
			If ($Action_ComboBox.Text -eq 'Run')
			{
				$InvokeCmd = 'Invoke-AtomicTest ' + $Attack_TextBox.Text + ' -Confirm:$false ' + `
				" -PathToAtomicsFolder " + $AtomicsPath
			}
			Else
			{
				$InvokeCmd = 'Invoke-AtomicTest ' + $Attack_TextBox.Text + ' -' + $Action_ComboBox.Text + `
				" -PathToAtomicsFolder " + $AtomicsPath
			}
		}
		Else
		{
		 	If ($Action_ComboBox.Text -eq 'Run')
			{
				If ($Input_DataGridView.RowCount -le 1)
				{
					$InvokeCmd = "Invoke-AtomicTest " + $Attack_TextBox.Text + " -TestNames '" + $Test_ComboBox.Text + "'" + `
					" -PathToAtomicsFolder " + $AtomicsPath
				}
				Else
				{
					$InvokeCmd = "Invoke-AtomicTest " + $Attack_TextBox.Text + " -TestNames '" + $Test_ComboBox.Text + "'" + ' -InputArgs $Custom_Inputs' + `
					" -PathToAtomicsFolder " + $AtomicsPath
				}
			}
			Else
			{
				$InvokeCmd = "Invoke-AtomicTest " + $Attack_TextBox.Text + " -TestNames '" + $Test_ComboBox.Text + "' -" + $Action_ComboBox.Text + `
				" -PathToAtomicsFolder " + $AtomicsPath
			}
		}
	
	
		# Builds a string to create a hash table containing custom inputs
		$InputHash_Str = '@{'
		Foreach ($Input_Row in $Input_DataGridView.Rows)
		{
			If (!$Input_Row.IsNewRow)
			{		
				$InputHash_Str += "'" + $Input_Row.Cells[0].Value + "'= '" + $Input_Row.Cells[1].Value + "';"
			}
		}
		$InputHash_Str = $InputHash_Str.SubString(0, $InputHash_Str.Length - 1)
		$InputHash_Str += '}'
		
		$CustomIn_Str = '$Custom_Inputs = ' + "$InputHash_Str"
		
		# Creates final invoke command to be sent to process
		If (($Input_DataGridView.RowCount -le 1) -or ($Test_ComboBox.Text -eq 'All'))
		{
			$FinalInvokeCmd = "Import-Module $ModuleName -Force; $InvokeCmd"
		}
		Else
		{
			$FinalInvokeCmd = "Import-Module $ModuleName -Force; $CustomIn_Str; $InvokeCmd"
		}

        Try
        {
		    # Starts new process to run invoke command
		    $psi = New-object System.Diagnostics.ProcessStartInfo 
		    $psi.CreateNoWindow = $false 
		    $psi.UseShellExecute = $false 
		    $psi.RedirectStandardOutput = $true 
		    $psi.RedirectStandardError = $true 
		    $psi.FileName = "powershell.exe"
		    $psi.Arguments = @("$FinalInvokeCmd")
		    $IARTProcess = New-Object System.Diagnostics.Process 
		    $IARTProcess.StartInfo = $psi 
		    [void]$IARTProcess.Start()
		
		    $InvokeOutput = $IARTProcess.StandardOutput.ReadToEnd()
		    $InvokeError = $IARTProcess.StandardError.ReadToEnd()
		    $IARTProcess.WaitForExit() 
		    If ($output -ne "")
		    {
			    $InvokeOutput = $InvokeOutput -replace "`n", "`r`n"
			    $InvokeOutput_TextBox.Text += $InvokeOutput
		    }
		    Else
		    {
			    $InvokeError = $InvokeError -replace "`n", "`r`n"
			    $InvokeOutput_TextBox.Text += $InvokeError
		    }
            Write-Host "Called Invoke Atomic Red Team module on" $Attack_TextBox.Text "with parameter" $Action_ComboBox.Text -BackgroundColor Black -ForegroundColor Magenta
        }
        Catch{ [System.Windows.Forms.MessageBox]::Show("Attempted $FinalInvokeCmd `r`n`r`n Error: $_", 'Error') }
	}
	Else
	{
		[System.Windows.Forms.MessageBox]::Show("Technique does not exist.`r`nPlease browse existing techniques or create a new test", 'Error')
	}

}

Function NewTest()
{
	ClearHomeParameters
	$InvokeOutput_TextBox.Text = ""
	Import-Module $ModuleName -Force
	CreateAtomicTestForm
}



################################ Add Atomic Test Form ################################
################################ Add Atomic Test Form ################################
################################ Add Atomic Test Form ################################
################################ Add Atomic Test Form ################################

################################ Add Atomic Test Form Main Function ################################

Function AddAtomicTestForm()
{

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$AddTestForm									= New-Object System.Windows.Forms.Form
$AddTestForm.ClientSize							= '1200,300'
$AddTestForm.Text								= "Invoke Atomic Red Team Add Test"
$AddTestForm.AutoScroll							= $true
$AddTestForm.BackColor							= "White"
$AddTestForm.Font								= 'Segoe UI,10'

$NewTechPanel									= New-Object System.Windows.Forms.Panel
$NewTechPanel.Location							= New-Object System.Drawing.Point(10,60)
$NewTechPanel.Size								= New-Object System.Drawing.Size(500,140)

$ModTechPanel									= New-Object System.Windows.Forms.Panel
$ModTechPanel.Location							= New-Object System.Drawing.Point(550,60)
$ModTechPanel.Size								= New-Object System.Drawing.Size(500,140)

$Instr_Label									= New-Object System.Windows.Forms.Label
$Instr_Label.Text								= "Add your custom Atomic Red Team test to a technique..."
$Instr_Label.Location							= New-Object System.Drawing.Point(10,10)

$Or_Label										= New-Object System.Windows.Forms.Label
$Or_Label.Text									= "Or"
$Or_Label.Location								= New-Object System.Drawing.Point(450,50)

$RetHome_Button2								= New-Object System.Windows.Forms.Button
$RetHome_Button2.Text							= "Return"
$RetHome_Button2.Size							= New-Object System.Drawing.Size(150,30)
$RetHome_Button2.Location						= New-Object System.Drawing.Point(870,10)

######## AtomicTechnique Labels ########

$NewTech_Label									= New-Object System.Windows.Forms.Label
$NewTech_Label.Text								= "Add test to new attack technique"
$NewTech_Label.Location							= New-Object System.Drawing.Point(10,10)

$ModTech_Label									= New-Object System.Windows.Forms.Label
$ModTech_Label.Text								= "Add test to existing attack technique"
$ModTech_Label.Location							= New-Object System.Drawing.Point(10,10)

$AttackTech_Label								= New-Object System.Windows.Forms.Label
$AttackTech_Label.Text							= "New Attack Technique"
$AttackTech_Label.Location						= New-Object System.Drawing.Point(10,40)

$AttackTech_Label2								= New-Object System.Windows.Forms.Label
$AttackTech_Label2.Text							= "Attack Technique"
$AttackTech_Label2.Location						= New-Object System.Drawing.Point(10,40)

$AttackDispName_Label							= New-Object System.Windows.Forms.Label
$AttackDispName_Label.Text						= "New Attack Display Name"
$AttackDispName_Label.Location					= New-Object System.Drawing.Point(10,70)

######## AtomicTechnique Interactions ########

$AttackTech_TextBox								= New-Object System.Windows.Forms.TextBox
$AttackTech_TextBox.Size						= New-Object System.Drawing.Size(100,20)
$AttackTech_TextBox.Location					= New-Object System.Drawing.Point(190,35)

$AttackDispName_TextBox							= New-Object System.Windows.Forms.TextBox
$AttackDispName_TextBox.Size					= New-Object System.Drawing.Size(200,20)
$AttackDispName_TextBox.Location				= New-Object System.Drawing.Point(190,65)

$CreateTech_Button								= New-Object System.Windows.Forms.Button
$CreateTech_Button.Text							= "Create technique and add test"
$CreateTech_Button.Size							= New-Object System.Drawing.Size(300,30)
$CreateTech_Button.Location						= New-Object System.Drawing.Point(10,110)

$Attack_TextBox2								= New-Object System.Windows.Forms.TextBox
$Attack_TextBox2.Size							= New-Object System.Drawing.Size(120,20)
$Attack_TextBox2.Location						= New-Object System.Drawing.Point(190,40)

$AtomicsBrowser_Button2							= New-Object System.Windows.Forms.Button
$AtomicsBrowser_Button2.Text					= "Browse"
$AtomicsBrowser_Button2.Size					= New-Object System.Drawing.Size(150,30)
$AtomicsBrowser_Button2.Location				= New-Object System.Drawing.Point(320,35)

$AddToTech_Button								= New-Object System.Windows.Forms.Button
$AddToTech_Button.Text							= "Add test to technique"
$AddToTech_Button.Size							= New-Object System.Drawing.Size(300,30)
$AddToTech_Button.Location						= New-Object System.Drawing.Point(10,110)

$NewTechPanel.controls.AddRange(@($Or_Label,$NewTech_Label,$AttackTech_Label,$AttackDispName_Label,`
										$AttackTech_TextBox,$AttackDispName_TextBox,$CreateTech_Button))
$ModTechPanel.controls.AddRange(@($ModTech_Label,$AttackTech_Label2,$Attack_TextBox2,$AtomicsBrowser_Button2,$AddToTech_Button))
$AddTestForm.Controls.AddRange(@($Instr_Label,$NewTechPanel,$ModTechPanel,$RetHome_Button2))

$NewTechPanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Button]) {$_.BackColor = 'LightSteelBlue'}}
$ModTechPanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Button]) {$_.BackColor = 'LightSteelBlue'}}
$AddTestForm.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Button]) {$_.BackColor = 'LightSteelBlue'}}
$NewTechPanel.Controls  | ForEach-Object {If ($_ -is [System.Windows.Forms.Label]) {$_.Font = 'Segoe UI,10,style=Bold'; $_.AutoSize = $true}}
$ModTechPanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Label]) {$_.Font = 'Segoe UI,10,style=Bold'; $_.AutoSize = $true}}
$AddTestForm.Controls  | ForEach-Object {If ($_ -is [System.Windows.Forms.Label]) {$_.Font = 'Segoe UI,10,style=Bold'; $_.AutoSize = $true}}
$Instr_Label.Font = 'Segoe UI,13,style=Bold'
$Instr_Label.AutoSize = $true
$Or_Label.Font = 'Segoe UI,13,style=Bold'
$Or_Label.AutoSize = $true

################################ Add Atomic Test Form Event Handling ################################

$CreateTech_Button.Add_Click({CreateTech})
$AddToTech_Button.Add_Click({AddToTech})
$RetHome_Button2.Add_Click({ReturnHome2})
$AtomicsBrowser_Button2.Add_Click({ListTechniques($Attack_TextBox2)})

################################ Add Atomic Test Form Activation ################################

$AddTestForm.Add_Shown({$AddTestForm.Activate()}) 
$AddTestForm.ShowDialog()

}

################################ Create Atomic Test Form ################################
################################ Create Atomic Test Form ################################
################################ Create Atomic Test Form ################################
################################ Create Atomic Test Form ################################


################################ Create Atomic Test Form Main Function ################################

Function CreateAtomicTestForm()
{

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

################################ Create Atomic Test Form Style ################################

$NewTestForm                     				= New-Object System.Windows.Forms.Form
$NewTestForm.WindowState         				= 'Maximized'
$NewTestForm.Text                				= "Invoke Atomic Red Team New Test"
$NewTestForm.AutoScroll          				= $true
$NewTestForm.BackColor							= "White"
$NewTestForm.Font								= 'Segoe UI,10'			

$CreateTest_Button								= New-Object System.Windows.Forms.Button
$CreateTest_Button.Text							= "Create Test"
$CreateTest_Button.Size							= New-Object System.Drawing.Size(150,30)
$CreateTest_Button.Location						= New-Object System.Drawing.Point(410,90)

$RetHome_Button									= New-Object System.Windows.Forms.Button
$RetHome_Button.Text							= "Return Home"
$RetHome_Button.Size							= New-Object System.Drawing.Size(150,30)
$RetHome_Button.Location						= New-Object System.Drawing.Point(410,10)

$Clear_Button									= New-Object System.Windows.Forms.Button
$Clear_Button.Text								= "Clear"
$Clear_Button.Size								= New-Object System.Drawing.Size(150,30)
$Clear_Button.Location							= New-Object System.Drawing.Point(410,50)

$TopPanel										= New-Object System.Windows.Forms.Panel
$TopPanel.Location								= New-Object System.Drawing.Point(10,10)
$TopPanel.Size									= New-Object System.Drawing.Size(650,170)

$InputPanel										= New-Object System.Windows.Forms.Panel
$InputPanel.Location							= New-Object System.Drawing.Point(10,180)
$InputPanel.Size								= New-Object System.Drawing.Size(700,200)

$ExecPanel										= New-Object System.Windows.Forms.Panel
$ExecPanel.Location								= New-Object System.Drawing.Point(680,20)
$ExecPanel.Size									= New-Object System.Drawing.Size(700,550)

$DepPanel										= New-Object System.Windows.Forms.Panel
$DepPanel.Location								= New-Object System.Drawing.Point(10,390)
$DepPanel.Size									= New-Object System.Drawing.Size(680,450)

$LoadPanel										= New-Object System.Windows.Forms.Panel
$LoadPanel.Location								= New-Object System.Drawing.Point(680,630)
$LoadPanel.Size									= New-Object System.Drawing.Size(650,400)

######## Load Test Labels ########

$Load_Label										= New-Object System.Windows.Forms.Label
$Load_Label.Text								= "Pre-fill form with parameters from existing test"
$Load_Label.Location							= New-Object System.Drawing.Point(10,10)

$AttackTech_Label4								= New-Object System.Windows.Forms.Label
$AttackTech_Label4.Text							= "Attack Technique"
$AttackTech_Label4.Location						= New-Object System.Drawing.Point(10,50)

$Test_Label2									= New-Object System.Windows.Forms.Label
$Test_Label2.Text								= "Test"
$Test_Label2.Location							= New-Object System.Drawing.Point(10,105)

######## Load Test Interactions ########

$BrowseTest_Button2						        = New-Object System.Windows.Forms.Button
$BrowseTest_Button2.Text				        = "Browse..."
$BrowseTest_Button2.Size				        = New-Object System.Drawing.Size(150,30)
$BrowseTest_Button2.Location			        = New-Object System.Drawing.Point(300,45)

$Attack_TextBox3								= New-Object System.Windows.Forms.TextBox
$Attack_TextBox3.Size							= New-Object System.Drawing.Size(120,20)
$Attack_TextBox3.Location						= New-Object System.Drawing.Point(150,50)

$Test_ComboBox2									= New-Object System.Windows.Forms.ComboBox
$Test_ComboBox2.DropDownStyle					= "DropDownList"
$Test_ComboBox2.Text							= "Select Test"
$Test_ComboBox2.Size							= New-Object System.Drawing.Size(300,20)
$Test_ComboBox2.Location						= New-Object System.Drawing.Point(150,100)

$LoadTest_Button								= New-Object System.Windows.Forms.Button
$LoadTest_Button.Text							= "Load Test"
$LoadTest_Button.Size							= New-Object System.Drawing.Size(150,30)
$LoadTest_Button.Location						= New-Object System.Drawing.Point(10,140)

$About_Label									= New-Object System.Windows.Forms.Label
$About_Label.Text								= "Create custom Atomic Red Team test"
$About_Label.Location							= New-Object System.Drawing.Point(10,10)

######## AtomicTest Labels ########

$TestName_Label									= New-Object System.Windows.Forms.Label
$TestName_Label.Text							= "Test Name"
$TestName_Label.Location						= New-Object System.Drawing.Point(10,50)

$TestDesc_Label									= New-Object System.Windows.Forms.Label
$TestDesc_Label.Text							= "Test Description"
$TestDesc_Label.Location						= New-Object System.Drawing.Point(10,80)

$SuppPlat_Label									= New-Object System.Windows.Forms.Label
$SuppPlat_Label.Text							= "Supported Platforms"
$SuppPlat_Label.Location						= New-Object System.Drawing.Point(180,10)

$ExecType_Label									= New-Object System.Windows.Forms.Label
$ExecType_Label.Text							= "Executor Type"
$ExecType_Label.Location						= New-Object System.Drawing.Point(10,10)

$ExecSteps_Label								= New-Object System.Windows.Forms.Label
$ExecSteps_Label.Text							= "Executor Steps"
$ExecSteps_Label.Location						= New-Object System.Drawing.Point(10,440)

$ExecCmd_Label									= New-Object System.Windows.Forms.Label
$ExecCmd_Label.Text								= "Executor Command"
$ExecCmd_Label.Location							= New-Object System.Drawing.Point(10,140)

$CleanCmd_Label									= New-Object System.Windows.Forms.Label
$CleanCmd_Label.Text							= "Executor Cleanup Command"
$CleanCmd_Label.Location						= New-Object System.Drawing.Point(10,270)

######## AtomicTest Interactions ########

$TestName_TextBox								= New-Object System.Windows.Forms.TextBox
$TestName_TextBox.Multiline						= $false
$TestName_TextBox.Size							= New-Object System.Drawing.Size(500,20)
$TestName_TextBox.Location						= New-Object System.Drawing.Point(150,45)

$TestDesc_TextBox								= New-Object System.Windows.Forms.TextBox
$TestDesc_TextBox.Multiline						= $true
$TestDesc_TextBox.Scrollbars					= 'vertical'
$TestDesc_TextBox.Size							= New-Object System.Drawing.Size(500,90)
$TestDesc_TextBox.Location						= New-Object System.Drawing.Point(150,75)

$SuppPlats_CheckBox								= New-Object System.Windows.Forms.CheckedListBox
$SuppPlats_CheckBox.AutoSize					= $true
$SuppPlats_CheckBox.CheckOnClick				= $true
$SuppPlats_CheckBox.Location					= New-Object System.Drawing.Point(180,40)
@('Windows','macOS','Linux') | ForEach-Object {[void] $SuppPlats_CheckBox.Items.Add($_)}

$Cmd_RadioButton								= New-Object System.Windows.Forms.RadioButton
$Cmd_RadioButton.Text							= "CommandPrompt"
$Cmd_RadioButton.Location						= New-Object System.Drawing.Point(20,40)

$Sh_RadioButton									= New-Object System.Windows.Forms.RadioButton
$Sh_RadioButton.Text							= "Sh"
$Sh_RadioButton.Location						= New-Object System.Drawing.Point(20,60)

$Bash_RadioButton								= New-Object System.Windows.Forms.RadioButton
$Bash_RadioButton.Text							= "Bash"
$Bash_RadioButton.Location						= New-Object System.Drawing.Point(20,80)

$Pow_RadioButton								= New-Object System.Windows.Forms.RadioButton
$Pow_RadioButton.Text							= "PowerShell"
$Pow_RadioButton.Location						= New-Object System.Drawing.Point(20,100)

$Elevation_CheckBox								= New-Object System.Windows.Forms.CheckBox
$Elevation_CheckBox.Text						= "Elevation Required"
$Elevation_CheckBox.AutoSize					= $true
$Elevation_CheckBox.Location					= New-Object System.Drawing.Point(170,140)
$Elevation_CheckBox.Font						= 'Segoe UI,10,style=Bold'

$ExecSteps_TextBox								= New-Object System.Windows.Forms.TextBox
$ExecSteps_TextBox.Multiline					= $true
$ExecSteps_TextBox.Scrollbars					= 'vertical'
$ExecSteps_TextBox.Size							= New-Object System.Drawing.Size(550,80)
$ExecSteps_TextBox.Location						= New-Object System.Drawing.Point(10,470)

$ExecCmd_TextBox								= New-Object System.Windows.Forms.TextBox
$ExecCmd_TextBox.Multiline						= $true
$ExecCmd_TextBox.Scrollbars						= 'vertical'
$ExecCmd_TextBox.Size							= New-Object System.Drawing.Size(550,80)
$ExecCmd_TextBox.Location						= New-Object System.Drawing.Point(10,170)

$CleanCmd_TextBox								= New-Object System.Windows.Forms.TextBox
$CleanCmd_TextBox.Multiline						= $true
$CleanCmd_TextBox.Scrollbars					= 'vertical'
$CleanCmd_TextBox.Location						= New-Object System.Drawing.Point(10,300)
$CleanCmd_TextBox.Size							= New-Object System.Drawing.Size(550,80)

######## AtomicInputArgument Labels ########

$InputArgs_Label								= New-Object System.Windows.Forms.Label
$InputArgs_Label.Text							= "Input Arguments (Optional)"
$InputArgs_Label.Location						= New-Object System.Drawing.Point(10,5)

$InputList_Label								= New-Object System.Windows.Forms.Label
$InputList_Label.Text							= "Input List"
$InputList_Label.Location						= New-Object System.Drawing.Point(500,5)

$InputName_Label								= New-Object System.Windows.Forms.Label
$InputName_Label.Text							= "Name"
$InputName_Label.Location						= New-Object System.Drawing.Point(10,40)

$InputDesc_Label								= New-Object System.Windows.Forms.Label
$InputDesc_Label.Text							= "Description"
$InputDesc_Label.Location						= New-Object System.Drawing.Point(10,70)

$InputType_Label								= New-Object System.Windows.Forms.Label
$InputType_Label.Text							= "Type"
$InputType_Label.Location						= New-Object System.Drawing.Point(10,100)

$InputDefault_Label								= New-Object System.Windows.Forms.Label
$InputDefault_Label.Text						= "Default"
$InputDefault_Label.Location					= New-Object System.Drawing.Point(10,130)

######## AtomicInputArgument Interactions ########

$Input_ListBox									= New-Object System.Windows.Forms.ListBox
$Input_ListBox.AutoSize							= $false
$Input_ListBox.Size								= New-Object System.Drawing.Size(150,130)
$Input_ListBox.Location							= New-Object System.Drawing.Point(500,30)

$InputName_TextBox								= New-Object System.Windows.Forms.TextBox
$InputName_TextBox.Multiline					= $false
$InputName_TextBox.Size							= New-Object System.Drawing.Size(200,20)
$InputName_TextBox.Location						= New-Object System.Drawing.Point(110,35)

$InputDesc_TextBox								= New-Object System.Windows.Forms.TextBox
$InputDesc_TextBox.Multiline					= $false
$InputDesc_TextBox.Size							= New-Object System.Drawing.Size(350,20)
$InputDesc_TextBox.Location						= New-Object System.Drawing.Point(110,65)

$InputType_ComboBox								= New-Object System.Windows.Forms.ComboBox
$InputType_ComboBox.Text						= "Select Type"
$InputType_ComboBox.Size						= New-Object System.Drawing.Size(120,20)
$InputType_ComboBox.Location					= New-Object System.Drawing.Point(110,95)
@('Path','Url','String','Integer','Float') | ForEach-Object {[void] $InputType_ComboBox.Items.Add($_)}
$InputType_ComboBox.SelectedIndex				= 0

$InputDefault_TextBox							= New-Object System.Windows.Forms.TextBox
$InputDefault_TextBox.Multiline					= $false
$InputDefault_TextBox.Size						= New-Object System.Drawing.Size(350,20)
$InputDefault_TextBox.Location					= New-Object System.Drawing.Point(110,125)

$AddInput_Button								= New-Object System.Windows.Forms.Button
$AddInput_Button.Text							= "Add Input"
$AddInput_Button.Size							= New-Object System.Drawing.Size(150,30)
$AddInput_Button.Location						= New-Object System.Drawing.Point(10,160)

$UpdateInput_Button								= New-Object System.Windows.Forms.Button
$UpdateInput_Button.Text						= "Update Input"
$UpdateInput_Button.Size						= New-Object System.Drawing.Size(150,30)
$UpdateInput_Button.Location					= New-Object System.Drawing.Point(170,160)

$RemoveInput_Button								= New-Object System.Windows.Forms.Button
$RemoveInput_Button.Text						= "Remove Input"
$RemoveInput_Button.Size						= New-Object System.Drawing.Size(150,30)
$RemoveInput_Button.Location					= New-Object System.Drawing.Point(500,160)

######## AtomicDependency Labels ########

$Deps_Label										= New-Object System.Windows.Forms.Label
$Deps_Label.Text								= "Dependencies (Optional)"
$Deps_Label.Location							= New-Object System.Drawing.Point(10,0)

$DepList_Label									= New-Object System.Windows.Forms.Label
$DepList_Label.Text								= "Dependency List"
$DepList_Label.Location							= New-Object System.Drawing.Point(260,250)

$DepDesc_Label									= New-Object System.Windows.Forms.Label
$DepDesc_Label.Text								= "Description"
$DepDesc_Label.Location							= New-Object System.Drawing.Point(10,30)

$PrereqCmd_Label								= New-Object System.Windows.Forms.Label
$PrereqCmd_Label.Text							= "Prereq Command"
$PrereqCmd_Label.Location						= New-Object System.Drawing.Point(10,60)

$GetPrereqCmd_Label								= New-Object System.Windows.Forms.Label
$GetPrereqCmd_Label.Text						= "Get Prereq Command"
$GetPrereqCmd_Label.Location					= New-Object System.Drawing.Point(10,150)

$DepExecType_Label								= New-Object System.Windows.Forms.Label
$DepExecType_Label.Text							= "Dependency Executor Type"
$DepExecType_Label.Location						= New-Object System.Drawing.Point(10,250)

######## AtomicDependency Interactions ########

$Dep_ListBox									= New-Object System.Windows.Forms.ListBox
$Dep_ListBox.AutoSize							= $false
$Dep_ListBox.Size								= New-Object System.Drawing.Size(400,100)
$Dep_ListBox.Location							= New-Object System.Drawing.Point(260,280)

$Cmd_RadioButton2								= New-Object System.Windows.Forms.RadioButton
$Cmd_RadioButton2.Text							= "CommandPrompt"
$Cmd_RadioButton2.Location						= New-Object System.Drawing.Point(10,280)

$Sh_RadioButton2								= New-Object System.Windows.Forms.RadioButton
$Sh_RadioButton2.Text							= "Sh"
$Sh_RadioButton2.Location						= New-Object System.Drawing.Point(10,300)

$Bash_RadioButton2								= New-Object System.Windows.Forms.RadioButton
$Bash_RadioButton2.Text							= "Bash"
$Bash_RadioButton2.Location						= New-Object System.Drawing.Point(10,320)

$Pow_RadioButton2								= New-Object System.Windows.Forms.RadioButton
$Pow_RadioButton2.Text							= "PowerShell"
$Pow_RadioButton2.Location						= New-Object System.Drawing.Point(10,340)

$DepDesc_TextBox								= New-Object System.Windows.Forms.TextBox
$DepDesc_TextBox.Multiline						= $false
$DepDesc_TextBox.Size							= New-Object System.Drawing.Size(550,20)
$DepDesc_TextBox.Location						= New-Object System.Drawing.Point(110,25)

$PrereqCmd_TextBox								= New-Object System.Windows.Forms.TextBox
$PrereqCmd_TextBox.Size							= New-Object System.Drawing.Size(650,60)
$PrereqCmd_TextBox.Multiline					= $true
$PrereqCmd_TextBox.Scrollbars					= 'vertical'
$PrereqCmd_TextBox.Location						= New-Object System.Drawing.Point(10,85)


$GetPrereqCmd_TextBox							= New-Object System.Windows.Forms.TextBox
$GetPrereqCmd_TextBox.Size						= New-Object System.Drawing.Size(650,60)
$GetPrereqCmd_TextBox.Multiline					= $true
$GetPrereqCmd_TextBox.Scrollbars				= 'vertical'
$GetPrereqCmd_TextBox.Location					= New-Object System.Drawing.Point(10,175)

$AddDep_Button									= New-Object System.Windows.Forms.Button
$AddDep_Button.Text								= "Add Dependency"
$AddDep_Button.Size								= New-Object System.Drawing.Size(150,30)
$AddDep_Button.Location							= New-Object System.Drawing.Point(10,380)

$UpdateDep_Button								= New-Object System.Windows.Forms.Button
$UpdateDep_Button.Text							= "Update Dependency"
$UpdateDep_Button.Size							= New-Object System.Drawing.Size(150,30)
$UpdateDep_Button.Location						= New-Object System.Drawing.Point(170,380)

$RemoveDep_Button								= New-Object System.Windows.Forms.Button
$RemoveDep_Button.Text							= "Remove Dependency"
$RemoveDep_Button.Size							= New-Object System.Drawing.Size(150,30)
$RemoveDep_Button.Location						= New-Object System.Drawing.Point(510,380)

$TopPanel.controls.AddRange(@($About_Label,$TestName_Label,$TestDesc_Label,$TestName_TextBox,$TestDesc_TextBox))
$ExecPanel.controls.AddRange(@($SuppPlat_Label,$SuppPlats_CheckBox,$Elevation_CheckBox,$Cmd_RadioButton,$Sh_RadioButton,$Bash_RadioButton,$Pow_RadioButton, `
							$ExecCmd_Label,$CleanCmd_Label,$ExecSteps_Label,$ExecType_Label,$ExecCmd_TextBox,$CleanCmd_TextBox,$ExecSteps_TextBox,`
							$CreateTest_Button,$RetHome_Button,$Clear_Button))
$InputPanel.controls.AddRange(@($InputArgs_Label,$InputList_Label,$InputName_Label,$InputDesc_Label,$InputType_Label, `
							$InputDefault_Label,$InputName_TextBox,$InputDesc_TextBox,$InputType_ComboBox, `
							$InputDefault_TextBox,$AddInput_Button,$UpdateInput_Button,$Input_ListBox,$RemoveInput_Button))
$DepPanel.controls.AddRange(@($Deps_Label,$DepList_Label,$DepDesc_Label,$PrereqCmd_Label,$GetPrereqCmd_Label, `
							$DepDesc_TextBox,$PrereqCmd_TextBox,$GetPrereqCmd_TextBox,`
							$DepExecType_Label,$Cmd_RadioButton2,$Sh_RadioButton2,$Bash_RadioButton2,$Pow_RadioButton2, `
							$AddDep_Button,$UpdateDep_Button,$Dep_ListBox,$RemoveDep_Button))
$LoadPanel.controls.AddRange(@($Load_Label,$AttackTech_Label4,$Test_Label2,$Attack_TextBox3,$BrowseTest_Button2, `
							$Test_ComboBox2,$LoadTest_Button))

$NewTestForm.controls.AddRange(@($TopPanel,$ExecPanel,$InputPanel,$DepPanel,$LoadPanel))

$TopPanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Button]) {$_.BackColor = 'LightSteelBlue'}}
$InputPanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Button]) {$_.BackColor = 'LightSteelBlue'}}
$ExecPanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Button]) {$_.BackColor = 'LightSteelBlue'}}
$DepPanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Button]) {$_.BackColor = 'LightSteelBlue'}}
$LoadPanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Button]) {$_.BackColor = 'LightSteelBlue'}}
$NewTestForm.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Button]) {$_.BackColor = 'LightSteelBlue'}}
$TopPanel.Controls  | ForEach-Object {If ($_ -is [System.Windows.Forms.Label]) {$_.Font = 'Segoe UI,10,style=Bold'; $_.AutoSize = $true}}
$InputPanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Label]) {$_.Font = 'Segoe UI,10,style=Bold'; $_.AutoSize = $true}}
$ExecPanel.Controls  | ForEach-Object {If ($_ -is [System.Windows.Forms.Label]) {$_.Font = 'Segoe UI,10,style=Bold'; $_.AutoSize = $true}}
$DepPanel.Controls  | ForEach-Object {If ($_ -is [System.Windows.Forms.Label]) {$_.Font = 'Segoe UI,10,style=Bold'; $_.AutoSize = $true}}
$LoadPanel.Controls  | ForEach-Object {If ($_ -is [System.Windows.Forms.Label]) {$_.Font = 'Segoe UI,10,style=Bold'; $_.AutoSize = $true}}
$NewTestForm_Group.Controls  | ForEach-Object {If ($_ -is [System.Windows.Forms.Label]) {$_.Font = 'Segoe UI,10,style=Bold'; $_.AutoSize = $true}}
$ExecPanel.Controls  | ForEach-Object {If ($_ -is [System.Windows.Forms.RadioButton]) {$_.AutoSize = $true}}
$DepPanel.Controls  | ForEach-Object {If ($_ -is [System.Windows.Forms.RadioButton]) {$_.AutoSize = $true}}
$About_Label.Font = 'Segoe UI,13,style=Bold'
$About_Label.AutoSize = $true

################################ Create Atomic Test Form Event Handling ################################

$CreateTest_Button.Add_Click({CreateTest})
$BrowseTest_Button2.Add_Click({ListTechniques($Attack_TextBox3)})
$Attack_TextBox3.add_TextChanged({ListTests -ToUpdate $Test_ComboBox2 -ToRead $Attack_TextBox3; $Test_ComboBox2.Items.Remove('All'); If ($Test_ComboBox2.Items) {$Test_ComboBox2.SelectedIndex = 0}})
$LoadTest_Button.Add_Click({LoadTest})
$AddInput_Button.Add_Click({AddInput})
$RemoveInput_Button.Add_Click({RemoveInput})
$UpdateInput_Button.Add_Click({UpdateInput})
$Input_ListBox.Add_SelectedIndexChanged({ShowInput})
$AddDep_Button.Add_Click({AddDependency})
$RemoveDep_Button.Add_Click({RemoveDependency})
$UpdateDep_Button.Add_Click({UpdateDep})
$Dep_ListBox.Add_SelectedIndexChanged({ShowDep})
$RetHome_Button.Add_Click({ReturnHome})
$Clear_Button.Add_Click({ClearTestParameters})

################################ Create Atomic Test Form Activation ################################

$NewTestForm.Add_Shown({$NewTestForm.Activate()}) 
$NewTestForm.ShowDialog()

}


################################ Home Form ################################
################################ Home Form ################################
################################ Home Form ################################
################################ Home Form ################################

################################ Home Form Main Function ################################

Function AtomicRedTeamHome()
{

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$HomeForm										= New-Object System.Windows.Forms.Form
$HomeForm.Text									= "Invoke Atomic Red Team"
$HomeForm.AutoScroll							= $true
$HomeForm.StartPosition							= "WindowsDefaultBounds"
$HomeForm.BackColor								= "White"
$HomeForm.Font									= 'Segoe UI,10'

$InvokePanel									= New-Object System.Windows.Forms.Panel
$InvokePanel.Location							= New-Object System.Drawing.Point(10,60)
$InvokePanel.Size								= New-Object System.Drawing.Size(500,240)

$OutputPanel									= New-Object System.Windows.Forms.Panel
$OutputPanel.Location							= New-Object System.Drawing.Point(10,300)
$OutputPanel.Size								= New-Object System.Drawing.Size(1000,600)

$DefaultPanel									= New-Object System.Windows.Forms.Panel
$DefaultPanel.Location							= New-Object System.Drawing.Point(500,40)
$DefaultPanel.Size								= New-Object System.Drawing.Size(500,250)

$Home_Label										= New-Object System.Windows.Forms.Label
$Home_Label.Text								= "Invoke Atomic Red Team test"
$Home_Label.Location							= New-Object System.Drawing.Point(10,10)

# Home form labels #

$AttackTech_Label3								= New-Object System.Windows.Forms.Label
$AttackTech_Label3.Text							= "Attack Technique"
$AttackTech_Label3.Location						= New-Object System.Drawing.Point(10,20)

$Test_Label										= New-Object System.Windows.Forms.Label
$Test_Label.Text								= "Test"
$Test_Label.Location							= New-Object System.Drawing.Point(10,75)

$Action_Label									= New-Object System.Windows.Forms.Label
$Action_Label.Text								= "Action"
$Action_Label.Location							= New-Object System.Drawing.Point(10,135)

$DefaultInput_Label								= New-Object System.Windows.Forms.Label
$DefaultInput_Label.Text						= "Edit default inputs..."
$DefaultInput_Label.Location					= New-Object System.Drawing.Point(10,5)

$Output_Label									= New-Object System.Windows.Forms.Label
$Output_Label.Text								= "Result"
$Output_Label.Location							= New-Object System.Drawing.Point(10,5)

# Home Form Contols #

$NewTest_Button									= New-Object System.Windows.Forms.Button
$NewTest_Button.Text							= "Create new test"
$NewTest_Button.Size							= New-Object System.Drawing.Size(150,30)
$NewTest_Button.Location						= New-Object System.Drawing.Point(760,10)

$BrowseTest_Button								= New-Object System.Windows.Forms.Button
$BrowseTest_Button.Text							= "Browse..."
$BrowseTest_Button.Size							= New-Object System.Drawing.Size(150,30)
$BrowseTest_Button.Location						= New-Object System.Drawing.Point(300,15)

$Invoke_Button									= New-Object System.Windows.Forms.Button
$Invoke_Button.Text								= "INVOKE"
$Invoke_Button.Size								= New-Object System.Drawing.Size(150,30)
$Invoke_Button.Location							= New-Object System.Drawing.Point(10,180)

$Attack_TextBox									= New-Object System.Windows.Forms.TextBox
$Attack_TextBox.Size							= New-Object System.Drawing.Size(120,20)
$Attack_TextBox.Location						= New-Object System.Drawing.Point(150,20)

$Test_ComboBox									= New-Object System.Windows.Forms.ComboBox
$Test_ComboBox.DropDownStyle					= "DropDownList"
$Test_ComboBox.Text								= "Select Test"
$Test_ComboBox.Size								= New-Object System.Drawing.Size(300,20)
$Test_ComboBox.Location							= New-Object System.Drawing.Point(150,70)
[void] $Test_ComboBox.Items.Add('All')
$Test_ComboBox.SelectedIndex					= 0

$Input_DataGridView								= New-Object System.Windows.Forms.DataGridView
$Input_DataGridView.Size						= New-Object System.Drawing.Size(400,150)
$Input_DataGridView.Location					= New-Object System.Drawing.Point(10,30)
$Input_DataGridView.ColumnCount					= 2
$Input_DataGridView.ColumnHeadersVisible		= $true
$Input_DataGridView.Columns[0].Name				= "Name"
$Input_DataGridView.Columns[1].Name				= "Value"
$Input_DataGridView.Columns[0].Width			= 100
$Input_DataGridView.Columns[1].Width			= 257
$Input_DataGridView.Columns[0].ReadOnly			= $true
$Input_DataGridView.BackgroundColor				= "White"

$Action_ComboBox								= New-Object System.Windows.Forms.ComboBox
$Action_ComboBox.DropDownStyle					= "DropDownList"
$Action_ComboBox.Text        	 				= "Select Action"
$Action_ComboBox.Size							= New-Object System.Drawing.Size(120,20)
$Action_ComboBox.Location						= New-Object System.Drawing.Point(150,130)
@('Run','CleanUp', 'CheckPrereqs', 'GetPrereqs', 'ShowDetails', 'ShowDetailsBrief') | ForEach-Object {[void] $Action_ComboBox.Items.Add($_)}
$Action_ComboBox.SelectedIndex					= 0


$InvokeOutput_TextBox							= New-Object System.Windows.Forms.TextBox
$InvokeOutput_TextBox.Multiline					= $true
$InvokeOutput_TextBox.Scrollbars				= 'vertical'
$InvokeOutput_TextBox.Size						= New-Object System.Drawing.Size(900,500)
$InvokeOutput_TextBox.Location					= New-Object System.Drawing.Point(10,30)

$InvokePanel.controls.AddRange(@($AttackTech_Label3,$Test_Label,$Action_Label,$Attack_TextBox,$BrowseTest_Button,`
								$Test_ComboBox,$Action_ComboBox,$Invoke_Button))
$DefaultPanel.controls.AddRange(@($DefaultInput_Label,$Input_DataGridView))
$OutputPanel.controls.AddRange(@($Output_Label,$InvokeOutput_TextBox))
$HomeForm.Controls.AddRange(@($Home_Label,$InvokePanel,$DefaultPanel,$OutputPanel,$NewTest_Button))

$InvokePanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Button]) {$_.BackColor = 'LightSteelBlue'}}
$DefaultPanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Button]) {$_.BackColor = 'LightSteelBlue'}}
$OutputPanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Button]) {$_.BackColor = 'LightSteelBlue'}}
$HomeForm.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Button]) {$_.BackColor = 'LightSteelBlue'}}
$InvokePanel.Controls  | ForEach-Object {If ($_ -is [System.Windows.Forms.Label]) {$_.Font = 'Segoe UI,10,style=Bold'; $_.AutoSize = $true}}
$DefaultPanel.Controls | ForEach-Object {If ($_ -is [System.Windows.Forms.Label]) {$_.Font = 'Segoe UI,10,style=Bold'; $_.AutoSize = $true}}
$OutputPanel.Controls  | ForEach-Object {If ($_ -is [System.Windows.Forms.Label]) {$_.Font = 'Segoe UI,10,style=Bold'; $_.AutoSize = $true}}
$Home_Label.Font = 'Segoe UI,13,style=Bold'
$Home_Label.AutoSize = $true

################################ Home Form Event Handling ################################

$Attack_TextBox.add_TextChanged({ListTests -ToUpdate $Test_ComboBox -ToRead $Attack_TextBox})
$Test_ComboBox.Add_SelectedIndexChanged({If ($Test_ComboBox.Text -ne "All") {ListInputs -ToRead $Attack_TextBox} Else {$Input_DataGridView.Rows.Clear()}})
$BrowseTest_Button.Add_Click({ListTechniques($Attack_TextBox)})
$Invoke_Button.Add_Click({Invoke})
$NewTest_Button.Add_Click({NewTest})

################################ Home Form Activation ################################

$HomeForm.Add_Shown({$HomeForm.Activate()}) 
$HomeRes = $HomeForm.ShowDialog()
$HomeForm.Dispose()

}

################################ Main ################################

Function StartGUI
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory = $False, Position = 0)]
		[string]$AtomicFolderPath = $($env:HOMEDRIVE + "\AtomicRedTeam")
	)

	Try
	{
		Write-Host "Began Invoke-AtomicRedTeam GUI." -BackgroundColor Black -ForegroundColor Cyan

		# Specifies path to atomics, creates atomics folder is it does not exist
		$AtomicsPath = Join-Path $AtomicFolderPath "atomics"
		$atomics_exists = Test-Path $AtomicsPath
		If ($atomics_exists -eq $false)
		{
			Write-Host "Creating empty atomics folder..." -BackgroundColor Black -ForegroundColor Magenta
			mkdir $AtomicsPath
		}
		$ModuleName = Join-Path $AtomicFolderPath "invoke-atomicredteam"
		$ModuleName = Join-Path $ModuleName "Invoke-AtomicRedTeam.psd1"

		# Calls Home form
		AtomicRedTeamHome
		Write-Host "Ended Invoke-AtomicRedTeam GUI." -BackgroundColor Black -ForegroundColor Cyan
	}
	Catch
	{
		Write-Host "Error in Invoke-AtomicRedTeam GUI:" $_ -BackgroundColor Black -ForegroundColor Red
	}
}
