# Scrapple
A Ruby gem that crawls Apple's developer documentation.

## Introduction
Scrapple aims to crawl Apple's developer documetation as listed [here](https://developer.apple.com/documentation/technologies). Once complete and working, it'll be released as a Ruby gem.

## Installation
Download this repo locally, then navigate to it on your machine:

```bash
$ cd location/of/scrapple
```

Install the gem file:

```bash
$ bundle install
```

And also ensure you've got `geckodriver` and Firefox are both installed. To check if you've got `geckodriver` installed from Homebrew, run:

```bash
$ which geckodriver
```

That should give the location if you've got it.

## Running the Crawler
Simply run `ruby scrapple.rb`. Ensure you're at that location on your machine as well (i.e. `~/scrapple/lib`).

## Current Progress

- [X] Get all frameworks listed
- [ ] Parse the framework's symbols one by one
- [ ] Output it all to .json
