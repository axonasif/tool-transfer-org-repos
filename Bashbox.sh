NAME="Transfer organization repositories"
CODENAME="transfer-org-repos"
AUTHORS=("AXON <axonasif@gmail.com>")
VERSION="1.0"
DEPENDENCIES=(
  std
)
REPOSITORY=""
BASHBOX_COMPAT="0.4.0~"

bashbox::build::after() {
	cp "$_target_workfile" "$_arg_path/$CODENAME";
	chmod +x "$_arg_path/$CODENAME";
}

