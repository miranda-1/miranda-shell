#!/usr/bin/env bash
# Reverte o deploy do miranda-shell: religa a Waybar do HyDE e tira o autostart da
# shell. Não apaga nada do seu sistema além do que o deploy adicionou.
set -euo pipefail

grn=$'\e[32m'; ylw=$'\e[33m'; rst=$'\e[0m'
ok()   { printf '%s  ✓%s %s\n' "$grn" "$rst" "$*"; }
warn() { printf '%s  !%s %s\n' "$ylw" "$rst" "$*"; }

STARTUP="${XDG_DATA_HOME:-$HOME/.local/share}/hypr/startup.conf"
USERPREFS="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/userprefs.conf"
LINK="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/miranda-shell"

# 1) reativar a Waybar no login (descomenta o exec-once do startup.conf)
if grep -q '# exec-once = \$start\.BAR  # >>> desativado pelo miranda-shell deploy' "$STARTUP"; then
  sed -i 's|^# exec-once = \$start\.BAR  # >>> desativado pelo miranda-shell deploy (reverter: descomente) <<<|exec-once = $start.BAR|' "$STARTUP"
  ok "Waybar reativada no startup.conf."
else
  warn "Linha do Waybar já estava ativa (nada a fazer no startup.conf)."
fi

# 1b) remover o "fake waybar" que impede a barra de aparecer na troca de tema
FAKE="${HOME}/.local/bin/waybar"
if [[ -f "$FAKE" ]] && grep -q "miranda-shell deploy" "$FAKE"; then
  rm -f "$FAKE"; ok "Fake waybar removido ($FAKE)."
else
  warn "Fake waybar não encontrado (já removido?)."
fi
# garante que a unit fique limpa para a Waybar real subir
systemctl --user stop hyde-Hyprland-bar.service >/dev/null 2>&1 || true
systemctl --user reset-failed hyde-Hyprland-bar.service >/dev/null 2>&1 || true
hash -r 2>/dev/null || true

# 2) relançar a Waybar agora (sem precisar relogar)
if command -v hyde-shell >/dev/null 2>&1; then
  hyde-shell waybar >/dev/null 2>&1 && ok "Waybar relançada agora." || warn "Relance manual: hyde-shell waybar (ou relogue)."
else
  warn "hyde-shell ausente — relogue para a Waybar voltar."
fi

# 3) tirar o autostart da shell do userprefs.conf
if grep -qF "miranda-shell deploy" "$USERPREFS"; then
  sed -i '/# >>> miranda-shell deploy/,/# <<< miranda-shell deploy/d' "$USERPREFS"
  ok "Autostart da shell removido do userprefs.conf."
else
  warn "Bloco de autostart não encontrado (já removido?)."
fi

# 4) fechar a shell agora
qs kill >/dev/null 2>&1 && ok "Shell encerrada (qs kill)." || warn "Nenhuma shell rodando."

echo
ok "Rollback concluído: a Waybar volta e a shell não inicia mais no login."
warn "O symlink $LINK foi mantido (inócuo). Remova com: rm '$LINK'"
warn "Backups .predeploy-* ficam em ~/.config/hypr/ e ~/.local/share/hypr/ se precisar."
