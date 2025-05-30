Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
Start-Process powershell -Verb runAs "Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0"

winget install                `
  --disable-interactivity     `
  --accept-source-agreements  `
  --force                     `
                              `
  Microsoft.powershell        `
  Vim.Vim                     `
  Hashicorp.Terraform         `
  Kubernetes.kubectl          `
  Helm.Helm                   `
  Derailed.k9s                `
  Git.Git                     `
  ahmetb.kubectx              `
  OpenVPNTechnologies.OpenVPN `
  DEVCOM.JetBrainsMonoNerdFont

New-Item -Path $profile -ItemType "file" -Force
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.bin"

Invoke-WebRequest -Uri "https://github.com/projectcalico/calico/releases/latest/download/calicoctl-windows-amd64.exe" -OutFile "$env:USERPROFILE\.bin\calicoctl.exe"

@'
Set-Alias -Name k -Value kubectl

function ka { k apply -f $args }
function kg { k get -f $args }
function kd { k describe -f $args }
function kx { k delete -f $args }

function ti { terraform init $args }
function ta { terraform apply --parallelism 100 $args }
function taa { terraform apply --auto-approve --parallelism 100 $args }

$env:EDITOR = "code -w"
$env:PATH = "$env:PATH;C:\Program Files\Vim\vim91;C:\Users\$env:USERNAME\.bin"
'@ | `
Out-File -FilePath $profile

Start-Process powershell -Verb runAs "Set-Service ssh-agent -StartupType Automatic"
Start-Process powershell -Verb runAs "Start-Service ssh-agent"
