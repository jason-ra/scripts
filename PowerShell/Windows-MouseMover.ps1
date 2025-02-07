## Purpose: Move the mouse automatically across the Leaf Blower Revolution window
## to collect materials AFK


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

        #Write-Host $hWnd
        #$WindowHandles.Add($hWnd)
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

# Get Handle for LBR
$handle = (Get-WindowNames | ? { $_.Name -eq "Leaf Blower Revolution" }).Handle

if ($handle) {
    Write-Host "Found handle $handle for LBR"
}
else {
    Write-Host "Could not find LBR. Exiting"
    exit
}

# Get the window rectangle
$rect = New-Object User32+Rect
[User32]::GetWindowRect($handle, [ref]$rect) | Out-Null

# Variables to define the movement
$x = $rect.Left
$y = $rect.Top
$width = $rect.Right - $rect.Left
$height = $rect.Bottom - $rect.Top
$xStep = 60 # step size for horizontal movement
#$yStep = 150 # step size for vertical movement
$yStep = $height / 8

$switch = $true
# Move the cursor inside the window
while ($true) {
    for ($y = $rect.Top + 50; $y -lt $rect.Bottom; $y += $yStep) {
        #if ($y -ge ($rect.Bottom - 200)) { $y = $rect.Bottom - 10 }
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
