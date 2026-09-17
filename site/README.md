# Relay — project site

日英バイリンガルの静的ランディングページです。ビルド不要で、`site/` ディレクトリをそのまま配信できます。

## Preview locally

```bash
cd site
python3 -m http.server 8080
# → http://127.0.0.1:8080/
```

`file://` で直接開いても動作します(外部依存はフォントのみ)。

## Structure

```text
site/
  index.html                 1ページ完結のランディングページ
  styles.css                 ブランドテーマ(ネイビー×シアン×ミント)
  app.js                     言語切替・メタ情報更新・スクロール表示演出
  assets/                    ロゴ、システム概要図、Android スクリーンショット
```

## Bilingual switching

言語は CSS のみで切り替えます(`html[data-lang]`)。翻訳文は要素の `lang` 属性で併記されています。

```html
<h2>
  <span lang="ja">日本語の見出し</span>
  <span lang="en">English heading</span>
</h2>
```

- 初期値: `localStorage` の `relay-lang` → ブラウザ言語 → `ja`
- クエリで強制: `?lang=en` / `?lang=ja`
- 切替ボタンは `#langToggle`。`<html lang>` と `document.title`、`meta[name="description"]` も同時に更新されます。

新しい文言を追加するときは、`lang="ja"` と `lang="en"` を必ず対で記述してください。

## Publishing

静的ホスティング(GitHub Pages、Cloudflare Pages、Netlify、S3 など)ならどこでも配信できます。

GitHub Pages を使う場合は、リポジトリ設定の **Settings → Pages** で `Deploy from a branch` を選び、ブランチは `agent/zero-operation-relay`、フォルダは `/site` を指定します(リポジトリ直下の `docs/` は既存ドキュメントが入っているため、`site/` を公開対象にしてください)。

> [!NOTE]
> 公開前後に、このページが `DEVICE_TESTED` / `FIELD_READY` / `PILOT_READY` / `PRODUCTION_READY` を主張していないことを確認してください。到達度の記述は `docs/readiness/status.yml` を正とします。
