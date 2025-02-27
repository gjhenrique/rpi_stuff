## Synthetic checks using cronjobs

Create a Golang application that uses `github.com/robfig/cron` and a set of configuration files
to run synthetic checks.

The configuration files have the following structure:

```json
{
  prometheusRemoteWriteConfig: {
    url: "https://example.com",
    basicAuth: {
      username: "user",
      passwordFile: "/path/to/password/file"
    }
  },
  "checks": [
    {
      "name": "Check 1",
      "script": "/path/to/k6_script.js",
      "cron": "5 0 0 0 0 0",
      "writeToPrometheus": true
    },
    {
      "name": "Check 2",
      "url": "https://example.com",
      "cron": "0 0 0 0 0 0"
    }
  ]
}
```

The application should read the configuration files and schedule the checks according to the cron.
The checks can be either a script or a URL. If the check is a script, the application should run
the script using `k6 run` and store the results in a Prometheus remote write endpoint (when enabled).

If the check is a URL, the application should also use k6 to run a simple check and store the results in
Prometheus (when enabled).
