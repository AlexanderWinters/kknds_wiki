from webhook.app import WEBHOOK_SECRET

# Development
I will look through tools that I use for softdev. 

## Python

Most of the times in python you will need to work in a virtual environment. To create one:

```bash
python -m venv C:\path\to\new\virtual\environment
```

To activate an environment:

```bash
source <venv>/bin/activate
```

To deactivate:

```bash
deactivate
```

## Web Development with Python

[Streamlit](https://docs.streamlit.io/) is a simple Python framework for web dev.
There is also [Flask](https://flask.palletsprojects.com/en/stable/), [Django](https://docs.djangoproject.com/en/5.1/), and [FastAPI](https://fastapi.tiangolo.com/)

# GIT
:::info
As of 2025, February the 2nd, Git has a market share of 87.53%. It's probably the most used tool in all of the tech industry (maybe even outside). Here are some advanced concepts that make working with GIT 10x better.
:::
## GIT History

`git log` is a list of all the commits in a repo, but it's a bit hard to read. To make it look a little nicer:

```bash
git log --graph --decorate --oneline
```

## Commit Amend

Change the contents of a commit; can be used to just change the message as well.

```bash
git commit --amend -m "this is an amendement to the latest commit"
```

If you want to just add files, and not change the message:

```bash
git commit --amend --no-edit
```

## Reverting

If you have commited and pushed some code that you have changed your mind on, you can revert to a previous commit. Before reverting, you will need to find the name of the commit from the logs:

```bash
git log --oneline
git revert <commit_hash>
```

## Stashing

Sometimes code is too sloppy or just not good enough to commit, but we still want to keep it. Stash will remove the changes in your working directory and save them for later:

```bash
git stash
```

To add the changes back:

```bash
git stash pop
```

If you use stashing a lot, you can save your stashes with names so they are easier to find and navigate:

```bash
git stash save <awesome_name>
```

And then you can list the stashes and apply them with their corresponding indeces:

```bash
git stash list
git stash apply 0
```

## Binary Search (Bisect)

Sometimes code breaks without realization, or you might want to look for something specific in your code. Git can do a binary search through your commits. Git will changes the commits for you until you find what you were looking for. Practically, let's assume there is a bug in our and you want to find it. You will first need to start a binary search with:

```bash
git bisect start
```

Then you will need to point to GIT to the latest bad commit, and the latest good commit:

```bash
git bisect bad # The current commit is the bad 
git bisect good vd32401d # Commit vd32401d is the known good
```

The Git will select a commit in between these two commits and apply it to your working directory. You can test your project and then tell Git whether this is a good commit or a bad commit with:

```bash
git bisect bad || git bisect good
```

Once the search is done, Git will output a log with the commit that it found. After you are done, you will want to return to the original HEAD (latest commit):

```bash
git bisect reset
```

## Squashing

Squashing is used to combine several commits into one. It is especially useful when a feature needs to be rebased to the main branch. We can use an interactive rebase to squash everything together:

```bash
git rebase main --interactive
```

Otherwise, you can retroactively flag commits with the `--squash` flag so when you merge or rebase, git will automatically squash the commits for you. To flag a commit:

```bash
git commit --squash
```

And then run a rebase with the `--autosquash` flag so Git will handle all the squashing automagically:

```bash
git rebase -i --autosquash
```

## Remove files from git without deleting

```bash
git rm --cached .
```

If you want to remove a specific file, replace the dot with the file path.

## Delete all git history without resetting repo

Deleting the .git folder may cause problems in your git repository. If you want to delete all your commit history but keep the code in its current state, it is very safe to do it as in the following:

Checkout

```bash
git checkout --orphan latest_branch
```

Add all the files

```bash
git add -A
```

Commit the changes

```bash
git commit -am "commit message"
```

Delete the branch

```bash
git branch -D main
```

Rename the current branch to main

```bash
git branch -m main
```

Finally, force update your repository

```bash
git push -f origin main
```

## Git Hooks

When making an operation with Git like pushing, pulling, committing, etc, it creates an event and you use Hooks to run code before or after an event. If you open the `.git` folder, you will find a `hooks` folder in it with all the events you can use to trigger code.

## Migrating repo

Create a temp folder locally, and start a new empty in the destination service. Then clone the repo from source as mirror, and push the mirror to destination.

```bash
git clone --mirror <source-repo-url>
cd <source-repo-name>
git push --mirror  <dest-repo-url>
```

The mirror in not readable so it can be deleted after pushing.

## CI/CD

CI/CD stands for continuous intergration and continuous development. It's a set of practices and tools
used to automate building, testing, and deploying. There are several tools out there that help coordinate
and automate builds, but I will focus on two methods/tools I use for CI/CD - webhooks, and Jenkins. 

### Webhooks
When it comes to updating text on a web server the simplest thing would be to use git and GitHub webhooks.
You can use any simple web framework to create a webhook server; I use Flask, which is in python:
```python
from flask import Flask, request
import subprocess

app = Flask(__name__)


@app.route('/webhook', methods=['POST'])
def webhook():
    # Only handle push events
    if request.headers.get('X-GitHub-Event') == 'push':
        # Run deploy script
        result = subprocess.run(
            ['bash', '/path/to/deploy.sh'],
            capture_output=True,
            text=True
        )
        return f"Deployed: {result.stdout}"

    return "OK"


if __name__ == '__main__':
    app.run(port=3000)
```

This script opens up port 3000 on your server and listens on the GitHub webhook. Since this needs to be exposed to the internet, you will need to add some safeguards:

- Signature validation
- SSL
- Tunneling

#### Signature validation 
With this validation we make sure the request comes from GitHub:
```python
import hmac
import hashlib

WEBHOOK_SECRET = "your-secret" # YOU SET THIS UP IN GITHUB

def is_valid_signature(payload_body, signature_header):
    if not signature_header:
        return False

    # Get expected signature
    expected_signature = hmac.new(
        key=WEBHOOK_SECRET.encode(),
        msg=payload_body,
        digestmod=hashlib.sha256
    ).hexdigest()

    # Compare with GitHub's signature
    # GitHub sends it in format: 'sha256=<hash>'
    return hmac.compare_digest(
        f'sha256={expected_signature}',
        signature_header
    )
```

#### SSL
Make sure the webhook server is using HTTPS. By default, GitHub allows only HTTPS requests.

#### Tunneling
As an additional protection, you can forward the traffic to your server through a tunnel. I use Cloudflare Tunnels
as it is quick easy to set up. If you use Cloudflare as your domain registrar, it has excellent [documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) on
how to set up tunnels with your web services