# git-repos-updater

Shell script for update all git repositories placed in specified folder

### Purposes:

This script helps to automatically update all repositories located in a specific folder from remote repositories.

This is typically needed in a situation where you have many repositories cloned locally into a folder, such as a collection of various utilities, and you want to update all repositories to the latest version from a remote repository.

![alt text](./repos.png "Repos List in Finder")

This script does three simple things on each repository in the source folder:

> git fetch --all
> 
> git reset --hard HEAD
> 
> git pull

### That's all!

*It works with GitHub, GitLab, BitBucket or your remote Git Server.

### Important!

get reset --hard HEAD removes all changes made so far locally! 

Be careful not to lose your data!

It is recommended to apply this script only to collections of local repositories that are not actively edited.

### Usage:

- Clone this repository
- Run 'bash update.sh <Path to your repositories folder>', aka this, and wait:

> bash update.sh "/Volumes/Transcend/repos"

- Bingo!

![alt text](./terminal.png "Terminal")

## Related projects:

Also I use [github-starred-repos-loader](https://github.com/bormaxi8080/github-starred-repos-loader) and [github-starred-repos-builder](https://github.com/bormaxi8080/github-starred-repos-builder) scripts to pull my starred GitHub collected repos locally and generates repos description in Markdown format.
