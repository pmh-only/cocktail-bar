mkdir .vscode
cat <<EOF > .vscode/settings.json
{
  "workbench.startupEditor": "none",
  "redhat.telemetry.enabled": false,
  "editor.fontFamily": "'JetBrainsMono Nerd Font'",
  "editor.fontLigatures": true,
  "workbench.iconTheme": "material-icon-theme",
  "editor.mouseWheelZoom": true,
  "files.insertFinalNewline": true,
  "editor.smoothScrolling": true,
  "editor.cursorSmoothCaretAnimation": "on",
  "workbench.list.smoothScrolling": true,
  "editor.cursorBlinking": "smooth",
  "editor.tabSize": 2,
  "editor.lineNumbers": "relative",
  "git.enableSmartCommit": true,
  "git.autofetch": true,
  "material-icon-theme.activeIconPack": "nest",
  "editor.codeActionsOnSave": {
    "source.fixAll": "always",
    "source.fixAll.eslint": "always"
  },
  "editor.minimap.enabled": false,
  "vim.autoindent": true,
  "git.confirmSync": false,
  "javascript.updateImportsOnFileMove.enabled": "always",
  "typescript.updateImportsOnFileMove.enabled": "always",
  "workbench.colorTheme": "Atom One Light",
  "liveServer.settings.donotShowInfoMsg": true,
  "window.menuBarVisibility": "toggle",
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "terminal.integrated.profiles.windows": {
    "PowerShell": {
      "source": "PowerShell",
      "icon": "terminal-powershell"
    },
    "Command Prompt": {
      "path": [
      ],
      "args": [],
      "icon": "terminal-cmd"
    }
  },
  "terminal.integrated.defaultProfile.windows": "PowerShell",
  "terminal.integrated.cursorBlinking": true,
  "window.dialogStyle": "custom",
  "typescript.preferences.importModuleSpecifier": "relative",
  "debug.javascript.autoAttachFilter": "disabled",
  "liveServer.settings.donotVerifyTags": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "hexeditor.columnWidth": 16,
  "hexeditor.showDecodedText": true,
  "hexeditor.defaultEndianness": "little",
  "hexeditor.inspectorType": "aside",
  "[java]": {
    "editor.defaultFormatter": "redhat.java"
  },
  "[python]": {
    "editor.formatOnType": true
  },
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.formatOnType": true,
    "editor.rulers": [80],
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": "off"
  },
  "git.openRepositoryInParentFolders": "always",
  "editor.linkedEditing": true,
  "svelte.enable-ts-plugin": true,
  "terminal.integrated.defaultProfile.linux": "zsh",
  "git.enableCommitSigning": true,
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform"
  },
  "remote.SSH.remotePlatform": {
    "shutupandtakemy.codes": "linux",
    "localhost": "linux",
    "ssh.shutupandtakemy.codes": "linux",
    "shell.pmh.codes": "linux",
    "oci.pmh.codes": "linux",
    "pmhserver.host.pmh.codes": "linux",
    "pmhoci.host.pmh.codes": "linux",
    "3.35.187.223": "linux",
    "pmhoci": "linux",
    "3.36.93.131": "linux"
  },
  "editor.inlineSuggest.enabled": true,
  "github.copilot.enable": {
    "*": true,
    "plaintext": true,
    "markdown": true,
    "scminput": false
  },
  "terminal.integrated.enableMultiLinePasteWarning": false,
  "editor.stablePeek": true,
  "editor.stickyScroll.enabled": true,
  "typescript.implementationsCodeLens.enabled": true,
  "typescript.referencesCodeLens.enabled": true,
  "typescript.referencesCodeLens.showOnAllFunctions": true,
  "security.workspace.trust.untrustedFiles": "open",
  "window.commandCenter": true,
  "background.useFront": false,
  "liveshare.launcherClient": "visualStudioCode",
  "liveshare.allowGuestDebugControl": true,
  "liveshare.allowGuestTaskControl": true,
  "liveshare.anonymousGuestApproval": "accept",
  "liveshare.notebooks.allowGuestExecuteCells": true,
  "diffEditor.ignoreTrimWhitespace": false,
  "yaml.customTags": [
    "!And",
    "!And sequence",
    "!If",
    "!If sequence",
    "!Not",
    "!Not sequence",
    "!Equals",
    "!Equals sequence",
    "!Or",
    "!Or sequence",
    "!FindInMap",
    "!FindInMap sequence",
    "!Base64",
    "!Join",
    "!Join sequence",
    "!Cidr",
    "!Ref",
    "!Sub",
    "!Sub sequence",
    "!GetAtt",
    "!GetAZs",
    "!ImportValue",
    "!ImportValue sequence",
    "!Select",
    "!Select sequence",
    "!Split",
    "!Split sequence"
  ],
  "[yaml]": {
    "editor.insertSpaces": true,
    "editor.tabSize": 2,
    "editor.autoIndent": "keep",
    "diffEditor.ignoreTrimWhitespace": false,
    "editor.quickSuggestions": {
      "other": true,
      "comments": false,
      "strings": true
    },
    "editor.defaultFormatter": "redhat.vscode-yaml"
  },
  "window.titleBarStyle": "custom",
  "go.toolsManagement.autoUpdate": true,
  // "terminal.integrated.stickyScroll.enabled": true,
  "workbench.tree.enableStickyScroll": true,
