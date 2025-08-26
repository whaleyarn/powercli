FROM mcr.microsoft.com/powershell

RUN pwsh -Command Install-Module -Name VCF.PowerCLI -Repository PSGallery -Force \
    && pwsh -Command 'Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false'

COPY certs/* /usr/local/share/ca-certificates/

RUN update-ca-certificates

COPY powershell/Microsoft.PowerShell_profile.ps1 /root/.config/powershell/

COPY Modules/ /root/.local/share/powershell/Modules/

