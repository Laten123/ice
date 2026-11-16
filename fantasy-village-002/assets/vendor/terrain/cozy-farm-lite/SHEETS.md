# Cozy Farm Lite 合集图说明

本包同时保留原始 1x 独立 PNG 和原始 1x 合集图，二者关系如下：

- `tiles/`、`fences/`、`crops/`、`items/`、`props/`、`trees/` 下的独立 PNG 是主数据；
- `tileset/1x/farm-ground-tileset.png` 是地面 tiles 的合集，`farm-fences-tileset.png` 是围栏合集；
- `sheets/1x/crops-sheet.png`、`items-sheet.png`、`props-sheet.png`、`trees-sheet.png` 是各组的合集；
- 合集图不包含独立 PNG 之外的像素内容，不重复提交 2x/4x；
- 使用合集图做 Godot TileSet/Atlas 时，必须保留原始来源和帧坐标；使用独立 PNG 时不需要从合集再切一次。

这些合集图来自同一 CC-BY 4.0 原始包，未改像素；署名见上级 `ATTRIBUTION.md`。
