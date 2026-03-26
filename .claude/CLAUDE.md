# CLAUDE.md
## Project Overview

Play-by-Post TTRPG is a web application for asynchronous tabletop role-playing games. Game masters and players collaborate on scenes through threaded posts, with email notifications and email-to-post functionality.

## Documentation

- [Domain](../context/domain.md) concepts, data model relationships, business rules
- [product requirements](../context/pbp_ttrpg_requirements.md)

## Ruby
PATH="/opt/homebrew/opt/ruby/bin:$PATH" bundle exec ruby

## Development
    The software development cycle is:
        1. Create a testing plan for the feature or bug fix as a markdown file in the tests/integration directory.
        2. Create failing tests that describe the desired behavior
        3. Make changes to code until the tests pass
            1. Ask the product owner for requirements clarification if needed
            2. Ask the Lead Designer for design guidance if needed
            3. Ask the Technical Architect for technical guidance if needed
            4. Yield to user if requirements remain unclear
        4. Validate that all changes match the requirements
        5. Run local development server 
            1. Use chrome to verify functionality using the testing plan
        6. Make code changes until testing plan passes
        7. Confirm tests pass
        8. Lint the code

IMPORTANT: YOU MUST ALWAYS ADD TESTS FOR NEW FEATURES

## CLI Tools

- `git` - version control
- `gh` - GitHub PRs and issues
- `rails` - Ruby on Rails commands
