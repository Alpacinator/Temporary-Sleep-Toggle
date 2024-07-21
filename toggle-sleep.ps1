function Toggle-SleepSetting {
    # Retrieve the GUID of the currently active power plan
    $string = Invoke-Expression "powercfg /getactivescheme"

    # Define the regex pattern to match a GUID format
    $pattern = "\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b"

    # Extract the GUID from the active plan information using regex
    $GUID = [regex]::Match($string, $pattern).Value

    # Retrieve all power settings options for the active power plan
    $Options = powercfg /query $GUID
    $index = 0

    # Find the index of the line that contains the "Sleep after" setting
    For($i=0; $i -lt $Options.Length; $i++) {
        $line = $Options[$i]
        if($line.ToLower() -like "*sleep after*") {
            $index = $i
            break
        }        
    }

    # The actual AC sleep setting is 6 lines after the "Sleep after" setting
    $sleepSetting = $Options[$index + 6]

    # Extract the value of the sleep setting from the retrieved string
    $sleepSettingTrimmed = $sleepSetting.Substring($sleepSetting.IndexOf(":")+2)
    $sleepDecimalValue = [convert]::ToInt32($sleepSettingTrimmed, 16)

    # Convert the sleep value from seconds to minutes
    $initialSleepValue = $sleepDecimalValue / 60

    # Find the index of the line that contains the "Turn off display after" setting
    For($i=0; $i -lt $Options.Length; $i++) {
        $line = $Options[$i]
        if($line.ToLower() -like "*turn off display after*") {
            $index = $i
            break
        }        
    }

    # The actual AC display setting is 6 lines after the "Turn off display after" setting
    $displaySetting = $Options[$index + 6]

    # Extract the value of the display setting from the retrieved string
    $displaySettingTrimmed = $displaySetting.Substring($displaySetting.IndexOf(":")+2)
    $displayDecimalValue = [convert]::ToInt32($displaySettingTrimmed, 16)

    # Convert the display value from seconds to minutes
    $initialDisplayValue = $displayDecimalValue / 60

    # Register an engine event to handle script termination and restore initial values
    Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        Write-Output "Script is being stopped. Restoring initial registry value..."
        powercfg /change monitor-timeout-ac $initialDisplayValue
        powercfg /change standby-timeout-ac $initialSleepValue
    }

    try {
        # Load the required assembly for displaying message boxes
        Add-Type -AssemblyName System.Windows.Forms

        # Check the current values and toggle them
        if ($initialDisplayValue -gt 0 -and $initialSleepValue -gt 0) {
            # Disable sleep and display timeout settings
            powercfg /change monitor-timeout-ac 0  # Set monitor timeout to 0 (never)
            powercfg /change standby-timeout-ac 0  # Set sleep timeout to 0 (never)
            
            # Show a message box indicating sleep is disabled
            [System.Windows.Forms.MessageBox]::Show("Sleep is now disabled. Press OK to re-enable it.", "Temporary Sleep Toggle", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)    
            Write-Host "Sleep is now disabled." -ForegroundColor Red            

            # Re-enable the original sleep and display timeout settings
            powercfg /change monitor-timeout-ac $initialDisplayValue
            powercfg /change standby-timeout-ac $initialSleepValue
            
            Write-Host "Sleep is now enabled." -ForegroundColor Green
        } else {
            # Inform the user that sleep was already disabled and offer to enable it
            $result = [System.Windows.Forms.MessageBox]::Show("Sleep was already disabled. This only works when sleep is enabled. Would you like to enable it?", "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

            # Enable sleep settings if the user chooses "Yes"
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

# Execute the function to toggle the sleep setting
Toggle-SleepSetting
