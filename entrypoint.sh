#!/usr/bin/env bash

PROJECT_URL="$INPUT_PROJECT"
PROJECT1_URL="$INPUT_PROJECT1"
PROJECT2_URL="$INPUT_PROJECT2"
TOPIC1="$INPUT_TOPIC1"
TOPIC2="$INPUT_TOPIC2"

if [ "$PROJECT_URL" ]; then
  if [ "$PROJECT1_URL" ] || [ "$PROJECT2_URL" ]; then
    echo "Use the correct set of project inputs." >&2
    exit 1
  fi
fi

if [ -z "$PROJECT1_URL" ] && [ "$PROJECT2_URL" ]; then
  echo "PROJECT1_URL is not defined." >&2
  exit 1
fi

if [ -z "$PROJECT2_URL" ] && [ "$TOPIC2" ]; then
  echo "PROJECT2_URL is not defined." >&2
  exit 1
fi

if [ -z "$TOPIC1" ] && [ "$PROJECT1_URL" ]; then
  echo "topic1 is not defined" >&2
  exit 1
fi

if [ "$PROJECT1_URL" ] && [ "$PROJECT2_URL" ]; then
  if [ -z "$TOPIC1" ] || [ -z "$TOPIC2" ]; then
    echo "2 topics must be defined." >&2
    exit 1
  fi
fi

if [ -z "$PROJECT2_URL" ] && [ -z "$PROJECT1_URL" ] && [ -z "$PROJECT_URL" ]; then
  echo "No PROJECT_URL defined." >&2
  exit 1
fi

get_project_type() {
  _PROJECT_URL="$1"

  case "$_PROJECT_URL" in
    https://github.com/orgs/*)
      echo "org"
      ;;
    https://github.com/users/*)
      echo "user"
      ;;
    https://github.com/*/projects/*)
      echo "repo"
      ;;
    *)
      echo "Invalid PROJECT_URL: $_PROJECT_URL" >&2
      exit 1
      ;;
  esac
  unset _PROJECT_URL
}

find_project_id() {
  if [ "$PROJECT_URL" ]; then
    _PROJECT_TYPE="$1"
    _PROJECT_URL="$2"
  fi

  case "$_PROJECT_TYPE" in
    org)
      # shellcheck disable=SC2001
      _ORG_NAME=$(echo "$_PROJECT_URL" | sed -e 's@https://github.com/orgs/\([^/]\+\)/projects/[0-9]\+@\1@')
      _ENDPOINT="https://api.github.com/orgs/$_ORG_NAME/projects"
      ;;
    user)
      # shellcheck disable=SC2001
      _USER_NAME=$(echo "$_PROJECT_URL" | sed -e 's@https://github.com/users/\([^/]\+\)/projects/[0-9]\+@\1@')
      _ENDPOINT="https://api.github.com/users/$_USER_NAME/projects"
      ;;
    repo)
      _ENDPOINT="https://api.github.com/repos/$GITHUB_REPOSITORY/projects"
      ;;
  esac

  _PROJECTS=$(curl -s -X GET -u "$GITHUB_ACTOR:$TOKEN" --retry 3 \
           -H 'Accept: application/vnd.github.inertia-preview+json' \
           "$_ENDPOINT")

  _PROJECTID=$(echo "$_PROJECTS" | jq -r ".[] | select(.html_url == \"$_PROJECT_URL\").id")

  if [ "$_PROJECTID" != "" ]; then
    echo "$_PROJECTID"
  else
    echo "No project was found." >&2
    exit 1
  fi

  unset _PROJECT_TYPE _PROJECT_URL _ORG_NAME _USER_NAME _ENDPOINT _PROJECTS _PROJECTID
}

