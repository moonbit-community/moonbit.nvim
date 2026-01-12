# TreesitterのABI変更対応計画

## 概要
TreesitterのABI変更に伴い、moonbit.nvimの対応が必要

## 対応項目

### 1. 依存関係の確認・更新
- [x] nvim-treesitterの最新バージョン確認
- [x] tree-sitter-moonbitパーサーの互換性確認
- [x] パーサーのrevisionを最新に更新（a5a7e0b9cb2db740cfcc4232b2f16493b42a0c82）

### 2. treesitter.luaの修正
- [x] `lua/moonbit/treesitter.lua`のAPI変更対応
- [x] 新しいパーサー登録方式への移行（User TSUpdateイベント使用）
- [x] 古いAPI（get_parser_configs等）の削除
- [x] エラーハンドリングの見直し

### 3. クエリファイルの検証
- [ ] `queries/moonbit/`内の全クエリファイル動作確認
  - [ ] highlights.scm
  - [ ] indents.scm
  - [ ] folds.scm
  - [ ] textobjects.scm
  - [ ] locals.scm
  - [ ] tags.scm
  - [ ] injections.scm

### 4. テスト・検証
- [x] テスト用MoonBitファイル作成
- [ ] パーサーのインストール動作確認
- [ ] ハイライト表示確認
- [ ] インデント動作確認
- [ ] フォールディング確認
- [ ] 自動インストール機能確認

### 5. ドキュメント更新
- [x] README.mdの依存関係情報更新
- [x] Neovim 0.11.0要件の明記
- [ ] インストール手順の見直し

## 優先度
高: treesitter.luaのAPI対応
中: クエリファイルの検証
低: ドキュメント更新

## 期限
2026年1月末まで
