# Beautiful Markdown Homepage

A cleaner, more polished academic homepage that is still easy to maintain with **Markdown** and deploy on **GitHub Pages**.

## What you edit

For everyday updates, edit only:

- `index.md`

## Structure

- `index.md` — content (bio, research, publications, etc.)
- `_layouts/home.html` — site template
- `assets/styles.css` — visual design
- `assets/script.js` — mobile menu, section cards, publication search
- `_config.yml` — GitHub Pages / Jekyll config

## Quick editing guide

### Update profile info
Edit the YAML block at the top of `index.md`:

```yaml
name: Yixin Tao
role: Assistant Professor
affiliation: Institute of Theoretical Computer Science, Shanghai University of Finance and Economics
email: taoyixin@mail.shufe.edu.cn
location: Shanghai, China
```

### Add a publication
In the `## Publications` section, add another Markdown list item:

```md
1. **Paper title.**  
   Authors. *Conference / Journal*, Year.  
   [Paper](https://example.com)
```

## Deploy to GitHub Pages

1. Create or open your GitHub Pages repository.
2. Upload all files in this folder to the repository root.
3. In GitHub settings, enable Pages for the default branch.
4. GitHub Pages will build the site automatically.

## Local preview

If you have Ruby/Jekyll installed:

```bash
bundle exec jekyll serve
```

Or simply upload to GitHub Pages directly.