find_column_id() {
  _PROJECT_ID="$1"
  _INITIAL_COLUMN_NAME="$2"

  _COLUMNS=$(curl -s -X GET -u "$GITHUB_ACTOR:$TOKEN" --retry 3 \
          -H 'Accept: application/vnd.github.inertia-preview+json' \
          "https://api.github.com/projects/$_PROJECT_ID/columns")

  echo "$_COLUMNS" | jq -r ".[] | select(.name == \"$_INITIAL_COLUMN_NAME\").id"
  unset _PROJECT_ID _INITIAL_COLUMN_NAME _COLUMNS
}

if [ "$PROJECT1_URL" ]; then
  _TOPICS=$(curl -s -X GET -u "$GITHUB_ACTOR:$TOKEN" --retry 3 \
              -H "Accept: application/vnd.github.mercy-preview+json" \
              "${REPO_URL}")

  a=${_TOPICS#*topics}  
  b=${a#*[}  
  topics=${b%]*}

  if echo "$topics" | grep -q "$TOPIC1"; then
    PROJECT_URL=${PROJECT1_URL}

  elif echo "$topics" | grep -q "$TOPIC2" && [ "$PROJECT2_URL" ] ; then
    PROJECT_URL=${PROJECT2_URL}

  else
    "This repository does not have a matching topic"
    exit 1

  fi
fi

curl \
  -H "Accept: application/vnd.github.mercy-preview+json" \
  https://api.github.com/


PROJECT_TYPE=$(get_project_type "${PROJECT_URL:?<Error> required this environment variable}")

if [ "$PROJECT_TYPE" = org ] || [ "$PROJECT_TYPE" = user ]; then
  if [ -z "$GITHUB_TOKEN" ]; then
    echo "GITHUB_TOKEN not defined" >&2
    exit 1

  else
    TOKEN="$GITHUB_TOKEN"    # GitHub sets. The scope in only the repository containing the workflow file.
  fi
fi

INITIAL_COLUMN_NAME="$INPUT_COLUMN_NAME"
if [ -z "$INITIAL_COLUMN_NAME" ]; then
  INITIAL_COLUMN_NAME='To do'
  if [ "$GITHUB_EVENT_NAME" == "pull_request" ] || [ "$GITHUB_EVENT_NAME" == "pull_request_target" ]; then
    echo "changing col name for PR event"
    INITIAL_COLUMN_NAME='In progress'
  fi
fi


PROJECT_ID=$(find_project_id "$PROJECT_TYPE" "$PROJECT_URL")
INITIAL_COLUMN_ID=$(find_column_id "$PROJECT_ID" "${INITIAL_COLUMN_NAME:?<Error> required this environment variable}")

if [ -z "$INITIAL_COLUMN_ID" ]; then
  echo "INITIAL_COLUMN_ID is not found." >&2
  exit 1
fi

case "$GITHUB_EVENT_NAME" in
  issues)
    ISSUE_ID=$(jq -r '.issue.id' < "$GITHUB_EVENT_PATH")

    # Add this issue to the project column
    curl -s -X POST -u "$GITHUB_ACTOR:$TOKEN" --retry 3 \
     -H 'Accept: application/vnd.github.inertia-preview+json' \
     -d "{\"content_type\": \"Issue\", \"content_id\": $ISSUE_ID}" \
     "https://api.github.com/projects/columns/$INITIAL_COLUMN_ID/cards"
    ;;
  pull_request|pull_request_target)
    PULL_REQUEST_ID=$(jq -r '.pull_request.id' < "$GITHUB_EVENT_PATH")

    # Add this pull_request to the project column
    curl -s -X POST -u "$GITHUB_ACTOR:$TOKEN" --retry 3 \
     -H 'Accept: application/vnd.github.inertia-preview+json' \
     -d "{\"content_type\": \"PullRequest\", \"content_id\": $PULL_REQUEST_ID}" \
     "https://api.github.com/projects/columns/$INITIAL_COLUMN_ID/cards"
    ;;
  *)
    echo "Nothing to be done on this action: $GITHUB_EVENT_NAME" >&2
    exit 1
    ;;
esac
