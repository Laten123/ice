# A 骨架技术验证

基线b6444b9；002独立工程，001不变。比较Skeleton2D/Bone2D与整数分层像素木偶：Bone2D允许非整数平移、连续旋转，适合变形但不能自动保证原像素形状和关节接缝；最近邻也不能消除斜边重采样。分层像素方案按整数坐标合成，保留原生像素、固定脚底与逻辑碰撞。选择分层栅格木偶，未引入骨骼蒙皮变形。

实际属性探针tools/puppet_rig_probe.gd通过。原人物仍16×24，动画画布48×48，脚底(24,40)，逻辑碰撞半径仍5px。四方向按实际非透明脚底校准，未放大人物。技术预览previews/A-native-directions.png由Godot真实渲染两套分层皮肤，不是概念图。

依赖前置：data/puppet/rig.json与actions.json为数据定义，scripts/puppet/{library,renderer,player,validator}.gd为可共享原型，skins/forest、moon为合法源帧分层及配色派生。作者Spaceyyy，CC BY4，来源/修改说明与LICENSE随包保留；未新增网络素材。生成器tools/build_resident_skins.py可复现。

技术套件tests/puppet_test.gd 472/472通过，遍历所有已实现动作/支持方向/帧，验证完成和中断恢复。P1舞蹈与P2种植明确未实现。不把分层位移称作逐帧手绘动作；关节位移、表情替换、书本像素和修形通道在后续规范中进一步验证。此阶段尚未接入家园或工作台。
