function dw() {
	declare -a dw_cmd;
	if command::exists curl; then {
		dw_cmd=(curl -sSL);
	} elif command::exists wget; then {
		dw_cmd=(wget -qO-);
	} fi

	if test -n "${dw_cmd:-}"; then {
		declare dw_path="$1";
		declare dw_url="$2";
		declare cmd="$(
			cat <<EOF
mkdir -m 0755 -p "${dw_path%/*}" && until ${dw_cmd[*]} "$dw_url" ${PIPE:-"> '$dw_path'"}; do continue; done
if test -e "$dw_path"; then chmod +x "$dw_path"; fi
EOF
		)"
		sudo sh -c "$cmd";
	} else {
		log::warn "curl or wget wasn't found, some things will go wrong";
	} fi
}

function get_input() {
  declare name="$1";
  declare placeholder="$2";
  declare input && input="$(gum input --placeholder "$placeholder")";
  if test -z "${input:-}"; then {
    log::error "You provided empty input for $name" 1 || exit;
  } fi
  printf '%s\n' "$input";
}

