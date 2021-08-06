# github-action-add-issue-to-project

[docker]: https://hub.docker.com/r/srggrs/assign-one-project-github-action
[license]: https://github.com/srggrs/assign-one-project-github-action/blob/master/LICENSE

Automatically add an issue or pull request to specific [GitHub Project](https://help.github.com/articles/about-project-boards/) when you __create__ and/or __label__ them. By default, the issues are assigned to the `To do` column and the pull requests to the `In progress` one, so make sure you have those columns in your project dashboard. But the workflow allowed you to specify the column name as input, so you can assign the issues/PRs based on a set of conditions to a specific column of a specific project. You can also specify repository topics and it will check if the repository has that topic and will add it to the project you specify.

## Inputs

#### `project or project1 and project2`

The url of the project to be assigned to.

#### `topic1 and topic2`

The string of the topic to check for. **Required** if you are using the project1 and project 2 inputs.

#### `column_name`

**Optional**: The column name of the project, defaults to `'To do'` for issues and `'In progress'` for pull requests.

## Example usage

Examples of action:

### Repository project

```yaml
name: Auto Assign to Project(s)

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
        project: 'https://github.com/{user}/{repository-name}/projects/2'
        column_name: 'Backlog'

    - name: Assign issues and pull requests with `bug` label to project 3
      uses: Senzing/github-action-add-issue-to-project@1.0.0
      if: |
        contains(github.event.issue.labels.*.name, 'bug') ||
        contains(github.event.pull_request.labels.*.name, 'bug')
      with:
        project: 'https://github.com/{user}/{repository-name}/projects/2'
        column_name: 'Labeled'
```

#### __Notes__
Be careful of using the conditions above (opened and labeled issues/PRs) because in such workflow, if the issue/PR is opened and labeled at the same time, it will be assigned to __both__ projects!


You can use any combination of conditions. For example, to assign new issues or issues labeled with 'mylabel' to a project column, use:
```yaml
...

if: |
  github.event == 'issue' &&
  (
    github.event.action == 'opened' ||
    contains(github.event.issue.labels.*.name, 'mylabel')
  )
...
```

### Organization or User project

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
        project: 'https://github.com/org/{org-name}/projects/2'

    - name: Assign issues and pull requests with `bug` label to project 3
      uses: srggrs/assign-one-project-github-action@1.2.1
      if: |
        contains(github.event.issue.labels.*.name, 'bug') ||
        contains(github.event.pull_request.labels.*.name, 'bug')
      with:
        project: 'https://github.com/org/{org-name}/projects/3'
        column_name: 'Labeled'
```

### Using topics

Generate a token from the Organization settings or User Settings and add it as a secret in the repository secrets as `MY_GITHUB_TOKEN`.
Under 'env:' add the "REPO_URL" variable and use the project1, project2, topic1, and topic2 inputs. If the repository has topic1 then it will be put in project1 and topic2 will be put in project2. If you are using "column_name" make sure that both repositories have that column

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
        project1: 'https://github.com/org/{org-name}/projects/2'
        project1: 'https://github.com/org/{org-name}/projects/4'
        topic1: 'my-topic1`
        topic2: 'my-topic2'
        column_name: 'Backlog'
```

## Acknowledgment & Motivations

This action has been modified from the action from [srggrs](https://github.com/srggrs/assign-one-project-github-action).
