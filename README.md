# github-action-add-issue-to-project

## Overview

The repository holds and shows example usage of the GitHub workflow that can automatically add issues and pull-requests to GitHub projects. The workflow can check labels, project columns, and repository topics to conditionally add issues or pull-requests to selected projects.

### Contents

1. [Inputs]
   1. [Projects]
   1. [Topics]
   1. [Column_name]
1. [Examples]
   1. [Repository project]
   1. [Organization or user projects]
   1. [Using topics]
1. [References]

### Legend

1. :thinking: - A "thinker" icon means that a little extra thinking may be required.
   Perhaps you'll need to make some choices.
   Perhaps it's an optional step.
1. :pencil2: - A "pencil" icon means that the instructions may need modification before performing.
1. :warning: - A "warning" icon means that something tricky is happening, so pay attention.

## Inputs

### `Projects`

:thinking: The URL of the project to be assigned to.
You must use one of the follow sets of inputs:

- project
- project1 and/or project2

### `Topics`

:thinking: The string of the topics to check for. **Required** if you are using the project1 and/or project 2 inputs.

### `Column_name`

**Optional**: The column name of the project, defaults to `'To do'` for issues and `'In progress'` for pull requests.

## Examples

### Repository project

:pencil2:

```yaml
name: Auto Assign to Project

on:
  issues:
    types: [opened, labeled]
  pull_request:
    types: [opened, labeled]
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

jobs:
  assign_one_project:
    runs-on: ubuntu-latest
    name: Assign to One Project
    steps:
      - name: Assign NEW issues or NEW pull requests to project 2
        uses: Senzing/github-action-add-issue-to-project@1.0.0
        with:
          project: "https://github.com/{user}/{repository-name}/projects/2"
          column_name: "Backlog"

      - name: Assign issues and pull requests with `bug` label to project 3
        uses: Senzing/github-action-add-issue-to-project@1.0.0
        if: |
          contains(github.event.issue.labels.*.name, 'bug') ||
          contains(github.event.pull_request.labels.*.name, 'bug')
        with:
          project: "https://github.com/{user}/{repository-name}/projects/2"
          column_name: "Labeled"
```

#### Notes

:thinking:
Be careful of using the conditions above (opened and labeled issues/PRs) because in such workflow, if the issue/PR is opened and labeled at the same time, it will be assigned to **both** projects!

You can use any combination of conditions. For example, to assign new issues or issues labeled with 'mylabel' to a project column, use:

```yaml
---
if: |
  github.event == 'issue' &&
  (
    github.event.action == 'opened' ||
    contains(github.event.issue.labels.*.name, 'mylabel')
  )
```

### Organization or User project

:pencil2:

Generate a token from the Organization settings or User Settings and add it as a secret in the repository secrets as `MY_GITHUB_TOKEN`

```yaml
name: Auto Assign to Project(s)

on:
  issues:
    types: [opened, labeled]
  pull_request_target:
    types: [opened, labeled]
env:
  MY_GITHUB_TOKEN: ${{ secrets.MY_GITHUB_TOKEN }}

jobs:
  assign_one_project:
    runs-on: ubuntu-latest
    name: Assign to One Project
    steps:
      - name: Assign NEW issues and NEW pull requests to project 2
        uses: Senzing/github-action-add-issue-to-project@1.0.0
        with:
          project: "https://github.com/org/{org-name}/projects/2"

      - name: Assign issues and pull requests with `bug` label to project 3
        uses: srggrs/assign-one-project-github-action@1.2.1
        if: |
          contains(github.event.issue.labels.*.name, 'bug') ||
          contains(github.event.pull_request.labels.*.name, 'bug')
        with:
          project: "https://github.com/org/{org-name}/projects/3"
          column_name: "Labeled"
```

### Using topics

:pencil2: Generate a token from the organization settings or User Settings and add it as a secret in the repository secrets as `MY_GITHUB_TOKEN`.
Under 'env:' add the "REPO_URL" variable and use the project1, project2, topic1, and topic2 inputs. If the repository has topic1 then it will be put in project1 and topic2 will be put in project2. If you are using the "column_name" input make sure that both projects have that column.

```yaml
name: Auto Assign to Project

on:
  issues:
    types: [opened, labeled]
  pull_request_target:
    types: [opened, labeled]
env:
  MY_GITHUB_TOKEN: ${{ secrets.MY_GITHUB_TOKEN }}
  REPO_URL: ${{ github.event.repository.url}}

jobs:
  assign_one_project:
    runs-on: ubuntu-latest
    name: Assign to One Project
    steps:
      - name: Check for repository topics and add to project based on topic
        uses: Senzing/github-action-add-issue-to-project@1.0.0
        with:
          project1: "https://github.com/org/{org-name}/projects/2"
          project2: "https://github.com/org/{org-name}/projects/4"
          topic1: "my-topic1"
          topic2: "my-topic2"
          column_name: "Backlog"
```

## References

1. GitHub workflow
   1. [Documentation]
   1. [GitHub Actions]
1. Inspiration
   1. [GitHub]

[Column_name]: #column_name
[Documentation]: https://docs.github.com/en/rest/reference/actions
[Examples]: #examples
[GitHub Actions]: https://github.com/features/actions
[GitHub]: https://github.com/srggrs/assign-one-project-github-action
[Inputs]: #inputs
[Organization or user projects]: #organization-or-user-project
[Projects]: #projects
[References]: #references
[Repository project]: #repository-project
[Topics]: #topics
[Using topics]: #using-topics
