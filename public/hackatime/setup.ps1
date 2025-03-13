try {
    # Create config file
    New-Item -Path $env:USERPROFILE\.wakatime.cfg -Force
    Set-Content -Path $env:USERPROFILE\.wakatime.cfg -Value @"
[settings]
api_url = $env:HACKATIME_API_URL
api_key = $env:HACKATIME_API_KEY
"@

    Write-Host "Config file created at $env:USERPROFILE\.wakatime.cfg"

    # Read values from config to verify
    if (-not (Test-Path $env:USERPROFILE\.wakatime.cfg)) {
      Write-Error "Config file not found"
      throw "Config file not found"
    }

    $config = Get-Content $env:USERPROFILE\.wakatime.cfg
    $apiUrl = $config | Select-String "api_url" | ForEach-Object { $_.ToString().Split('=')[1].Trim() }
    $apiKey = $config | Select-String "api_key" | ForEach-Object { $_.ToString().Split('=')[1].Trim() }

    if (-not $apiUrl -or -not $apiKey) {
      Write-Error "Could not read api_url or api_key from config"
      throw "Could not read api_url or api_key from config"
    }

    Write-Host "Successfully read config:"
    Write-Host "API URL: $apiUrl"
    Write-Host ("API Key: " + $apiKey.Substring(0,8) + "...") # Show only first 8 chars for security

    # Send test heartbeat using values from config
    Write-Host "Sending test heartbeat..."
    $time = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat '%s'))
    $heartbeat = @{
      type = 'file'
      time = $time
      entity = 'test.txt'
      language = 'Text'
    }
    $body = "[$($heartbeat | ConvertTo-Json)]"

    $response = Invoke-WebRequest -Uri "$apiUrl/users/current/heartbeats" `
      -Method Post `
      -Headers @{Authorization="Bearer $apiKey"} `
      -ContentType 'application/json' `
      -Body $body

    Write-Host "Test heartbeat sent successfully"
} catch {
    Write-Host "----------------------------------------"
    Write-Host "ERROR: An error occurred during setup:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "----------------------------------------"
}
finally {
    # This will always execute, even if errors occur
    Write-Host "`nSetup process completed. Review any errors above."
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    # Additional fallback to keep window open in all cases
    Start-Sleep -Seconds 60
}
