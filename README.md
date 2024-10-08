# Fuzzy Pip Matcher

## Pre-requisites

- To build and run it is advised to have docker installed, and to target the provided Dockerfile
- A Github API token needs to be issued, no special privilege is required

## Build

Build image by running:

```shell
docker build -t fuzzy-pip-matcher -f Dockerfile .
```

## Run

Run container, default argument for package is `folium`:

```shell
docker run -it --rm -e GITHUB_API_TOKEN="<your-github-api-pat>" fuzzy-pip-matcher
```

override package to search for e.g. `leaflet`:
```shell
docker run -it --rm -e GITHUB_API_TOKEN="<your-github-api-pat>" fuzzy-pip-matcher leaflet
```
