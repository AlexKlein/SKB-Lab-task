#SKB-LAb task

This task from SKB-Lab for check my knowledge in Oracle PL/SQL and SQL

## [Documentation for this task and logical model](./doc)

## Installing

If you want to install and check this task, so you need follow that sequence of installation:

```
- Tables
- Sequence
- Package
- Queries
```

#Patch

When you need to install only patch, then you make this steps:
1. `git log --graph --abbrev-commit --decorate --all --oneline` - you will see all commits in your repository
2. `https://github.com/username/projectname/archive/commitshakey.zip` - link for downloading commit, if you have the long hash key, just get the first 7 chars
3. `git diff --patch <commit1> <commit2> --stat` - you will see list of modified objects
4. copy modified files in a directory to install
Notice: Oracle objects like tables you need to commit in repository action by action. For example, the first commit - create table, next commits - alter table.

#Installer for Oracle objects inside

You need to download [GitBash](https://git-scm.com/download/win) tool for executing shell script "installer.sh", if your operation system is Windows.
The script dynamically creates script and installs objects in preset order. Also, you need to install sqlplus tool on a computer.