<#
.Synopsis
   Automatic mouse mover that criss-crosses a chosen window / app
.DESCRIPTION
   Intended for Leaf Blower Revolution, the script runs continuously and moves the mouse cursor
   across an the open application to collect materials while AFK. Written for LBR using Steam.

   Run the script and press Control+Break to exit.
.INPUTS
   None
.OUTPUTS
   None
.EXAMPLE
   .\Windows\MouseMover.ps1
#>

# Add-Type is used to access Windows API functions
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class User32 {
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, ref Rect rect);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int x, int y);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    public struct Rect {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}

"@

function Get-WindowNames {
    $WindowNames = [System.Collections.Generic.List[String]]::new()
    $WindowHandles = [System.Collections.Generic.List[IntPtr]]::new()

    $callback = [User32+EnumWindowsProc] {
        param ($hWnd, $lParam)

        # Filter on visible windows only
        if ([User32]::IsWindowVisible($hWnd)) {
            $builder = New-Object System.Text.StringBuilder 256
            [User32]::GetWindowText($hWnd, $builder, $builder.Capacity) | Out-Null
            $windowName = $builder.ToString()

            if (![string]::IsNullOrEmpty($windowName)) {
                $WindowNames.Add($windowName)
                $WindowHandles.Add($hWnd)
            }
        }
        return $true
    }

    if ([User32]::EnumWindows($callback, [IntPtr]::Zero)) {
        # Return object of handle and window name
        $i = 0
        $result = foreach ($handle In $WindowHandles) {
            [PSCustomObject]@{
                Handle = $handle
                Name   = $windowNames[$i]
            }
            $i++
        }
        return $result
    }
    
}

# Get handle for app name
$appName = "Leaf Blower Revolution"
$handle = (Get-WindowNames | ? { $_.Name -eq $appName }).Handle

if ($handle) {
    Write-Host "Found handle $handle for $appName"
}
else {
    Write-Host "Could not find window for $appName. Exiting"
    exit
}

# Get the window rectangle
$rect = New-Object User32+Rect
[User32]::GetWindowRect($handle, [ref]$rect) | Out-Null

# Variables to define the movement
$height = $rect.Bottom - $rect.Top
$xStep = 60 # step size for horizontal movement
#$yStep = 150 # step size for vertical movement
$yStep = $height / 8

$switch = $true # Controls alternating movement between left-to-right and right-to-left
# Move the cursor inside the window
while ($true) {
    for ($y = $rect.Top + 50; $y -lt $rect.Bottom; $y += $yStep) {
        if ($switch) {
            for ($x = $rect.Left + 15; $x -lt $rect.Right; $x += $xStep) {
                [User32]::SetCursorPos($x, $y) | Out-Null
                Start-Sleep -Milliseconds 1
            }
            $switch = $false
        }
        else {
            for ($x = $rect.Right; $x -gt $rect.Left; $x -= $xStep) {
                [User32]::SetCursorPos($x, $y) | Out-Null
                Start-Sleep -Milliseconds 1
            }
            $switch = $true
        }
    }
    # Reset to top-left
    $x = $rect.Left
    $y = $rect.Top
    $switch = $true
}
