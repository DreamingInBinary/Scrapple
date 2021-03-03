# Scrapple
A Ruby gem that crawls Apple's developer documentation.

## Introduction
Scrapple aims to crawl Apple's developer documetation as listed [here](https://developer.apple.com/documentation/technologies). Once complete and working, it'll be released as a Ruby gem. It's starting point was based off of NSHipster's [`NoOverviewAvailable.com`](https://www.nooverviewavailable.com).

## Installation
Download this repo locally, then navigate to it on your machine:

```bash
$ cd location/of/scrapple
```

Install the gem file:

```bash
$ bundle install
```

And also ensure you've got `geckodriver` and Firefox installed. To check if you've got `geckodriver` installed from Homebrew, run:

```bash
$ which geckodriver
```

That should give the location if you've got it.

## Running the Crawler
Simply run `ruby scrapple.rb`. Ensure you're at that location on your machine as well (i.e. `~/scrapple/lib`).

## Current Progress

- [X] Get all frameworks listed
- [ ] Iterate through all of the frameworks to...
- [ ] Parse the framework's symbols one by one
- [ ] Output it all to .json
- [ ] Create a `CLI` for it
- [ ] Release it as a Ruby gem

### FAQ

> How does this work?

Scrapple uses Nokogiri to load up the docs are parse them. For help with getting started with it, visit this [tutorial](http://ruby.bastardsbook.com/chapters/html-parsing/) or its own [docs](https://nokogiri.org/rdoc/Nokogiri/XML/Node.html).

> What's happening in `def parse(response, url:, data: {})`?

Scrapple receives the initial set of HTML of Apple's docs. It's matched here:
`response.css('div.card__content p')`
Which gives us a list of all of the frameworks. **This is the error prone part, as Apple could change their HTML of this page at anytime.** As such, this will have to be updated a few times a year most likely. The `framework` object we get back is a Nokogiri `Node`.
