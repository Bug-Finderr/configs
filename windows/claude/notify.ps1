# Toasts for the interactive CLI's main thread only. SDK hosts (T3 Code, claude -p)
# notify their own way, and subagent events carry agent_id.
if ($env:CLAUDE_CODE_ENTRYPOINT -ne 'cli') { exit }

$evt = (New-Object System.IO.StreamReader([Console]::OpenStandardInput(), [Text.Encoding]::UTF8)).ReadToEnd() | ConvertFrom-Json
if ($evt.agent_id) { exit }
$message = if ($evt.hook_event_name -eq 'Stop') { 'Done' } else { $evt.message }

[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > $null
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml('<toast><visual><binding template="ToastGeneric"><text/><text placement="attribution"/></binding></visual></toast>')
$text = $xml.GetElementsByTagName('text')
$text.Item(0).AppendChild($xml.CreateTextNode($message)) > $null
$text.Item(1).AppendChild($xml.CreateTextNode($evt.cwd)) > $null
$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show([Windows.UI.Notifications.ToastNotification]::new($xml))
