# Tasks

## To do

- Change logged in menu mobile and web for when logged in
- Go over every page in mobile
- Fix Tailwind and assets generation in DEV for real time without restarting rails support
- Anchor menu so it does not scroll
- Increase padding of standings table on lg mode for better readibility
- Refresh admin page when open or close are run
- Make a chart out of the simulation distribution page
- Add teams and single team view
- Paginate matches
- Start name sorting ascending
- Make a graph out of th simulation distribution page
- Add teams and single team view
- Paginate matches
- Start name sorting ascending
Data:
- Rename teams via Rake (keep imports up to date)
- Import Serie B
Technical:
- Adopt https://github.com/ankane/ahoy for metrics
- Simplify link sorting in a single helper
- Concern for standings
- Cache team logos locally
- Add sorbet
- Move to use SQL so that the materialization view works well without the need to put it on seeds.rb

## Milestone 2
- Improve look and feel
- Support to multiple competitions
- Restructure simulation to be discrete in the positions
- Show different probabilities for different milestones on standings

# Extra
- Take out node and yarn and use importmaps
- Deployment with Kamal

## Thoughts
- Minitest
- Create a client at lib/clients
