# Configuration

Customize your Hackatime setup to get the most accurate time tracking.

## Project Mapping

Map your local project folders to GitHub repositories for better insights:

1. Go to [Projects](/my/projects)
2. Click on a project name
3. Enter the GitHub repository URL
4. Save your changes

This helps link your coding time to specific repositories and enables features like:
* Repository links in leaderboards
* Better project organization
* Integration with GitHub stats

## Time Zone

Set your correct time zone in [Settings](/my/settings) to ensure accurate daily/weekly statistics.

## Privacy Settings

### What Gets Tracked

Hackatime tracks:
* **File names and paths** (for project detection)
* **Programming languages**
* **Editors used**
* **Time spent coding**

### What Doesn't Get Tracked

Hackatime **never** tracks:
* File contents or code
* Keystrokes
* Screenshots
* Passwords or sensitive data

## WakaTime Configuration

You can also configure the WakaTime plugin directly:

### Exclude Files

Create a `.wakatime-project` file in your project root:

```
[settings]
debug = false
hidefilenames = false
exclude = 
    ^/var/
    \.log$
    /node_modules/
    /vendor/
```

### Include Only Specific Files

```
[settings]
include_only_with_project_file = true
```

## API Configuration

For advanced users, you can configure the API endpoint in your WakaTime settings:

* **API URL**: `https://hackatime.hackclub.com/api/hackatime/v1`
* **Timeout**: 30 seconds (default)

## Need Help?

If you need assistance with configuration, reach out in [Hack Club Slack](https://hackclub.slack.com) or check our [troubleshooting guide](/docs/getting-started/troubleshooting).
