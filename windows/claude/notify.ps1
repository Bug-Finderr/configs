$ErrorActionPreference = 'Stop'

if ($env:CLAUDE_CODE_ENTRYPOINT -like 'sdk-*') { exit 0 }

try {
    $raw = (New-Object System.IO.StreamReader(
        [Console]::OpenStandardInput(),
        [System.Text.Encoding]::UTF8
    )).ReadToEnd()
    $evt = $raw | ConvertFrom-Json
} catch {
    exit 0
}

$message = switch ($evt.hook_event_name) {
    'PermissionRequest' { "Permission: $($evt.tool_name)" }
    'Notification'      { $evt.message }
    'Stop'              { 'Done' }
    default             { $null }
}

if ([string]::IsNullOrWhiteSpace($message)) { exit 0 }
$message = ([string]$message -replace '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '').Trim()

[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > $null
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null

$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml('<toast><visual><binding template="ToastGeneric"><text/><text placement="attribution"/></binding></visual></toast>')
$text = $xml.GetElementsByTagName('text')
$text.Item(0).AppendChild($xml.CreateTextNode($message)) > $null
$text.Item(1).AppendChild($xml.CreateTextNode([string]$evt.cwd)) > $null

$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
$toast = New-Object Windows.UI.Notifications.ToastNotification $xml
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
