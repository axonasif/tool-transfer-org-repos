use std::print::log;
use std::term::colors;
use common;

function main() {


  declare \
    source_org \
    target_org \
    total_repo_list \
    filter_repos;

  declare extra_gitpod_msg="Maybe you need to readjust scopes on https://gitpod.io/variables
Also make sure Gitpod is allowed on third-party access on your ORG(s)";

  # Install gh CLI if missing
  if ! command::exists gh; then {
    log::info "Installing gh CLI";
    PIPE="| tar --strip-components=1 -C /usr -xpz" \
      dw "/usr/bin/gh" "https://github.com/cli/cli/releases/download/v2.20.0/gh_2.20.0_linux_amd64.tar.gz"; 
  } fi
  # Install fzf CLI if missing
  if ! command::exists fzf; then {
    log::info "Installing fzf CLI";
    PIPE="| tar -C /usr/bin -xpz fzf" \
      dw "/usr/bin/fzf" "https://github.com/junegunn/fzf/releases/download/0.35.0/fzf-0.35.0-linux_amd64.tar.gz"; 
  } fi
  # Install gum CLI if missing
  if ! command::exists gum; then {
    log::info "Installing gum CLI";
    PIPE="| tar -C /usr/bin -xpz gum" \
      dw "/usr/bin/gh" "https://github.com/charmbracelet/gum/releases/download/v0.8.0/gum_0.8.0_linux_x86_64.tar.gz"; 
  } fi
  
  # Print info
  declare repo="$(git -C "${GITPOD_REPO_ROOT:-.}" config --get remote.origin.url)";
  declare default_repo="https://github.com/gitpod-samples/tool-transfer-org-repos";
  : "${repo:="$default_repo"}";
  printf "${ORANGE}\$${RC} %s\n" \
    "$___self_NAME - v${___self_VERSION}" \
    "With this tool you can interactively filter out and choose repos to transfer" \
    "Please ensure that all the prerequisites are met: $(echo -e "${ORANGE}${repo}#prerequisites${RC}")";
  read -n 1 -r -p "$(echo -e ">> Press ${BGREEN}Enter${RC} to continue...")";

  # Login into GitHub if needed
  if ! gh auth status >/dev/null 2>&1; then {
    log::info "Trying to login into gh CLI";
    declare token;
    token="$(printf '%s\n' host=github.com | gp credential-helper get | awk -F'password=' '{print $2}')" || {
      log::error "Failed to retrieve Github auth token from 'gp credential-helper'" || exit;
    };
    printf '%s\n' "$token" | gh auth login --with-token || {
      log::error "Failed to login to Github via gh CLI. $extra_gitpod_msg" || exit;
    };
  } fi

  source_org="$(get_input "source_org" "Enter the source org name to move repos from (e.g. gitpod-io)")";
  target_org="$(get_input "target_org" "Enter the target org name (e.g. gitpod-samples)")";

  log::info "Checking if you got admin permissions on $source_org";
  declare query && query="$(
    gh api graphql -F login="${source_org}" -f query='
      query ($login: String!) {
        organization(login: $login) {
          viewerCanAdminister
        }
      }
    ' --jq '.data.organization.viewerCanAdminister'
  )"

  if test "$query" != true; then {
    log::error "You do not have, $extra_gitpod_msg" 1 || exit;
  } fi

  log::info "Checking if you got repository creation permissions on $target_org";
  declare query && query="$(
    gh api graphql -F login="${target_org}" -f query='
      query ($login: String!) {
        organization(login: $login) {
          viewerCanCreateRepositories
        }
      }
    ' --jq '.data.organization.viewerCanCreateRepositories'
  )"

  if test "$query" != true; then {
    log::error "You do not have, $extra_gitpod_msg" 1 || exit;
  } fi

  log::info "Retrieving repository list from $source_org";
  total_repo_list=(
    $(gh api graphql --paginate -F login="${source_org}" -f query='
      query($endCursor: String, $login: String!) {
      organization(login: $login) {
          repositories(first: 100, after: $endCursor) {
            pageInfo { hasNextPage endCursor }
            nodes { name }
          }
        }
      }' --jq '.[].organization.repositories.nodes[].name'
    )
  );

  filter_repos=($(
    filter="$(
      printf '%s\n' "${total_repo_list[@]}" | \
        fzf --ansi --print-query \
          --prompt "[1/2] Provide a filter keyword, then press $(echo -e "${BGREEN}Enter${RC}") > " | head -n1
    )";

    if test -z "$filter"; then {
      log::error "You did not provide a filter key" 1 || exit;
    } fi

    filter=($(printf '%s\n' "${total_repo_list[@]}" | fzf --filter "$filter")) || {
      log::error "Your filter didn't match anything!" || exit;
    };


    log::info "[2/2] You can press ${BRED}Space${RC} to unselect, proceed by pressing ${BGREEN}Enter${RC}" >&2;
    filter_string="${filter[*]}";
    printf '%s\n' "${filter[@]}" | \
      GUM_CHOOSE_SELECTED="${filter_string// /,}" gum choose --no-limit --height 20;

  )) || exit;


  declare keyPress filter_string;
  filter_string="$(echo -e "${YELLOW}${filter_repos[*]}${RC}")";
  read -r -n 1 -p "$(echo -e ">> Press ${BGREEN}Enter${RC} to start the transfer of selected repos: ${filter_string// /, }")" keyPress;

  printf '\n';

  log::info ">> Confirm once again by typing ${BRED}transfer${RC}";
  keyPress="$(gum input --placeholder 'Type ...')";
  if test "${keyPress:-}" != "transfer"; then {
    log::error 'You did not type ${BRED}transfer${BRED}, quitting' 1 || exit;
  } fi

  declare repo;
  for repo in "${filter_repos[@]}"; do {
    log::info "Issuing transfer of ${source_org}/${repo} to $target_org \c";

    printf '{"new_owner":"%s"}' "$target_org" | \
      gh api -X POST "repos/${source_org}/${repo}/transfer" --input - 1>/dev/null || {
      log::error "Failed to move $repo, ensure you have correct permissions" || exit;
    };

    echo -e "${BGREEN}[OK]${RC}";
  } done

}

