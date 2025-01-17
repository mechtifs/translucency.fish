# translucent

A fish prompt with pure simplicity and all good stuff from [lucid.fish](https://github.com/mattgreen/lucid.fish)

The name `translucent` comes from `transient` + `lucid`

![Preview](https://user-images.githubusercontent.com/18751876/186891523-a8a5a857-f8d4-4c3e-975e-972b7533a96c.png)


## Features

* All from [lucid.fish](https://github.com/mattgreen/lucid.fish) (almost)
* Transient prompt
* _It's sick_

## Installation

### System Requirements

* [Fish](https://fishshell.com/) ≥ 3.4.0

Manually:

* Backup your own `fish_prompt.fish` (if exists)
* Replace `fish_prompt.fish` with [the one](./functions/fish_prompt.fish) in the repo

## Performance

Please refer to [lucid.fish](https://github.com/mattgreen/lucid.fish)

## Customization

* `dirty_indicator`: displayed when a repository is dirty. Default: `*`
* `cwd_color`: color used for current working directory. Default: `brcyan`
* `git_color`: color used for git information. Default: `blue`
* `git_status_in_home_directory`: if set, git information is also displayed in the home directory. Default: not set
* `prompt_symbol`: the prompt symbol. Default: `>`
* `prompt_symbol_color`: the color of the prompt symbol. Default: `brmagenta`
* `prompt_symbol_error_color`: the color of the prompt symbol when an error occurs. Default: `grey`
* `transient_prompt_symbol_color`: the color of the transient prompt symbol. Default: `magenta`

## Known Issues

Currently, transient prompt in fish shell is still in experimental state with a few known bugs. The very solution comes from [Oh My Posh](https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/src/shell/scripts/omp.fish), while still containing some minor issues.

* Transient prompt is **NOT** working in vi binding mode
* Current solution is by repainting former prompt instantly whenever `\r` is sent, so it's not able to update from the pipe status afterwards
* Same as above, while receiving `^C` it does not repaint properly

For other issues, please refer to [lucid.fish](https://github.com/mattgreen/lucid.fish)

## License

[MIT](LICENSE)
