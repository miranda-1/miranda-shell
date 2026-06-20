# miranda-shell

Uma **shell de borda reativa** para **Hyprland**, escrita em **[Quickshell](https://quickshell.outfoxxed.me/) (QML)**.
Inspirada no [Caelestia](https://github.com/caelestia-dots/shell): uma barra lateral
viva à esquerda e um painel que desce do topo, contextual, com animação — em vez de
uma barra estática.

Pensada para **Arch Linux + Hyprland + [HyDE](https://github.com/HyDE-Project/HyDE)**,
mas roda em qualquer Hyprland (o HyDE é opcional — sem ele a shell usa uma paleta
neutra de fallback).

> **Convive com a sua Waybar.** A shell roda sobrepondo a sessão atual (layer-shell)
> e **não toca em nada do sistema** até você optar pelo deploy. Dá pra testar com a
> Waybar rodando por baixo e fechar quando quiser — nada muda.

---

## ✨ O que tem dentro

A barra lateral (`EdgeLeft`) é o seletor; cada botão abre uma página no painel do topo:

| Página | O que faz |
| --- | --- |
| **Dashboard** | Resumo vivo: hora/data, janela ativa, rede, bateria, mídia. |
| **Busca / Launcher** | Lança apps (`.desktop`), com "me leve até o app" (foca se já estiver aberto). |
| **Calendário** | Mês navegável em pt-BR. |
| **Controles** | Wi-Fi (conectar, inclusive rede protegida), Bluetooth (parear), volume, **brilho** (tela interna), perfil de energia. |
| **Mídia** | Player MPRIS real (título/progresso/controles) + abrir Spotify. |
| **Atalhos** | Lê seu `keybindings.conf` do Hyprland e mostra traduzido/agrupado. |
| **Aparência** | Troca tema e wallpaper do HyDE direto pela shell. |
| **Workspaces** | Overview tipo alt-tab com mini-mapa real das janelas de **todas as telas**; clique foca. |
| **Sistema ao vivo** | Anéis de CPU / GPU / RAM com uso %, temperatura e detalhe. |
| **Telas** | Escolhe em qual monitor o shell aparece e troca resolução / Hz / escala no Hyprland vivo, **com revert automático**. |
| **Energia** | Bloquear, suspender, reiniciar, desligar, iniciar no Windows — com confirmação. |
| **SystemTray** | Ícones de apps em background (StatusNotifierItem) com menu de contexto. |

Mais: **tema dinâmico** — a shell segue o tema do HyDE ao vivo (recolore sozinha
quando você troca o wallpaper/tema).

---

## 🚀 Instalação rápida

```sh
git clone https://github.com/miranda-1/miranda-shell.git
cd miranda-shell
./install.sh
```

O `install.sh`:

1. confere as dependências e, **no Arch**, oferece instalar o que faltar;
2. liga o repositório em `~/.config/quickshell/miranda-shell` (symlink — atualiza junto
   com `git pull`);
3. opcionalmente adiciona o autostart no seu `hyprland.conf`.

Depois é só rodar (sem reiniciar):

```sh
qs -c miranda-shell
```

Pra fechar: `qs kill`. Pra ver logs: `qs -c miranda-shell --log`.

---

## 🔧 Dependências

**Obrigatórias**

| Pacote (Arch) | Para quê |
| --- | --- |
| `quickshell-git` (AUR) | runtime da shell (binário `qs`) |
| `hyprland` | compositor (workspaces, monitores, IPC) |
| `ttf-jetbrains-mono-nerd` | os glyphs dos ícones (qualquer *JetBrainsMono Nerd Font* serve) |
| `brightnessctl` | controle de brilho da tela interna |

**Opcionais** (a shell degrada sozinha se faltar)

| Pacote | Habilita |
| --- | --- |
| `nvidia-utils` (`nvidia-smi`) | uso/temperatura da GPU no "Sistema ao vivo" |
| **HyDE** (`hyde-shell`) | tema dinâmico + página Aparência |
| `networkmanager` | controles de Wi-Fi |
| `bluez` / `bluez-utils` | controles de Bluetooth |
| `pipewire` | controle de volume |
| `upower` | status da bateria |

> Em outras distros: instale o Quickshell (AUR/compilar), Hyprland, uma JetBrainsMono
> Nerd Font e `brightnessctl` pelos canais da sua distro. O resto é igual.

---

## 🧱 Instalação manual (sem o script)

```sh
# 1. dependências (Arch + helper AUR)
paru -S quickshell-git hyprland ttf-jetbrains-mono-nerd brightnessctl

# 2. ligar a config
ln -s "$PWD" ~/.config/quickshell/miranda-shell

# 3. rodar
qs -c miranda-shell
```

Pra iniciar junto do Hyprland, adicione ao `~/.config/hypr/hyprland.conf`:

```conf
exec-once = qs -c miranda-shell
```

---

## 🗑️ Desinstalar

```sh
rm ~/.config/quickshell/miranda-shell           # remove o symlink
qs kill                                     # fecha a shell
# e tire a linha `exec-once = qs -c miranda-shell` do hyprland.conf, se adicionou
```

Nada além disso é tocado no sistema.

---

## 🗂️ Estrutura

```
shell.qml              # entrypoint
config/Theme.qml       # tokens visuais — segue o tema do HyDE (wallbash)
services/              # singletons: estado do sistema (read-only) + ações typed
modules/
  EdgeLeft/            # a barra lateral / seletor
  TopSheet/            # o painel do topo + as páginas (pages/*.qml)
components/            # widgets reutilizáveis (cards, sliders, tray, menus…)
deploy/                # rollback.sh — reverte o deploy (religa a Waybar)
```

## 🔒 Segurança

Toda escrita no sistema passa pela **API typed do Quickshell** dentro de `services/`
(áudio, rede, Bluetooth, perfil de energia, brilho, modos de monitor). As poucas
exceções que usam comando externo são fixas e escopadas (`brightnessctl`, `nvidia-smi`,
`hyde-shell`, `systemctl`/`loginctl` para energia). Nada de `sh -c` com entrada do
usuário. Ações destrutivas (fechar workspace, desligar, trocar modo de tela) pedem
confirmação ou revertem sozinhas.
