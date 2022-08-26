for f in "$HOME"/.shrc.d/*.sh
  source "$f"
end
for f in "$HOME"/.shrc.d/*.fish
  source "$f"
end

if status is-interactive
  fish_vi_key_bindings
end
