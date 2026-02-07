
## (in ~/) Init ~ dir for git & pull these dotfiles (overwriting):

```
git init && \
git remote remove origin 2>/dev/null || true && \
git remote add origin https://github.com/wiresv/dotfiles.git && \
git fetch origin && \
git checkout -B main origin/main && \
git pull
```
