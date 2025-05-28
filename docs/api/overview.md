# API Overview

The Hackatime API is compatible with WakaTime's API, allowing you to access your coding time data programmatically.

## Quick Start

Get your API key from your Hackatime dashboard settings, then make requests to:

```
https://hackatime.hackclub.com/api/v1/
```

## Authentication

Include your API key in requests using either method:

**Authorization Header** (recommended):
```
Authorization: Bearer YOUR_API_KEY
```

**Query Parameter**:
```
?api_key=YOUR_API_KEY
```

## Basic Example

Get your coding stats:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://hackatime.hackclub.com/api/v1/users/current/stats
```

## WakaTime Compatibility

Since Hackatime is compatible with WakaTime's API, you can:
- Use existing WakaTime libraries and SDKs
- Point WakaTime tools to `https://hackatime.hackclub.com`
- Import/export data between services

## Common Endpoints

- **User Stats**: `/api/v1/users/current/stats` - Your coding statistics
- **Heartbeats**: `/api/v1/users/current/heartbeats` - Raw activity data
- **Leaderboard**: `/api/v1/leaders` - Community leaderboard data

For detailed endpoint documentation, refer to the [WakaTime API docs](https://wakatime.com/developers) - most endpoints work identically with Hackatime.
