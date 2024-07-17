function Toggle-SleepSetting {
	#Get GUID of active plan
	$string = Invoke-Expression "powercfg /getactivescheme"

	# Define regex pattern to extract GUID
	$pattern = "\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b"

	# Extract GUID using regex
	$GUID = [regex]::Match($string, $pattern).Value
	#Get a list of all options for this plan
	$Options = powercfg /query $GUID
	$index = 0

	#Find index of line that contains Sleep Settings
	For($i=0; $i -lt $Options.Length; $i++)
	{
		$line = $Options[$i]
		if($line.ToLower() -like "*sleep after*")
		{
			$index = $i
			break
		}        
	}

	#AC Setting is 6 lines later
	$sleepSetting = $Options[$index + 6]
	#trim off the beginning of the string, leaving only the value
	$sleepSettingTrimmed = $sleepSetting.Substring($sleepSetting.IndexOf(":")+2)
	$sleepDecimalValue = [convert]::ToInt32($sleepSettingTrimmed, 16)

	$initialSleepValue = $sleepDecimalValue/60;
	
	
	#Find index of line that contains display Settings
	For($i=0; $i -lt $Options.Length; $i++)
	{
		$line = $Options[$i]
		if($line.ToLower() -like "*turn off display after*")
		{
			$index = $i
			break
		}        
	}

	#AC Setting is 6 lines later
	$displaySetting = $Options[$index + 6]
	#trim off the beginning of the string, leaving only the value
	$displaySettingTrimmed = $displaySetting.Substring($displaySetting.IndexOf(":")+2)
	$displayDecimalValue = [convert]::ToInt32($displaySettingTrimmed, 16)
	
	$initialDisplayValue = $displayDecimalValue/60;
	

    # Register an engine event to handle script termination
    Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        Write-Output "Script is being stopped. Restoring initial registry value..."
		powercfg /change monitor-timeout-ac $initialDisplayValue
		powercfg /change standby-timeout-ac $initialSleepValue
    }

    try {
        # Load the required assembly
        Add-Type -AssemblyName System.Windows.Forms


		# Check the current value and toggle it
		if ($initialDisplayValue -gt 0 -and $initialSleepValue -gt 0){
			# Change the value to 0
			powercfg /change monitor-timeout-ac 0  # Set system standby timeout to 0 (never)
			powercfg /change standby-timeout-ac 0  # Set system standby timeout to 0 (never)
			
			[System.Windows.Forms.MessageBox]::Show("Sleep is now disabled. Press OK to re-enable it.", "Temporary Sleep Toggle", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)	
			Write-Host "Sleep is now disabled." -ForegroundColor Red			

			# Continue with the rest of the script
			powercfg /change monitor-timeout-ac $initialDisplayValue
			powercfg /change standby-timeout-ac $initialSleepValue
			
			Write-Host "Sleep is now enabled." -ForegroundColor Green
		} else {
			# Inform that the sleep setting was already disabled
			$result = [System.Windows.Forms.MessageBox]::Show("Sleep was already disabled. This only works when sleep is enabled. Would you like to enable it?", "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

			# Check the user's response
			if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
				Write-Host "Sleep is now enabled. The monitor will turn off after 5 minutes and the PC will go to sleep after 20 minutes." -ForegroundColor Green
				powercfg /change monitor-timeout-ac 5
				powercfg /change standby-timeout-ac 20
			}
		}
            
    } finally {
        # Unregister the engine event to avoid memory leaks
        Unregister-Event -SourceIdentifier PowerShell.Exiting -ErrorAction SilentlyContinue
    }
}

# Call the function
Toggle-SleepSetting
