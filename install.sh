#!/usr/bin/env bash
# Instalador do miranda-shell — uma shell Quickshell para Hyprland.
#
# O que ele faz (e o que NÃO faz):
#   - confere as dependências e mostra o que falta (no Arch, oferece instalar);
#   - cria um symlink de ESTE repositório em ~/.config/quickshell/<nome>, que é
#     onde o Quickshell procura configs nomeadas (daí você roda `qs -c <nome>`);
#   - opcionalmente, adiciona a linha de autostart no seu hyprland.conf.
#
# Ele NÃO substitui a sua Waybar, NÃO toca em config do HyDE/Hyprland sem você
# pedir, e roda tudo na SUA conta — o `sudo` (se houver) é só pra instalar pacote.
set -euo pipefail

# ---- aparência ----
bold=$'\e[1m'; dim=$'\e[2m'; red=$'\e[31m'; grn=$'\e[32m'; ylw=$'\e[33m'; cyn=$'\e[36m'; rst=$'\e[0m'
info()  { printf '%s==>%s %s\n' "$cyn" "$rst" "$*"; }
ok()    { printf '%s  ✓%s %s\n' "$grn" "$rst" "$*"; }
warn()  { printf '%s  !%s %s\n' "$ylw" "$rst" "$*"; }
err()   { printf '%s  ✗%s %s\n' "$red" "$rst" "$*" >&2; }

# Diretório do próprio repositório (funciona de onde você tiver clonado).
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="miranda-shell"
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
LINK="$CFG_DIR/$NAME"

# ---- dependências: comando -> pacote (Arch) / observação ----
# obrigatórias
REQ_CMDS=(qs Hyprland brightnessctl)
declare -A PKG=(
  [qs]="quickshell-git"          # AUR
  [Hyprland]="hyprland"
  [brightnessctl]="brightnessctl"
  [nvidia-smi]="nvidia-utils"
  [nmcli]="networkmanager"
  [bluetoothctl]="bluez-utils"
  [pw-cli]="pipewire"
  [upower]="upower"
)
# opcionais (a shell degrada sozinha se faltar)
OPT_CMDS=(nvidia-smi nmcli bluetoothctl pw-cli upower)

FONT_NAME="JetBrainsMono Nerd Font"
FONT_PKG="ttf-jetbrains-mono-nerd"

has() { command -v "$1" >/dev/null 2>&1; }
has_font() { fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; }

# ---- checagem ----
info "Repositório: ${dim}$REPO_DIR${rst}"
info "Conferindo dependências…"

missing_req=()  # pacotes obrigatórios faltando
missing_opt=()  # pacotes opcionais faltando

for c in "${REQ_CMDS[@]}"; do
  if has "$c"; then ok "$c"; else err "$c (faltando)"; missing_req+=("${PKG[$c]}"); fi
done

if has_font; then ok "$FONT_NAME"; else err "$FONT_NAME (faltando)"; missing_req+=("$FONT_PKG"); fi

for c in "${OPT_CMDS[@]}"; do
  if has "$c"; then ok "$c ${dim}(opcional)${rst}"; else warn "$c ${dim}(opcional — recurso degrada)${rst}"; missing_opt+=("${PKG[$c]}"); fi
done

# HyDE é opcional mas habilita o tema dinâmico + a página Aparência.
if has hyde-shell; then ok "hyde-shell ${dim}(HyDE — tema dinâmico)${rst}"
else warn "hyde-shell ausente ${dim}(opcional — sem HyDE a shell usa paleta neutra de fallback)${rst}"; fi

# ---- instalar o que falta (só Arch / pacman) ----
if ((${#missing_req[@]})); then
  echo
  if has pacman; then
    # deduplica
    mapfile -t req_uniq < <(printf '%s\n' "${missing_req[@]}" | sort -u)
    warn "Faltam pacotes obrigatórios: ${bold}${req_uniq[*]}${rst}"
    aur=""
    for h in paru yay; do has "$h" && { aur="$h"; break; }; done
    read -rp "  Instalar agora com pacman/${aur:-AUR}? [s/N] " ans
    if [[ "${ans,,}" == s* ]]; then
      # quickshell-git é do AUR; o resto é repo oficial. Se houver helper AUR,
      # ele cobre tudo de uma vez; senão, repo oficial via sudo pacman e avisa
      # sobre o que for AUR.
      if [[ -n "$aur" ]]; then
        "$aur" -S --needed "${req_uniq[@]}"
      else
        repo=(); aurl=()
        for p in "${req_uniq[@]}"; do
          [[ "$p" == *-git || "$p" == "quickshell-git" ]] && aurl+=("$p") || repo+=("$p")
        done
        ((${#repo[@]})) && sudo pacman -S --needed "${repo[@]}"
        ((${#aurl[@]})) && err "Pacotes do AUR sem helper: ${aurl[*]} — instale um helper (paru/yay) e rode de novo, ou compile manualmente."
      fi
    else
      warn "Pulei a instalação. Instale antes de rodar: ${req_uniq[*]}"
    fi
  else
    err "Você não está no Arch (sem pacman). Instale na sua distro: ${missing_req[*]}"
    warn "Equivalentes: quickshell (AUR/compilar), hyprland, $FONT_PKG (qualquer JetBrainsMono Nerd Font), brightnessctl."
  fi
fi

# ---- symlink da config ----
echo
info "Ligando a shell em ${bold}$LINK${rst}"
mkdir -p "$CFG_DIR"
if [[ -L "$LINK" ]]; then
  cur="$(readlink -f "$LINK")"
  if [[ "$cur" == "$REPO_DIR" ]]; then ok "Symlink já aponta pra cá."
  else warn "Symlink existente aponta pra ${dim}$cur${rst}; atualizando."; ln -sfn "$REPO_DIR" "$LINK"; ok "Atualizado."; fi
elif [[ -e "$LINK" ]]; then
  err "$LINK já existe e NÃO é symlink. Remova/renomeie e rode de novo."; exit 1
else
  ln -s "$REPO_DIR" "$LINK"; ok "Symlink criado."
fi

# ---- autostart (opcional) ----
echo
HYPR_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.conf"
AUTOSTART_LINE="exec-once = qs -c $NAME"
if [[ -f "$HYPR_CONF" ]]; then
  if grep -qF "qs -c $NAME" "$HYPR_CONF"; then
    ok "Autostart já presente no hyprland.conf."
  else
    read -rp "  Adicionar autostart (${bold}$AUTOSTART_LINE${rst}) no hyprland.conf? [s/N] " a2
    if [[ "${a2,,}" == s* ]]; then
      printf '\n# miranda-shell\n%s\n' "$AUTOSTART_LINE" >> "$HYPR_CONF"
      ok "Linha adicionada. (Comente a da Waybar quando quiser trocar de vez.)"
    else
      warn "Sem autostart. Rode manualmente: ${bold}qs -c $NAME${rst}"
    fi
  fi
else
  warn "hyprland.conf não encontrado em $HYPR_CONF — adicione você mesmo:"
  printf '       %s\n' "$AUTOSTART_LINE"
fi

echo
ok "Pronto! Teste agora sem reiniciar:"
printf '       %sqs -c %s%s\n' "$bold" "$NAME" "$rst"
printf '   %sFechar:%s qs kill   •   %sLogs:%s qs -c %s --log\n' "$dim" "$rst" "$dim" "$rst" "$NAME"
