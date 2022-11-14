use std::print::log;
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
  if ! command -v gh 1>/dev/null; then {
    log::info "Installing gh CLI";
    PIPE="| tar --strip-components=1 -C /usr -xpz" \
      dw "/usr/bin/gh" "https://github.com/cli/cli/releases/download/v2.20.0/gh_2.20.0_linux_amd64.tar.gz"; 
  } fi
  
  # Login into Github
  if ! gh auth status 1>/dev/null; then {
    log::info "Trying to login into gh CLI";
    declare token;
    token="$(printf '%s\n' host=github.com | gp credential-helper get | awk -F'password=' '{print $2}')" || {
      log::error "Failed to retrieve Github auth token from 'gp credential-helper'" || exit;
    };
    printf '%s\n' | gh auth login --with-token || {
      log::error "Failed to login to Github via gh CLI.
Maybe you need to readjust scopes on https://gitpod.io/variables
Also make sure Gitpod is allowed on third-party access on your ORG(s)" || exit;
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
        fzf --print-query \
          --prompt "[1/2] Provide a filter keyword, then press enter > " | head -n1
    )";

    if test -z "$filter"; then {
      log::error "You did not provide a filter key" 1 || exit;
    } fi

    filter=($(printf '%s\n' "${total_repo_list[@]}" | fzf --filter "$filter")) || {
      log::error "Your filter didn't match anything!" || exit;
    };


    log::info "You can press 'space' to unselect" >&2;
    filter_string="${filter[*]}";
    printf '%s\n' "${filter[@]}" | \
      GUM_CHOOSE_SELECTED="${filter_string// /,}" gum choose --no-limit --height 20;

  )) || exit;


  declare keyPress;
  read -r -n 1 -p ">> Press Enter or Return to start the transfer of selected repos: ${filter_repos[*]}" keyPress;

  declare repo;
  for repo in "${filter_repos[@]}"; do {
    printf '{"new_owner":"%s"}' "$target_org" | \
      gh api -X POST "repos/${source_org}/${repo}/transfer" --input - || {
      log::error "Failed to move $repo, ensure you have correct permissions" || exit;
    };
  } done

}

