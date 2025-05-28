# API Endpoints

Hackatime provides both WakaTime-compatible and native API endpoints for accessing your coding data.

## Authentication

All API requests require authentication via:
- **Header**: `Authorization: Bearer YOUR_API_KEY`
- **Query Parameter**: `?api_key=YOUR_API_KEY`

Get your API key from your [Hackatime dashboard settings](https://hackatime.hackclub.com/my/wakatime_setup).

## WakaTime-Compatible Endpoints

These endpoints are compatible with existing WakaTime tools and libraries.

### Push Heartbeats
```
POST /api/hackatime/v1/users/current/heartbeats
```

Send coding activity data (what editor plugins use automatically).

**Request Body** (JSON):
```json
[{
  "type": "file",
  "time": 1640995200,
  "entity": "example.py", 
  "language": "Python",
  "project": "my-project"
}]
```

### Status Bar Data
```
GET /api/hackatime/v1/users/{user_id}/statusbar/today
```

Get today's coding time for status bar displays.

**Example Response**:
```json
{
  "data": {
    "grand_total": {
      "total_seconds": 7200.0,
      "text": "2 hrs"
    }
  }
}
```

### Dashboard Redirect
```
GET /api/hackatime/v1/
```

Redirects to the main dashboard.

## Native Hackatime API

Enhanced endpoints with additional features.

### User Statistics
```
GET /api/v1/users/{username}/stats
```

Get comprehensive coding statistics for a user.

**Example Response**:
```json
{
  "user": "username",
  "total_seconds": 86400,
  "languages": [
    {"name": "Python", "seconds": 43200},
    {"name": "JavaScript", "seconds": 28800}
  ],
  "projects": [
    {"name": "my-app", "seconds": 36000}
  ]
}
```

### Heartbeat Spans
```
GET /api/v1/users/{username}/heartbeats/spans
```

Get time spans of coding activity.

### My Heartbeats
```
GET /api/v1/my/heartbeats
GET /api/v1/my/heartbeats/most_recent
```

Access your own heartbeat data.

**Query Parameters**:
- `start` - Start date (ISO 8601)
- `end` - End date (ISO 8601)
- `limit` - Number of results (default: 100)

### Global Statistics
```
GET /api/v1/stats
```

Get platform-wide statistics (requires authentication).

### User Lookup
```
GET /api/v1/users/lookup_email/{email}
GET /api/v1/users/lookup_slack_uid/{slack_uid}
```

Look up users by email or Slack UID.

## Example Usage

### Get Your Recent Activity
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  "https://hackatime.hackclub.com/api/v1/my/heartbeats?limit=10"
```

### Send a Test Heartbeat
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[{"type":"file","time":1640995200,"entity":"test.py","language":"Python"}]' \
  "https://hackatime.hackclub.com/api/hackatime/v1/users/current/heartbeats"
```

### Get Today's Coding Time
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  "https://hackatime.hackclub.com/api/hackatime/v1/users/current/statusbar/today"
```

## Rate Limits

- **Heartbeats**: 30-second rate limit between heartbeats (configurable in `~/.wakatime.cfg`)
- **API Requests**: Reasonable usage expected; no hard limits currently enforced

## Error Responses

All errors return appropriate HTTP status codes with JSON error messages:

```json
{
  "error": "Invalid API key",
  "message": "The provided API key is invalid or expired"
}
```

Common status codes:
- `401` - Invalid or missing API key
- `404` - Resource not found
- `429` - Rate limit exceeded
- `500` - Server error

## Libraries & SDKs

Since Hackatime is WakaTime-compatible, you can use existing WakaTime libraries:

- **Python**: `wakatime-python`
- **JavaScript**: `wakatime-client`
- **Go**: `go-wakatime`
- **Ruby**: `wakatime-ruby`

Just configure them to use `https://hackatime.hackclub.com` as the base URL.