"cSpell.userWords": [
    "Minhyeok",
    "pydio"
],
  "[go]": {
    "editor.defaultFormatter": "golang.go"
  },
  "eslint.validate": ["javascript", "javascriptreact", "svelte"],
  "terminal.integrated.mouseWheelZoom": true,
  "editor.accessibilitySupport": "off",
  "security.workspace.trust.banner": "never",
  "security.workspace.trust.enabled": false,
  "prisma.showPrismaDataPlatformNotification": false,
  "vs-kubernetes": {
    "vscode-kubernetes.kubectl-path-linux": "/home/ec2-user/.local/state/vs-kubernetes/tools/kubectl/kubectl",
    "vscode-kubernetes.helm-path-linux": "/home/ec2-user/.local/state/vs-kubernetes/tools/helm/linux-amd64/helm",
    "vscode-kubernetes.minikube-path-linux": "/home/ec2-user/.local/state/vs-kubernetes/tools/minikube/linux-amd64/minikube"
  },
  "vim.easymotion": true,
  "vim.incsearch": true,
  "vim.useSystemClipboard": true,
  "vim.useCtrlKeys": true,
  "vim.hlsearch": true,
  "vim.insertModeKeyBindings": [
    {
      "before": ["j", "j"],
      "after": ["<Esc>"]
    }
  ],
  "vim.normalModeKeyBindingsNonRecursive": [
    {
      "before": ["<leader>", "d"],
      "after": ["d", "d"]
    },
    {
      "before": ["<C-n>"],
      "commands": [":nohl"]
    },
    {
      "before": ["K"],
      "commands": ["lineBreakInsert"],
      "silent": true
    }
  ],
  "vim.leader": "<space>",
  "vim.handleKeys": {
    "<C-c>": false,
    "<C-v>": false,
    "<C-d>": false,
    "<C-x>": false
  },

  "extensions.experimental.affinity": {
    "vscodevim.vim": 1
  },
  "terminal.integrated.fontSize": 24,
  "yaml.schemas": {
    "Kubernetes": [
      "*.yml",
      "!cluster.yml"
    ],
    ".vscode/eksctl.json": "cluster.yml"
  }
}
EOF

code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
code --install-extension lunuan.kubernetes-templates
code --install-extension redhat.vscode-yaml
code --install-extension vscodevim.vim
code --install-extension pkief.material-icon-theme
code --install-extension usernamehw.errorlens
code --install-extension remcohaszing.schemastore
code --install-extension akamud.vscode-theme-onelight

eksctl utils schema > .vscode/eksctl.json

echo "export EDITOR='code -w'" >> ~/.bashrc
echo "export EDITOR='code -w'" >> ~/.zshrc
