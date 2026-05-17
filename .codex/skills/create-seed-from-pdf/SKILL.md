---
name: create-seed-from-pdf
description: Use when creating or updating KokushiEX seed-fu data from Japanese national exam PDFs, including question/choice extraction, answer-key application, image cropping from main and appendix PDFs, and review HTML generation.
---

# Create Seed From PDF

Use this skill for KokushiEX exam PDF ingestion work. Follow existing repository conventions over inventing a new import path.

## Target Files

- Seed-fu fixtures: `db/fixtures/development/*.rb`
- Question images: `public/images/question_<exam><session><number>.png`
  - Example: `public/images/question_60a19.png`
  - In seed: `image_url: 'images/question_60a19.png'`
- Temporary extraction files: `tmp/pdf_extract/`
- Review HTML: `tmp/seed_review_<exam>.html`

Do not commit temporary extraction files unless the user explicitly asks.

## Required Checks

Before changing seeds, inspect existing IDs and naming patterns:

```sh
rg -n "Test.seed|TestSession.seed|Question.seed|Choice.seed|image_url" db/fixtures/development
ls public/images
```

Preserve seed-fu style:

```ruby
Test.seed(:id, [...])
TestSession.seed(:id, [...])
Question.seed(:id, [...])
Choice.seed(:id, [...])
```

`Question.content` is limited to 255 characters. Check after generation.

## Extraction Workflow

1. Extract text from question PDFs:

```sh
pdftotext -layout <question.pdf> tmp/pdf_extract/<exam>_<session>_raw.txt
```

2. Parse into:

- one `Test`
- one `TestSession` per AM/PM
- 100 `Question` rows per session
- 500 `Choice` rows per session

3. Normalize question text:

- Remove PDF line-break artifacts such as `経 鼻`, `筋力 を評価`, `左大 腿直筋`.
- Keep meaningful spaces inside English phrases and units, such as `175 cm`, `80 kg`, `room air`, `Unified Parkinsonʼs Disease Rating Scale`.
- Prefer compact Japanese text over preserving PDF line wraps.

4. Apply answer-key PDFs:

```sh
pdftotext -layout <answer.pdf> tmp/pdf_extract/<exam>_answers_layout.txt
pdftotext <answer.pdf> tmp/pdf_extract/<exam>_answers_raw.txt
```

Use the answer table’s primary answer column for `is_correct`. If a row has multiple correct options for a "2つ選べ" question, set multiple choices to `is_correct: true`.

If the answer table is blank for a question, leave all choices false and report it. Do not infer a correct answer from domain knowledge.

## Image Workflow

Find likely image-required questions:

```sh
rg -n "図|写真|別冊|心電図|エックス線|CT|MRI|造影|画像|波形" db/fixtures/development/<seed>.rb
```

Extract embedded images from main question PDFs:

```sh
pdftohtml -xml -hidden -nodrm <question.pdf> tmp/pdf_extract/<exam>_<session>_html/out
rg -n "<image" tmp/pdf_extract/<exam>_<session>_html/out.xml
```

Create contact sheets for visual mapping:

```sh
magick montage tmp/pdf_extract/<dir>/out-*.png -label '%f' -tile 3x -geometry 260x220+16+28 tmp/pdf_extract/<contact>.png
```

For figure choices split across multiple images, render the page and crop the whole choice area:

```sh
pdftoppm -r 144 -f <page> -l <page> -png <question.pdf> tmp/pdf_extract/<page_prefix>
magick <page.png> -crop <WxH+X+Y> +repage public/images/question_<exam><session><number>.png
```

For appendix PDFs, first identify page-to-question mapping with:

```sh
pdftotext -layout <appendix.pdf> tmp/pdf_extract/<appendix>_layout.txt
```

Use labels such as `No. 1（P 問題 3）` to map appendix pages to questions. Crop only the useful reference region, keeping important labels such as A/B, 正面像/側面像, 左/右, or ECG settings when needed.

## Review HTML

After any seed or image update, generate or update a local review HTML that shows:

- session and question number
- `question_id`
- question text
- image
- choices
- `[正答]` marker
- warnings for missing correct answers
- warnings for image-required questions without `image_url`
- warnings for "2つ選べ" questions where correct count is not 2

Regenerate after every seed edit. For this repository, the current helper is:

```sh
ruby .codex/skills/create-seed-from-pdf/scripts/build_seed_review_html.rb --exam <exam>
```

By default, the helper reads `db/fixtures/development/*test_<exam>_*.rb` and writes `tmp/seed_review_<exam>.html`. Use `--seeds path/to/am.rb,path/to/pm.rb` or `--output path/to/file.html` only when the default discovery is not appropriate.

## Validation

Run:

```sh
ruby -c db/fixtures/development/<seed>.rb
```

Also verify:

- each session has 100 questions
- each session has 500 choices
- all referenced `image_url` files exist under `public/`
- max `Question.content` length is <= 255
- "2つ選べ" questions have two `is_correct: true` choices unless the answer table is blank
- placeholder choices such as `選択肢1（PDF上の図表）` are replaced when the image text is readable

When committing, include only reviewed seed files and committed image assets. Leave unreviewed future exam seeds and unrelated untracked files out of the commit.
