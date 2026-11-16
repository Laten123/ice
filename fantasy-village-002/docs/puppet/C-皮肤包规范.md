# C ResidentSkin 1 / rig 1.0

包是纯JSON/PNG/TXT/MD资源，入口skin.json位于根目录，不含脚本、网络权限、私聊/记忆或身份读取声明。schema_version=1，rig_version="1.0"，48×48 RGBA原生画布，foot_origin=[24,40]，pixel_scale=1、filter="nearest"；逻辑碰撞半径5px不随皮肤改变。

必需元数据：skin_id（安全ASCII标识）、version、display_name、author、author_id、source、license、license_url、attribution、modifications。必须保留原作署名；许可证元数据仅作声明，不自动认定有授权。发布/导出前需人工审查确认。

parts为front/left/right/back四方向，每方向head、hair、torso、arm_l/r、leg_l/r，每项path为包内PNG路径、anchor为整数锚点。occlusion明确列出部件和book的遮挡顺序；部件在骨架rest_joint减去皮肤anchor后定位。held_anchors.left/right供共享物品使用。expressions提供方向表情覆盖；背面无眼睛不伪造眨眼。optional_clothing提供headwear/outerwear槽，每方向含path、anchor、bind（绑定已有关节）。correctives可按action→direction→PNG帧数组覆盖特殊姿态，帧数必须与动作库一致。

actions列明支持动作，P0必须完整；unsupported声明不可见方向等原因，不能用它伪装缺失P0为完成。P1/P2由共享动作库标记未实现，不能播放。

安全与自动检查：清单类型/版本/字段、资源路径/文件白名单/目录深度/总8MiB限制、PNG头48×48（解码前）、透明边缘/二值alpha、部件锚点附近像素、四方向脚底、连接区域、持物锚点、帧间大幅抖动和动作兼容。自动接缝检查是启发式，不代表美术质量保证。

ZIP在解压前检查中央目录、文件数/解压总量、目录穿越、重复路径、符号链接、加密及可执行后缀。只写入工作台user目录，无导入代码执行。内容哈希是规范化清单（去掉自身hash）+排序路径+解码后规范PNG的SHA256，用于完整性而非作者身份认证。

导出：标准ZIP含清单、所有引用PNG（含可选服饰、修形）、许可证与校验结果；图集ZIP每动作一张PNG及atlas.json，含方向行序/帧序/FPS/48×48原点；展示PNG及APNG直接由正式renderer输出，APNG无模糊缩放，现代浏览器可播放。

验证：skin_package_test.gd 28/28，包括从模板新建实际换色PNG→校验→导出→独立干净目录重新导入，以及缺部件/方向/锚点/版本/半透明/边缘/动作/权限、ZIP穿越/脚本/解压大小、哈希篡改。APNG经Pillow实际解码6帧48×48；预览见previews/C-walk.apng、C-directions.png。双皮肤动作测试472/472仍通过。

生成：python tools/build_resident_skins.py；再用Godot执行tools/bake_skin_correctives.gd，保证moon睡眠修形来自同一正式renderer。原始Spaceyyy PNG与CC BY4许可证未修改。
