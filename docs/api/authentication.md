# Authentication

Learn how to authenticate with the Hackatime API.

## API Key

All API requests require authentication using your personal API key.

### Getting Your API Key

1. Log in to [Hackatime](/)
2. Go to [Settings](/my/settings)
3. Copy your API key from the settings page

### Using Your API Key

Include your API key in the Authorization header:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     https://hackatime.hackclub.com/api/v1/stats
```

## Alternative Authentication Methods

### Query Parameter

You can also pass your API key as a query parameter:

```bash
curl "https://hackatime.hackclub.com/api/v1/stats?api_key=YOUR_API_KEY"
```

**Note**: Using the Authorization header is recommended for security.

## Testing Authentication

Test your API key with a simple request:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     https://hackatime.hackclub.com/api/v1/stats
```

A successful response will look like:

```json
{
  "data": {
    "total_seconds": 12345,
    "languages": [...],
    "editors": [...]
  },
  "success": true
}
```

## Error Responses

### Invalid API Key

```json
{
  "error": "Invalid API key",
  "success": false
}
```

### Missing API Key

```json
{
  "error": "API key required",
  "success": false
}
```

## Rate Limiting

* **Authenticated requests**: 100 per minute
* **Unauthenticated requests**: 10 per minute

Rate limit headers are included in responses:
* `X-RateLimit-Limit`: Your rate limit
* `X-RateLimit-Remaining`: Requests remaining
* `X-RateLimit-Reset`: Unix timestamp when limit resets

## Security Best Practices

* **Never commit API keys** to version control
* **Use environment variables** to store API keys
* **Rotate keys regularly** if they may be compromised
* **Use HTTPS** for all API requests

## Need Help?

If you're having authentication issues, check:
1. Your API key is correct
2. You're using the right API endpoint
3. Your request headers are properly formatted

Still stuck? Reach out in [Hack Club Slack](https://hackclub.slack.com)!
