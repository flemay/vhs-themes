# VHS Themes

**VHS Themes** generates and hosts a gallery showcasing ~280 themes from [charmbracelet/vhs](https://github.com/charmbracelet/vhs).

## Themes

Visit the branch [themes](../themes/) for viewing the complete list.

| | |
|:--:|:--:|
| ![3024 Day](../themes/records/3024%20Day.gif)<br>3024 Day | ![3024 Night](../themes/records/3024%20Night.gif)<br>3024 Night |

## Requirements

- VHS comes with ~280 themes. Recording and publishing them should be done in less than [6 hours with GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/usage-limits-billing-and-administration#usage-limits)
	- The shorter the better
- Same remote contents should not be generated and published unless forced
- Keep the size of the repository consistent over time by
	- Publishing records to a dedicated orphan branch (that is deleted beforehand)
- Viewing the records in a browser should be a good experience
	- Good balance between the number of records per page (loading time) versus the total number of pages to navigate
- Logs should be useful but concise so that generating 280 records won't create zillions of lines
- A single record should
	- Be good enough to view the theme (ie: font size, content, and time)
	- Be as small as possible which saves GitHub repository size, and time to record and publish
- Commands should run the same way
	- Locally as well as with GitHub Actions
	- For a private or public repository

## Prerequisites

This project follows the [3 Musketeers](https://github.com/flemay/3musketeers) pattern

- [Docker](https://www.docker.com/)
- [Compose](https://docs.docker.com/compose/)
- [Make](https://www.gnu.org/software/make/)
- [GitHub account](https://github.com/)
- [GitHub fine-grained personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#fine-grained-personal-access-tokens)
	- Token access
		- Only select repositories
		- Contents: Read and Write
		- Metadata: Read-only

## Development

```bash
# Create a .env file and modify it with the correct values
# All variables are required but does not mean they are all used at once
make envfile
# Install dependencies
make deps
# Run the test (record and page)
make test
# Generate records
make record
# Create markdown pages
make page
# Test end-to-end (record, page, publish, and download)
# Requires GitHub token
make testE2E
# Publish the contents to a dedicated publish branch
# Requires GitHub token
make publish
# Download remote contents
# This is useful if minor change needs to be done without the need of recording
make download
# Check if remote and local contents are the same (based on metadata)
make checkMetadata
# Access shell container. Useful for testing/troubleshooting scripts
make shell
# Prune the current dir from generated files
make prune
```

## Contributing

Contributions are greatly appreciated and here are different ways

1. :star: [Star it][linkProjectRepo]!
1. :mega: Share with your friends!
1. :thought_balloon: Feedback! Is there anything from the project that is not clear or missing? Let us know by filing an [issue][linkProjectIssue].
1. :computer: Contributing code! The project follows the typical [GitHub pull request][linkGitHubPR] model. Before starting any work, please either comment on an existing [issue][linkProjectIssue], or file a new one.
	1. [Fork][linkGitHubFork] this [repository][linkProjectRepo]
	1. Clone the forked repository
	1. _Optionally_, create a new branch with a meaningful name
	1. Make your changes
	1. Depending on your changes, run `make test` and/or `make testE2E`
	1. Commit and push your changes
	1. Create a [pull request from a fork][linkGitHubPRFork]

[linkProjectRepo]: https://github.com/flemay/vhs-themes
[linkProjectReadmeTest]: https://github.com/flemay/vhs-themes#testing
[linkProjectIssue]: https://github.com/flemay/vhs-themes/issues

[linkGitHubPR]: https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests
[linkGitHubFork]: https://help.github.com/en/github/getting-started-with-github/fork-a-repo
[linkGitHubPRFork]: https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork

## References

- [VHS](https://github.com/charmbracelet/vhs)
- [gum](https://github.com/charmbracelet/gum)
- [ShellCheck](https://www.shellcheck.net/)
- [Docker](https://www.docker.com/)
- [Compose](https://docs.docker.com/compose/)
- [Make](https://www.gnu.org/software/make/)
- [GitHub](https://github.com/)
- [Storing Images and Demos in your Repo](https://gist.github.com/joncardasis/e6494afd538a400722545163eb2e1fa5)
- [Calculate an MD5 Checksum of a Directory in Linux](https://www.baeldung.com/linux/directory-md5-checksum)

## License

[MIT](LICENSE)
