# VHS Themes

**VHS Themes** generates and hosts a gallery showcasing ~350 themes from [charmbracelet/vhs](https://github.com/charmbracelet/vhs).

## Themes

Visit the branch [themes](../themes/) for viewing the complete list.

| | |
|:--:|:--:|
| ![3024 Day](../themes/records/3024%20Day.gif)<br>3024 Day | ![3024 Night](../themes/records/3024%20Night.gif)<br>3024 Night |

## Requirements

- VHS comes with hundreds of themes. Recording and publishing them should be done in less than [6 hours with GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/usage-limits-billing-and-administration#usage-limits)
	- The shorter the better
- Same remote contents should not be generated and published unless forced
- Keep the size of the repository consistent over time by
	- Publishing records to a dedicated orphan branch (that is deleted beforehand)
- As some file systems can be case-insensitive, records will be prefixed with a number which allows themes like `TokyoNight` and `tokyonight` to be recorded to 2 different files
- Themes with same name (case sensitive) will only be recorded once. For instance, with themes `TokyoNight`, `tokyonight`, and `tokyonight`, the second `tokyonight` theme will be ignored
- Viewing the records in a browser should be a good experience
	- Good balance between the number of records per page (loading time) versus the total number of pages to navigate
- Logs should be useful but concise so that generating many records won't output zillions of lines
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

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md)

## License

[MIT](LICENSE)
