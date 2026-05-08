# Homepage maintenance

The homepage has been redesigned so routine updates can be made in Markdown only.

## What to edit

Most updates should happen in `index.md`:

- `profile`: name, title, affiliation, photo, and short biography.
- `links`: buttons in the hero area.
- `contact`: contact card on the right.
- `research_interests`: chips below the portrait.
- `highlights`: small cards near the top of the page.
- `publications`: journal and conference papers.
- `working_papers`: papers in progress.

The visual structure is handled by `_layouts/home.html`, and the style is handled by `assets/css/style.scss`. You normally do not need to edit either file when adding papers or changing profile text.

## Adding a publication

Copy one block under `publications` and edit the fields:

```yaml
  - title: "Paper title"
    url: "https://example.com/paper"
    author_prefix: "with"
    authors: "Coauthor One and Coauthor Two"
    status: "Published"
    venue: "Conference or Journal"
    year: "2026"
    conference_version: "Optional conference version"
    note: "Optional note."
```

Leave out optional fields when they do not apply.
