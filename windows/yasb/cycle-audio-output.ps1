[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]]$AllowedDevices = @(
        "Speakers (Realtek(R) Audio)",
        "Headphones (Chu2 DSP)"
    ),
    [switch]$ListOnly
)

$ErrorActionPreference = "Stop"

if (-not ("YasbAudio.Policy" -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace YasbAudio
{
    public enum EDataFlow
    {
        Render = 0,
        Capture = 1,
        All = 2
    }

    public enum ERole
    {
        Console = 0,
        Multimedia = 1,
        Communications = 2
    }

    [ComImport]
    [Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
    internal class MMDeviceEnumeratorComObject { }

    [ComImport]
    [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDeviceEnumerator
    {
        int EnumAudioEndpoints(EDataFlow dataFlow, uint stateMask, out IntPtr devices);
        int GetDefaultAudioEndpoint(EDataFlow dataFlow, ERole role, out IMMDevice endpoint);
        int GetDevice([MarshalAs(UnmanagedType.LPWStr)] string id, out IMMDevice device);
        int RegisterEndpointNotificationCallback(IntPtr client);
        int UnregisterEndpointNotificationCallback(IntPtr client);
    }

    [ComImport]
    [Guid("D666063F-1587-4E43-81F1-B948E807363F")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDevice
    {
        int Activate(ref Guid iid, uint context, IntPtr activationParams, out IntPtr instance);
        int OpenPropertyStore(uint access, out IntPtr properties);
        int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);
        int GetState(out uint state);
    }

    [ComImport]
    [Guid("870AF99C-171D-4F9E-AF0D-E63DF40C2BC9")]
    internal class PolicyConfigClientComObject { }

    [ComImport]
    [Guid("F8679F50-850A-41CF-9C72-430F290290C8")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IPolicyConfig
    {
        int GetMixFormat([MarshalAs(UnmanagedType.LPWStr)] string deviceId, out IntPtr format);
        int GetDeviceFormat([MarshalAs(UnmanagedType.LPWStr)] string deviceId, int isDefault, out IntPtr format);
        int ResetDeviceFormat([MarshalAs(UnmanagedType.LPWStr)] string deviceId);
        int SetDeviceFormat([MarshalAs(UnmanagedType.LPWStr)] string deviceId, IntPtr endpointFormat, IntPtr mixFormat);
        int GetProcessingPeriod([MarshalAs(UnmanagedType.LPWStr)] string deviceId, int isDefault, out long defaultPeriod, out long minimumPeriod);
        int SetProcessingPeriod([MarshalAs(UnmanagedType.LPWStr)] string deviceId, ref long period);
        int GetShareMode([MarshalAs(UnmanagedType.LPWStr)] string deviceId, out IntPtr mode);
        int SetShareMode([MarshalAs(UnmanagedType.LPWStr)] string deviceId, IntPtr mode);
        int GetPropertyValue([MarshalAs(UnmanagedType.LPWStr)] string deviceId, IntPtr key, out IntPtr value);
        int SetPropertyValue([MarshalAs(UnmanagedType.LPWStr)] string deviceId, IntPtr key, IntPtr value);
        int SetDefaultEndpoint([MarshalAs(UnmanagedType.LPWStr)] string deviceId, ERole role);
        int SetEndpointVisibility([MarshalAs(UnmanagedType.LPWStr)] string deviceId, int visible);
    }

    public static class Policy
    {
        public static string GetDefaultRenderId()
        {
            IMMDeviceEnumerator enumerator = (IMMDeviceEnumerator)new MMDeviceEnumeratorComObject();
            IMMDevice endpoint;
            Marshal.ThrowExceptionForHR(
                enumerator.GetDefaultAudioEndpoint(EDataFlow.Render, ERole.Multimedia, out endpoint)
            );
            string id;
            Marshal.ThrowExceptionForHR(endpoint.GetId(out id));
            return id;
        }

        public static void SetDefaultRenderId(string id)
        {
            IPolicyConfig policy = (IPolicyConfig)new PolicyConfigClientComObject();
            foreach (ERole role in Enum.GetValues(typeof(ERole)))
            {
                Marshal.ThrowExceptionForHR(policy.SetDefaultEndpoint(id, role));
            }
        }
    }
}
'@
}

$prefix = "SWD\MMDEVAPI\"
$playbackDevices = @(
    Get-PnpDevice -Class AudioEndpoint -PresentOnly |
        Where-Object InstanceId -Like "$prefix{0.0.0.00000000}*" |
        ForEach-Object {
            [pscustomobject]@{
                Name = $_.FriendlyName
                Id = $_.InstanceId.Substring($prefix.Length)
            }
        }
)

if ($ListOnly) {
    $playbackDevices
    exit
}

if ($AllowedDevices.Count -lt 2) {
    throw "At least two allowed playback devices are required."
}

$allowed = @(
    foreach ($name in $AllowedDevices) {
        $matches = @($playbackDevices | Where-Object Name -EQ $name)
        if ($matches.Count -gt 1) {
            throw "Expected at most one playback device named '$name', found $($matches.Count)."
        }
        if ($matches.Count -eq 1) {
            $matches[0]
        }
    }
)

if ($allowed.Count -eq 0) {
    throw "None of the allowed playback devices are currently available."
}

$currentId = [YasbAudio.Policy]::GetDefaultRenderId()
$currentIndex = -1
for ($i = 0; $i -lt $allowed.Count; $i++) {
    if ($allowed[$i].Id -ieq $currentId) {
        $currentIndex = $i
        break
    }
}

$nextIndex = if ($currentIndex -lt 0) { 0 } else { ($currentIndex + 1) % $allowed.Count }
$next = $allowed[$nextIndex]
$current = $playbackDevices | Where-Object Id -IEQ $currentId | Select-Object -First 1
$currentName = if ($current) { $current.Name } else { $currentId }

if ($allowed.Count -eq 1) {
    [pscustomobject]@{
        Current = $currentName
        Next = $allowed[0].Name
        Changed = $false
        Reason = "Only one allowed playback device is available."
    }
    exit 0
}

if ($PSCmdlet.ShouldProcess($next.Name, "Set as default playback device")) {
    [YasbAudio.Policy]::SetDefaultRenderId($next.Id)
}

[pscustomobject]@{
    Current = $currentName
    Next = $next.Name
    Changed = -not [bool]$WhatIfPreference
}
