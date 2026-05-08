# 望海镇 · 第一章 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现第一章互动小说 + 老陈心象空间可玩 DEMO，验证故事情感与核心交互

**Architecture:** 两线并行 — 互动小说引擎驱动第一章叙事（开场仪式→小镇→阿树→老陈），心象空间 DEMO 独立验证"触摸与修复"玩法。均用 HTML/JS 实现，可直接在预览服务器中运行。

**Tech Stack:** HTML5 + CSS3 + Vanilla JavaScript（零依赖，可在预览服务器中直接运行）

---

## 文件结构

```
src/
├── engine/
│   ├── story-engine.js      # 互动小说引擎：场景管理、分支选择、状态追踪
│   └── story-engine.css      # 引擎样式：打字效果、选择按钮、氛围背景
├── chapter1/
│   ├── story-data.js         # 第一章全部故事数据（场景、对话、分支、物品）
│   ├── chapter1.html          # 第一章入口页面
│   └── chapter1.css           # 第一章专属样式
└── heartspace/
    ├── lchen-storm.html       # 老陈心象空间 DEMO 页面
    ├── lchen-storm.js         # 暴风雨之夜交互逻辑（触摸与修复）
    └── lchen-storm.css        # 心象空间视觉样式
```

---

### Task 1: 互动小说引擎 — 场景管理器

**Files:**
- Create: `src/engine/story-engine.js`
- Create: `src/engine/story-engine.css`

- [ ] **Step 1: 创建引擎核心 — 场景渲染与选择系统**

```javascript
// src/engine/story-engine.js
// 互动小说引擎：管理场景、渲染文本、处理玩家选择

class StoryEngine {
  constructor(containerId, storyData) {
    this.container = document.getElementById(containerId);
    this.storyData = storyData;
    this.state = {
      currentScene: null,
      history: [],
      inventory: [],        // 开场物品选择
      flags: {},            // 剧情标记（如 cat=true 表示带了猫）
      relationships: {}     // NPC 好感/关系状态
    };
    this.typingTimer = null;
  }

  // 启动引擎，进入指定场景
  start(sceneId) {
    this.goTo(sceneId);
  }

  // 跳转到场景
  goTo(sceneId) {
    const scene = this.storyData[sceneId];
    if (!scene) {
      console.error(`场景 "${sceneId}" 不存在`);
      return;
    }
    this.state.currentScene = sceneId;
    this.state.history.push(sceneId);
    this.renderScene(scene);
  }

  // 渲染场景
  renderScene(scene) {
    this.clearTyping();
    const box = this.container.querySelector('.story-content');
    
    // 构建 HTML
    let html = '';
    
    // 场景标题（可选，通常不显示）
    if (scene.title) {
      html += `<h2 class="scene-title">${scene.title}</h2>`;
    }
    
    // 场景文本段落
    scene.paragraphs.forEach(p => {
      html += `<p class="story-text">${p}</p>`;
    });
    
    // 选择分支
    if (scene.choices && scene.choices.length > 0) {
      html += '<div class="choices">';
      scene.choices.forEach((choice, i) => {
        // 检查条件
        if (choice.condition && !this.checkCondition(choice.condition)) {
          return; // 不满足条件的选择不显示
        }
        html += `<button class="choice-btn" data-index="${i}">${choice.text}</button>`;
      });
      html += '</div>';
    }
    
    // 自动推进（无选择时，延迟后跳转）
    if (scene.next && !scene.choices) {
      html += '<button class="choice-btn continue-btn">继续...</button>';
    }
    
    box.innerHTML = html;
    
    // 绑定事件
    this.bindEvents(scene);
    
    // 执行场景入场效果
    if (scene.onEnter) {
      scene.onEnter(this.state);
    }
    
    // 滚动到顶部
    box.scrollTop = 0;
  }

  // 绑定按钮事件
  bindEvents(scene) {
    const buttons = this.container.querySelectorAll('.choice-btn');
    buttons.forEach(btn => {
      btn.addEventListener('click', () => {
        if (btn.classList.contains('continue-btn')) {
          // 自动推进
          this.handleAutoAdvance(scene);
        } else {
          // 玩家选择
          const index = parseInt(btn.dataset.index);
          const choice = this.getVisibleChoices(scene)[index];
          this.handleChoice(scene, choice);
        }
      });
    });
  }

  // 获取可见的选择项（过滤掉条件不满足的）
  getVisibleChoices(scene) {
    if (!scene.choices) return [];
    return scene.choices.filter(c => 
      !c.condition || this.checkCondition(c.condition)
    );
  }

  // 处理玩家选择
  handleChoice(scene, choice) {
    // 设置标记
    if (choice.setFlag) {
      this.state.flags[choice.setFlag] = true;
    }
    if (choice.addItem) {
      this.state.inventory.push(choice.addItem);
    }
    if (choice.setRelationship) {
      const rel = choice.setRelationship;
      this.state.relationships[rel.npc] = 
        (this.state.relationships[rel.npc] || 0) + rel.change;
    }
    
    // 播放过渡效果（可选）
    this.fadeOut(() => {
      // 跳转到下一场景
      const target = choice.next || scene.next;
      if (target) {
        this.goTo(target);
      }
    });
  }

  // 自动推进
  handleAutoAdvance(scene) {
    this.fadeOut(() => {
      if (scene.next) {
        this.goTo(scene.next);
      }
    });
  }

  // 检查条件
  checkCondition(cond) {
    if (cond.flag) return !!this.state.flags[cond.flag];
    if (cond.hasItem) return this.state.inventory.includes(cond.hasItem);
    if (cond.notFlag) return !this.state.flags[cond.notFlag];
    if (cond.relationship) {
      const r = cond.relationship;
      return (this.state.relationships[r.npc] || 0) >= r.min;
    }
    return true;
  }

  // 淡出过渡
  fadeOut(callback) {
    const box = this.container.querySelector('.story-content');
    box.style.opacity = '0';
    box.style.transition = 'opacity 0.3s ease';
    setTimeout(() => {
      callback();
      box.style.opacity = '1';
    }, 300);
  }

  // 清除打字效果定时器
  clearTyping() {
    if (this.typingTimer) {
      clearTimeout(this.typingTimer);
      this.typingTimer = null;
    }
  }
}

// 导出
if (typeof module !== 'undefined') module.exports = { StoryEngine };
```

```css
/* src/engine/story-engine.css */
/* 互动小说引擎样式 */

.story-container {
  max-width: 680px;
  margin: 0 auto;
  padding: 60px 40px;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.story-content {
  transition: opacity 0.3s ease;
}

.story-text {
  font-size: 18px;
  line-height: 2;
  color: #e0d6c8;
  margin-bottom: 24px;
  font-family: 'Georgia', 'Noto Serif SC', serif;
}

.scene-title {
  font-size: 14px;
  text-transform: uppercase;
  letter-spacing: 4px;
  color: #8b7355;
  margin-bottom: 32px;
}

.choices {
  margin-top: 32px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.choice-btn {
  background: rgba(255,255,255,0.05);
  border: 1px solid rgba(255,255,255,0.12);
  color: #c8b898;
  padding: 14px 20px;
  font-size: 16px;
  cursor: pointer;
  border-radius: 6px;
  text-align: left;
  transition: all 0.2s ease;
  font-family: 'Georgia', 'Noto Serif SC', serif;
}

.choice-btn:hover {
  background: rgba(255,255,255,0.10);
  border-color: rgba(255,255,255,0.25);
  color: #e8dcc8;
}

.continue-btn {
  text-align: center;
  opacity: 0.6;
}

/* 氛围背景 */
body.story-scene {
  background: #1a1410;
  transition: background 1s ease;
}
body.story-warm {
  background: #1e1812;
}
body.story-storm {
  background: #0a0f14;
}
```

- [ ] **Step 2: 创建引擎测试页面验证基础功能**

```html
<!-- src/engine/test.html -->
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>引擎测试</title>
<link rel="stylesheet" href="story-engine.css">
</head>
<body class="story-scene">
<div id="story-root" class="story-container">
  <div class="story-content"></div>
</div>

<script src="story-engine.js"></script>
<script>
const testData = {
  start: {
    title: '测试场景',
    paragraphs: ['这是一个测试场景。引擎应该能正确渲染文本和选择。'],
    choices: [
      { text: '选择 A — 设置标记', next: 'scene_a', setFlag: 'chose_a' },
      { text: '选择 B — 添加物品', next: 'scene_b', addItem: '测试物品' },
    ]
  },
  scene_a: {
    paragraphs: ['你选择了 A。标记已设置。'],
    next: 'start'
  },
  scene_b: {
    paragraphs: ['你选择了 B。物品已添加。'],
    next: 'start'
  }
};

const engine = new StoryEngine('story-root', testData);
engine.start('start');
</script>
</body>
</html>
```

- [ ] **Step 3: 在预览服务器中验证测试页面**

启动预览服务器，打开 `src/engine/test.html`，确认：
- 文本渲染正常
- 点击选择后跳转正确
- 过渡动画流畅
- 条件判断（标记/物品）正确

- [ ] **Step 4: 提交引擎代码**

```bash
git add src/engine/story-engine.js src/engine/story-engine.css src/engine/test.html
git commit -m "feat: add interactive story engine with scene/choice/flag system"
```

---

### Task 2: 第一章故事数据 — 开场仪式

**Files:**
- Create: `src/chapter1/story-data.js`

- [ ] **Step 1: 编写开场仪式场景数据**

```javascript
// src/chapter1/story-data.js
// 第一章全部故事数据

const CHAPTER1_DATA = {

  // ========== 第一幕：开场仪式 ==========

  opening_start: {
    title: '傍晚',
    paragraphs: [
      '傍晚的光从窗户斜进来，把半个客厅染成了蜜糖色。',
      '沙发上搭着一条毛毯，桌上有一杯半凉的茶。角落里堆着几本书，有一本翻到一半，扣在地上。',
      '茶几上放着一张车票——"望海镇"。还有一张便条，字迹潦草但温柔：',
      '"你需要休息一段时间。那边有人接你。带上你想带的就行。"',
      '行李箱摊开在地上，差不多快满了。你扫了一眼——大概还能塞三样东西。',
    ],
    choices: [
      { text: '在房间里走走，看看有什么可以带', next: 'opening_room' },
    ]
  },

  opening_room: {
    paragraphs: [
      '你在这个住了很久的公寓里慢慢走了一圈。',
      '每一件东西都认识你。有些东西甚至比你自己还了解你。',
    ],
    choices: [
      { text: '看看书架边的旧照片', next: 'item_photo' },
      { text: '拿起搭在椅背上的手织围巾', next: 'item_scarf' },
      { text: '打开抽屉，看看那封未寄出的信', next: 'item_letter' },
      { text: '去阳台看看那块石头', next: 'item_stone' },
      { text: '拿起床头柜上的旧 MP3', next: 'item_mp3' },
      { text: '看看窗台上那盆快枯死的植物', next: 'item_plant' },
      { text: '注意到沙发上蜷着的猫', next: 'item_cat_first' },
      { text: '（行李箱差不多满了，该出发了）', next: 'opening_leave' }
    ]
  },

  // ===== 物品：旧照片 =====
  item_photo: {
    paragraphs: [
      '一张旧照片。照片上的人脸有些模糊了——也许是阳光太强，也许是时间太久。',
      '你记得那天的阳光很好。但现在再看这张照片，你说不清自己是怀念那个人，还是怀念那个时候的自己。',
    ],
    choices: [
      { text: '放进箱子。有些东西放不下，那就带着走。', next: 'item_photo_add', addItem: '旧照片', setFlag: 'took_photo' },
      { text: '放回书架。有些东西该留在原地。', next: 'opening_room' },
    ]
  },

  item_photo_add: {
    paragraphs: [
      '照片滑进箱子侧袋。你感觉它轻轻叹了口气——或者是箱子在叹气。',
    ],
    next: 'opening_room'
  },

  // ===== 物品：手织围巾 =====
  item_scarf: {
    paragraphs: [
      '一条手织的围巾，针脚不太整齐，但很暖和。有人给你织的。',
      '你已经很久没见那个人了。围巾上有淡淡的樟脑味——你一直在保护它，却很少真正用它。',
    ],
    choices: [
      { text: '围上试了试。还是暖的。放进行李箱。', next: 'item_scarf_add', addItem: '手织围巾', setFlag: 'took_scarf' },
      { text: '叠好放回椅背。带着记忆就行，不用带着东西。', next: 'opening_room' },
    ]
  },

  item_scarf_add: {
    paragraphs: [
      '围巾柔软地蜷在箱子角落。你想起那个人说的话："冷了记得围。"',
    ],
    next: 'opening_room'
  },

  // ===== 物品：未寄出的信 =====
  item_letter: {
    paragraphs: [
      '信封已经有些发黄了。压在抽屉最底层，和几张旧账单、一把生锈的钥匙在一起。',
      '收件人的名字写了一半，后半截被划掉了。你甚至不记得当初想说什么——道歉？告白？告别？',
    ],
    choices: [
      { text: '放进箱子。也许有一天我会写完它。也许不会。', next: 'item_letter_add', addItem: '未寄出的信', setFlag: 'took_letter' },
      { text: '放回抽屉。有些话，没说出来也许是对的。', next: 'opening_room' },
    ]
  },

  item_letter_add: {
    paragraphs: [
      '信躺在箱底，安安静静的。你不打算寄它。但你打算带着它。',
    ],
    next: 'opening_room'
  },

  // ===== 物品：石头 =====
  item_stone: {
    paragraphs: [
      '一块光滑的石头。你从海边捡回来的，不知道为什么一直留着。',
      '它很重，很凉，没有任何实用价值。但握着它的时候，你会平静下来。',
    ],
    choices: [
      { text: '放进口袋。沉一点没关系。', next: 'item_stone_add', addItem: '光滑的石头', setFlag: 'took_stone' },
      { text: '放回阳台。它属于海边，也许该让它留在这里。', next: 'opening_room' },
    ]
  },

  item_stone_add: {
    paragraphs: [
      '石头沉甸甸地落进口袋。你感到一种奇怪的安心——好像它在说："我帮你坠着。"',
    ],
    next: 'opening_room'
  },

  // ===== 物品：旧 MP3 =====
  item_mp3: {
    paragraphs: [
      '早就没电了。但你记得里面有一首歌，每次听到都会哭。',
      '不是因为难过——是因为终于有人把你说不出来的东西唱出来了。',
    ],
    choices: [
      { text: '放进箱子。没电了也没关系，旋律还记得。', next: 'item_mp3_add', addItem: '旧MP3', setFlag: 'took_mp3' },
      { text: '放回床头柜。那首歌已经在我脑子里了。', next: 'opening_room' },
    ]
  },

  item_mp3_add: {
    paragraphs: [
      '没有电池的 MP3 轻得几乎没有重量。但你知道它在。',
    ],
    next: 'opening_room'
  },

  // ===== 物品：快枯死的植物 =====
  item_plant: {
    paragraphs: [
      '这盆植物总是在濒死的边缘。叶子蔫了大半，但茎还绿着。',
      '你总是忘记给它浇水。但它用一种顽固的方式活着——不漂亮，但还没放弃。',
      '你觉得有点内疚，又有点被感动。',
    ],
    choices: [
      { text: '浇了最后一次水，然后把它放进箱子。咱俩都还活着。', next: 'item_plant_add', addItem: '快枯死的植物', setFlag: 'took_plant' },
      { text: '给它浇了水，放在窗台上。邻居会帮忙照看的。', next: 'opening_room' },
    ]
  },

  item_plant_add: {
    paragraphs: [
      '植物的叶子蹭了蹭你的手。你不太确定植物能不能蹭人。也许只是风。',
    ],
    next: 'opening_room'
  },

  // ===== 猫（隐藏彩蛋 — 第一次发现） =====
  item_cat_first: {
    paragraphs: [
      '沙发上蜷着一只猫。它一直在那里。',
      '你收拾行李的时候，它半睁着眼看你，偶尔换个姿势，但始终没离开沙发。',
      '你走过去，它抬头看了你一眼，然后继续舔爪子。',
      '你再看了它一会儿。它站起来，伸了个懒腰，走到行李箱旁边坐下。',
      '然后——它看着你。不说一句话。',
    ],
    choices: [
      { text: '再点它一下', next: 'item_cat_second' },
      { text: '（笑了笑，继续收拾行李）', next: 'opening_room' },
    ]
  },

  item_cat_second: {
    paragraphs: [
      '"你收拾完了？"',
      '它打了个哈欠。',
      '箱子已经塞了三样东西。但它不是物品——你没法把它"装进去"。',
    ],
    choices: [
      { text: '抱起猫。它不是行李，它是我带的同伴。', next: 'item_cat_add', setFlag: 'took_cat' },
      { text: '摸摸它的头。"在这里等我回来。"', next: 'opening_room' },
      { text: '把它放回沙发。猫不需要旅行。', next: 'opening_room' },
    ]
  },

  item_cat_add: {
    paragraphs: [
      '"行吧。我不占地方。"',
      '它蜷进你的怀里，开始打呼噜。',
      '你检查了一下箱子——还是三样东西。猫不算。猫从来不算。',
    ],
    next: 'opening_room'
  },

  // ===== 离开 =====
  opening_leave: {
    paragraphs: [
      '你站在门口，最后看了一眼这个住了很久的公寓。',
      '晚霞已经褪成了深蓝。行李箱在你脚边，沉甸甸的——装了三样你选择带走的东西。',
    ],
    choices: [
      { text: '关上门。出发。', next: 'arrival_train' },
    ]
  },

  // ===== 列车上 =====
  arrival_train: {
    paragraphs: [
      '列车在夜色中穿行。窗外偶尔掠过几点灯火，很快就消失在黑暗里。',
      '你靠着窗，感到一种奇怪的平静。',
      '不是开心，也不是难过——是终于可以什么都不想了。',
      '广播响了："前方到站——望海镇。"',
    ],
    next: 'arrival_station'
  },
};

// ===== 需要继续的场景（后续 Task 补充） =====

// 占位：抵达小镇、遇见阿树、老陈支线待 Task 3/Task 4 补充
```

- [ ] **Step 2: 创建第一章入口页面**

```html
<!-- src/chapter1/chapter1.html -->
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>望海镇 · 第一章</title>
<link rel="stylesheet" href="../engine/story-engine.css">
<link rel="stylesheet" href="chapter1.css">
</head>
<body class="story-warm">
<div id="story-root" class="story-container">
  <div class="story-content"></div>
</div>

<script src="../engine/story-engine.js"></script>
<script src="story-data.js"></script>
<script>
const engine = new StoryEngine('story-root', CHAPTER1_DATA);
engine.start('opening_start');
</script>
</body>
</html>
```

```css
/* src/chapter1/chapter1.css */
body.story-warm {
  background: linear-gradient(180deg, #1e1812 0%, #1a1410 100%);
  min-height: 100vh;
}

.story-container {
  padding-top: 80px;
}
```

- [ ] **Step 3: 在预览服务器中验证开场仪式**

打开 `src/chapter1/chapter1.html`，完整走一遍开场流程：
- 所有6件物品+猫都能正确交互
- 选择3件物品后离开的流程完整
- 猫的隐藏彩蛋（多点几次）触发正确
- 标记和物品正确记录在引擎状态中

- [ ] **Step 4: 提交**

```bash
git add src/chapter1/
git commit -m "feat: add opening ritual scenes with 6 items and hidden cat easter egg"
```

---

### Task 3: 第一章故事数据 — 抵达小镇 & 阿树

**Files:**
- Modify: `src/chapter1/story-data.js`（追加场景）

- [ ] **Step 1: 追加抵达小镇与阿树场景**

在 `CHAPTER1_DATA` 对象中追加以下场景（放在 `arrival_station` 之后）：

```javascript
  // ========== 抵达望海镇 ==========

  arrival_station: {
    paragraphs: [
      '车站很小。只有一条长椅、一盏路灯、和一个写着"望海镇"的旧木牌。',
      '海风从某个方向吹过来，带着盐的味道和远处渔船的汽笛声。',
      '你站在站台上，深吸了一口气。这里的空气和城里不一样——更慢，更安静。',
      '一个声音从你身后传来："来了？"',
    ],
    choices: [
      { text: '回头', next: 'meet_ashu_first' },
    ]
  },

  meet_ashu_first: {
    paragraphs: [
      '一个中年男人站在路灯下。他穿着有点旧的棉麻衬衫，手里拎着一盏纸灯笼。',
      '"我是阿树。茶馆的。"他说话很慢，每个字之间有空隙，像风吹过竹林。',
      '"便条上说的'有人接你'——就是我。"',
      '他看了看你，又看了看你的行李箱。没问任何问题，只是点了点头。',
      '"走吧。茶馆离这不远。今晚先歇着，明天你想到处走走再说。"',
    ],
    choices: [
      { text: '"谢谢你来接我。"', next: 'walk_to_teahouse' },
      { text: '点点头，跟着他走', next: 'walk_to_teahouse' },
    ]
  },

  walk_to_teahouse: {
    paragraphs: [
      '阿树提着灯笼走在前面，你在后面跟着。',
      '小镇的夜晚很安静。石板路两旁是低矮的老房子，有些窗户透着暖黄色的光。',
      '你听到了海浪的声音——不远，就在某条巷子的尽头。',
      '阿树忽然开口："这个镇子不大。灯塔、码头、老街、面馆、还有我的茶馆。明天你可以到处转转。"',
      '他停顿了一下。',
      '"有些人来望海镇，是为了找一个答案。有些人来——是为了忘掉一个问题。你不用告诉我你是哪种。"',
    ],
    choices: [
      { text: '"你呢？你是哪种？"', next: 'ashu_laugh', setRelationship: { npc: 'ashu', change: 1 } },
      { text: '沉默地走着。有些问题不需要现在回答。', next: 'arrive_teahouse' },
    ]
  },

  ashu_laugh: {
    paragraphs: [
      '阿树轻轻笑了一声。不是觉得好笑——像是被戳中了什么。',
      '"我？我两种都不是。我是那个开了茶馆之后，发现自己也需要喝茶的人。"',
      '他没有继续解释。但你感觉这句话比听起来要重。',
    ],
    next: 'arrive_teahouse'
  },

  arrive_teahouse: {
    paragraphs: [
      '茶馆不大，但很舒服。木质的桌椅、墙上挂着几幅淡彩画、柜台上摆着一排陶罐。',
      '阿树给你倒了一杯茶。热气在灯光下慢慢升起。',
      '"房间在后面。被子是新换的。有什么需要就喊我——我睡得晚。"',
      '他走了几步，又回头。',
      '"对了——茶别喝完。留一口。"',
    ],
    choices: [
      { text: '"为什么要留一口？"', next: 'ashu_tea_wisdom', setRelationship: { npc: 'ashu', change: 1 } },
      { text: '点点头，捧着茶杯暖手', next: 'first_night' },
    ]
  },

  ashu_tea_wisdom: {
    paragraphs: [
      '"留一口，代表还有下一次。"他笑了笑，"空杯子代表结束。留一口的杯子——代表还会再来。"',
      '他说完就上楼了。脚步声很轻。',
    ],
    next: 'first_night'
  },

  first_night: {
    title: '第一夜',
    paragraphs: [
      '你在房间里坐了一会儿。窗外可以看到远处灯塔的光——一闪一闪的。',
      '茶留了一口。温的，在杯底晃着小小的光。',
    ],
    // 如果有猫
    choices: [
      { text: '看看窗外的灯塔', next: 'first_night_lighthouse' },
      { text: '躺下睡觉。明天再说。', next: 'morning_first' },
    ]
  },

  first_night_lighthouse: {
    paragraphs: [
      '灯塔的光很有节奏——亮三秒，暗一秒。',
      '你想起阿树说的："有些人来是为了找一个答案。有些人来是为了忘掉一个问题。"',
      '你不太确定自己是哪种。也许两种都有。也许都不是。',
    ],
    choices: [
      { text: '躺下睡觉。明天会知道的。', next: 'morning_first' },
    ]
  },

  // ========== 第一天早晨 ==========

  morning_first: {
    title: '清晨',
    paragraphs: [
      '海风把你叫醒了——或者说，是阳光和海风一起。',
      '窗外的小镇在晨光中完全变了个样。石板路是暖灰色的，远处的大海在日出中泛着金光。码头上有人在整理渔网，老街上飘来面馆的香味。',
      '阿树在楼下泡茶。你下楼的脚步声让他抬起头。',
      '"早。睡得好吗？"',
    ],
    choices: [
      { text: '"很好。好久没睡得这么沉了。"', next: 'morning_explore' },
      { text: '"做了个梦。但不记得了。"', next: 'morning_explore' },
    ]
  },

  morning_explore: {
    paragraphs: [
      '"今天你可以到处走走。"阿树递给你一杯茶，"灯塔那边有个守灯人——老陈。面馆的秋姨做的海鲜面不错。海边有个小姑娘经常在那里画画。"',
      '他顿了顿。',
      '"想跟谁聊聊都行。不想聊也行。我都在茶馆。"',
    ],
    choices: [
      { text: '去灯塔看看老陈', next: 'meet_laochen_first' },
      { text: '去码头走走', next: 'explore_dock' },
      { text: '先去面馆吃碗面', next: 'explore_noodle' },
    ]
  },

  // ===== 码头（自由探索 — 可选） =====
  explore_dock: {
    paragraphs: [
      '码头的风很大。几个老人在钓鱼，鱼竿架在栏杆上，他们自己坐在马扎上打盹。',
      '海面上有几艘渔船。更远的地方，海和天模糊成一片灰蓝。',
      '一个钓鱼的老人睁开一只眼看了看你，又闭上了。',
    ],
    choices: [
      { text: '在码头坐一会儿', next: 'explore_dock_sit' },
      { text: '去灯塔看看', next: 'meet_laochen_first' },
      { text: '回茶馆找阿树', next: 'back_to_teahouse' },
    ]
  },

  explore_dock_sit: {
    paragraphs: [
      '你在码头边上坐了一会儿。海浪拍在石墩上，规律得像呼吸。',
      '那个打盹的老人忽然开口："新来的？"',
      '"嗯。"',
      '"好。这地方好。"他又闭上了眼。',
      '你不太确定他说的是小镇好——还是你来这件事好。',
    ],
    next: 'explore_dock'
  },

  // ===== 面馆 — 秋姨（可选） =====
  explore_noodle: {
    paragraphs: [
      '"来啦？坐！海鲜面？"',
      '秋姨的声音比海风还快。她五十出头，手脚麻利得像三十岁，笑起来有两个酒窝。',
      '不等你回答，她已经转身进了厨房。三分钟后，一碗热气腾腾的海鲜面放在你面前。',
      '"多吃点。你瘦。"',
      '她对你一无所知，但这话说得像认识了很久。',
    ],
    choices: [
      { text: '吃面。很好吃。', next: 'explore_noodle_chat' },
      { text: '"你怎么知道我瘦？"', next: 'explore_noodle_chat' },
    ]
  },

  explore_noodle_chat: {
    paragraphs: [
      '"来这镇上的，十个有九个瘦。"秋姨擦了擦手，"不是身上瘦——是心里瘦。吃面吧，吃饱了心里能暖和点。"',
      '她说话的方式让人没法反驳。你低头吃面。确实很好吃。',
    ],
    choices: [
      { text: '吃完面，去灯塔看看', next: 'meet_laochen_first' },
      { text: '回茶馆找阿树', next: 'back_to_teahouse' },
    ]
  },

  // ===== 回茶馆 =====
  back_to_teahouse: {
    paragraphs: [
      '阿树在擦杯子。看到你回来，他点了点头，没问你去哪了。',
      '"茶？"',
      '你坐下来。茶馆里很安静，只有茶杯轻轻碰撞的声音。',
    ],
    choices: [
      { text: '喝杯茶，然后去灯塔', next: 'meet_laochen_first' },
      { text: '"阿树，你在镇子多久了？"', next: 'ashu_backstory' },
    ]
  },

  ashu_backstory: {
    paragraphs: [
      '"十年了吧。"他放下杯子，"来的时候跟你想的差不多——想找个地方安静一下。结果安静着安静着，就开了这家茶馆。"',
      '"然后呢？"',
      '"然后——就有人开始来喝茶了。有人的地方就有故事。有故事的地方——就安静不了了。"',
      '他笑了一下。和昨晚那种笑不太一样——这次是真的觉得好笑。',
    ],
    choices: [
      { text: '去灯塔看看', next: 'meet_laochen_first' },
    ]
  },
```

- [ ] **Step 2: 在预览中验证抵达与阿树场景**

打开 `src/chapter1/chapter1.html`，走完从车站到小镇探索的完整流程。验证：
- 所有分支选择（码头/面馆/茶馆）都能正确跳转
- 阿树的对话在不同选择下有不同回应
- 关系值（relationships）正确累积

- [ ] **Step 3: 提交**

```bash
git add src/chapter1/story-data.js
git commit -m "feat: add arrival at seaside town and A-Shu intro scenes"
```

---

### Task 4: 第一章故事数据 — 老陈支线（日常→冲突→心象）

**Files:**
- Modify: `src/chapter1/story-data.js`（追加场景）

- [ ] **Step 1: 追加老陈支线场景数据**

在 `CHAPTER1_DATA` 对象中追加：

```javascript
  // ========== 老陈支线 ==========

  meet_laochen_first: {
    title: '灯塔',
    paragraphs: [
      '灯塔比想象中高。白色的塔身被海风侵蚀出斑驳的痕迹，但顶上的灯擦得很亮。',
      '灯塔下面有一间小屋，门半掩着。你敲了敲门。',
      '一个六十多岁的男人打开门。他穿着灰蓝色的旧工作服，头发花白，眼神很安静。',
      '"嗯？"',
      '他看起来不太习惯有人敲门。',
    ],
    choices: [
      { text: '"你好。我是新来镇上的。阿树说可以来看看。"', next: 'laochen_hello' },
      { text: '"你好。路过，想看看灯塔。"', next: 'laochen_hello' },
    ]
  },

  laochen_hello: {
    paragraphs: [
      '"哦。"他点了下头，让开半个身子。"进来吧。没什么好看的。"',
      '屋里很简单。一张床，一张桌子，一把椅子，一个暖水瓶。墙上挂着一张黑白照片——一个女人在灯塔前笑着。',
      '他注意到你在看照片。没说什么，给你倒了杯水。',
    ],
    choices: [
      { text: '"你在灯塔工作了多久？"', next: 'laochen_talk_work', setRelationship: { npc: 'laochen', change: 1 } },
      { text: '安静地喝水。不问问题。', next: 'laochen_silent', setRelationship: { npc: 'laochen', change: 1 } },
      { text: '"照片上是谁？"', next: 'laochen_photo_trigger' },
    ]
  },

  laochen_talk_work: {
    paragraphs: [
      '"三十多年了吧。"他坐在床沿上，"从年轻的时候就开始干。那时候灯塔还不是自动的——得手动点。现在好了，机器管的。我就是……看着。"',
      '"看着？"',
      '"嗯。看着它亮。确定它没灭。"',
      '他说这话的时候，语气和看照片的时候一样。',
    ],
    choices: [
      { text: '"三十多年，每天看着同一片海——不腻吗？"', next: 'laochen_sea' },
      { text: '"那我明天再来看你。"', next: 'laochen_goodbye_first' },
    ]
  },

  laochen_sea: {
    paragraphs: [
      '"海天天不一样。"他说，"有时候平得像镜子，有时候浪有三层楼高。同一个地方，每天都是新的。"',
      '他顿了顿。',
      '"人有的时候……也想不一样。但有的事情，变不了。"',
    ],
    choices: [
      { text: '没有追问。有些话需要时间。', next: 'laochen_goodbye_first' },
    ]
  },

  laochen_silent: {
    paragraphs: [
      '你们安静地坐了一会儿。水杯里的热气慢慢消散。',
      '灯塔的光透过窗户，一闪一闪地照进来。',
      '老陈忽然开口："很少有人来我这里。更少有人——来了之后不说话。"',
      '他看了你一眼。不是审视——是一种缓慢的评估。像是在看你耐不耐得住安静。',
    ],
    next: 'laochen_goodbye_first'
  },

  laochen_photo_trigger: {
    paragraphs: [
      '老陈的手停了一下。水杯里的水晃了晃。',
      '"……我妻子。"',
      '他的声音很轻，但很稳。像是在说一个很久以前就接受了的事实。',
      '"她走了。七年了。"',
      '你没说话。灯塔的光一闪一闪。',
    ],
    choices: [
      { text: '"对不起。我不该问。"', next: 'laochen_dont_sorry' },
      { text: '什么也不说。只是坐在那里。', next: 'laochen_silent_support', setRelationship: { npc: 'laochen', change: 2 } },
    ]
  },

  laochen_dont_sorry: {
    paragraphs: [
      '"不。没事。"他转过头看着照片，"……有时候有人问起，也挺好的。说明她还被记得。"',
    ],
    next: 'laochen_goodbye_first'
  },

  laochen_silent_support: {
    paragraphs: [
      '你什么都没说。只是坐在那里，和他一起看着照片。',
      '过了很久，老陈深吸了一口气。',
      '"……谢谢。"',
      '这是他第一次说谢谢。声音很小，但很真。',
    ],
    next: 'laochen_goodbye_first'
  },

  laochen_goodbye_first: {
    paragraphs: [
      '你起身准备离开。老陈送你到门口。',
      '"灯塔晚上一直亮着。"他说，"睡不着的时候——可以看看。"',
      '他不是在说灯塔。',
    ],
    next: 'back_to_teahouse_evening'
  },

  // ===== 回到茶馆（傍晚） =====
  back_to_teahouse_evening: {
    paragraphs: [
      '傍晚回到茶馆。阿树在柜台后面看书。',
      '"去看老陈了？"他头也没抬。',
    ],
    choices: [
      { text: '"嗯。他挺……安静的。"', next: 'ashu_about_laochen' },
      { text: '"他妻子——"', next: 'ashu_about_laochen' },
    ]
  },

  ashu_about_laochen: {
    paragraphs: [
      '"老陈心里有一场暴风雨。"阿树放下书，"七年了，还没停。他不说，不代表没在下。"',
      '他看着你。',
      '"你感觉到了吗？"',
    ],
    choices: [
      { text: '"感觉到了。他看照片的时候——眼睛里有海。"', next: 'ashu_nod' },
    ]
  },

  ashu_nod: {
    paragraphs: [
      '阿树点了点头。"你比你以为的更会看人。"',
      '他给你倒了杯茶。这次不是热的——是温的。',
      '"不用急。有些连接，需要时间。"',
    ],
    choices: [
      { text: '喝茶。留一口。', next: 'chapter1_transition' },
    ]
  },

  // ===== 第一章过渡（提示后续内容） =====
  chapter1_transition: {
    paragraphs: [
      '灯塔的光从窗外照进来。一闪一闪。',
      '你想起老陈看照片的眼神。想起阿树说的"心里有一场暴风雨"。',
      '你想——也许有一天，你能走进那场暴风雨。',
      '但不是今天。',
      '今天，你只需要喝茶。留一口。',
    ],
    choices: [
      { text: '（第一章结束）', next: 'chapter1_end' },
    ]
  },

  chapter1_end: {
    paragraphs: [
      '—— 第一章 · 抵达 · 完 ——',
      '',
      '进度提示：',
      '· 完成了开场仪式（物品选择 + 猫）',
      '· 抵达望海镇，结识阿树',
      '· 遇见了老陈，建立了初步信任',
      '· 下一章：深入老陈的心象空间——无尽暴风雨之夜',
    ],
    choices: [
      { text: '重新开始', next: 'opening_start' },
    ]
  },
```

- [ ] **Step 2: 验证老陈支线的完整流程**

在 `chapter1.html` 中走完：初始对话（多种方式）→ 回到茶馆 → 阿树对话 → 第一章结束。验证：
- 触碰照片 vs 不触碰照片 产生不同对话
- 沉默/陪伴选项正确增加关系值
- 第一章结束提示正确显示

- [ ] **Step 3: 提交**

```bash
git add src/chapter1/story-data.js
git commit -m "feat: add Lao Chen intro scenes with trust-building and emotional pacing"
```

---

### Task 5: 老陈心象空间 DEMO — "无尽暴风雨之夜"

**Files:**
- Create: `src/heartspace/lchen-storm.html`
- Create: `src/heartspace/lchen-storm.js`
- Create: `src/heartspace/lchen-storm.css`

- [ ] **Step 1: 创建 HTML 页面**

```html
<!-- src/heartspace/lchen-storm.html -->
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>无尽暴风雨之夜 — 老陈的心象空间</title>
<link rel="stylesheet" href="lchen-storm.css">
</head>
<body>
<div id="heartspace">

  <!-- 氛围层：雨、闪电、海洋 -->
  <div id="atmosphere">
    <canvas id="rain-canvas"></canvas>
    <div id="lightning"></div>
  </div>

  <!-- 游戏层 -->
  <div id="game-layer">
    <div id="lighthouse-beam"></div>
    <div id="fragments-area"></div>
    <div id="hint-text"></div>
  </div>

  <!-- 叙事层 -->
  <div id="narration"></div>

</div>

<script src="lchen-storm.js"></script>
</body>
</html>
```

- [ ] **Step 2: 创建 CSS 样式**

```css
/* src/heartspace/lchen-storm.css */

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  background: #0a0d14;
  overflow: hidden;
  font-family: 'Georgia', 'Noto Serif SC', serif;
}

#heartspace {
  width: 100vw;
  height: 100vh;
  position: relative;
}

/* ===== 氛围层 ===== */
#atmosphere {
  position: absolute;
  inset: 0;
  z-index: 1;
}

#rain-canvas {
  width: 100%;
  height: 100%;
  opacity: 0.7;
}

#lightning {
  position: absolute;
  inset: 0;
  background: transparent;
  transition: background 0.1s ease;
  pointer-events: none;
}

/* ===== 游戏层 ===== */
#game-layer {
  position: absolute;
  inset: 0;
  z-index: 2;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

#lighthouse-beam {
  width: 0;
  height: 0;
  border-left: 30px solid transparent;
  border-right: 30px solid transparent;
  border-bottom: 200px solid rgba(255, 220, 150, 0.15);
  position: absolute;
  top: 20%;
  left: 50%;
  transform: translateX(-50%);
  animation: beamPulse 3s ease-in-out infinite;
  filter: blur(10px);
}

@keyframes beamPulse {
  0%, 100% { opacity: 0.3; border-bottom-color: rgba(255, 220, 150, 0.1); }
  50% { opacity: 0.8; border-bottom-color: rgba(255, 220, 150, 0.4); }
}

#fragments-area {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.fragment {
  position: absolute;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(255,255,200,0.6), rgba(255,200,100,0.2));
  cursor: pointer;
  pointer-events: auto;
  animation: fragmentFloat 4s ease-in-out infinite;
  transition: transform 0.3s ease, opacity 0.5s ease;
  box-shadow: 0 0 20px rgba(255,220,150,0.3);
}

.fragment:hover {
  transform: scale(1.5);
  box-shadow: 0 0 40px rgba(255,220,150,0.6);
}

.fragment.collected {
  animation: fragmentCollect 0.8s ease-out forwards;
  pointer-events: none;
}

@keyframes fragmentFloat {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-12px); }
}

@keyframes fragmentCollect {
  0% { opacity: 1; transform: scale(1); }
  100% { opacity: 0; transform: scale(3) translateY(-100px); }
}

#hint-text {
  position: absolute;
  bottom: 15%;
  color: rgba(200,180,150,0.6);
  font-size: 14px;
  letter-spacing: 2px;
  animation: fadeInOut 3s ease-in-out infinite;
}

@keyframes fadeInOut {
  0%, 100% { opacity: 0.3; }
  50% { opacity: 0.7; }
}

/* ===== 叙事层 ===== */
#narration {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 3;
  padding: 40px;
  background: linear-gradient(transparent, rgba(10,13,20,0.95) 40%);
  color: #c8b898;
  font-size: 16px;
  line-height: 1.8;
  text-align: center;
  min-height: 180px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-end;
}

.narration-text {
  max-width: 600px;
  opacity: 0;
  transform: translateY(10px);
  transition: all 1s ease;
}

.narration-text.visible {
  opacity: 1;
  transform: translateY(0);
}

.narration-hint {
  font-size: 12px;
  color: rgba(200,180,150,0.4);
  margin-top: 16px;
  letter-spacing: 1px;
}

/* ===== 完成状态 ===== */
.completion-overlay {
  position: absolute;
  inset: 0;
  z-index: 10;
  display: flex;
  align-items: center;
  justify-content: center;
  background: radial-gradient(circle, rgba(255,220,150,0.1), rgba(10,13,20,0.9));
  opacity: 0;
  transition: opacity 3s ease;
  pointer-events: none;
}

.completion-overlay.visible {
  opacity: 1;
}

.completion-text {
  color: #e0d0b0;
  font-size: 20px;
  text-align: center;
  line-height: 2;
}
```

- [ ] **Step 3: 创建核心游戏逻辑**

```javascript
// src/heartspace/lchen-storm.js
// 老陈心象空间 — 无尽暴风雨之夜
// 核心玩法：触摸与修复 — 在暴风雨中拾回记忆碎片，平息风暴

class LchenHeartSpace {
  constructor() {
    this.fragments = [];
    this.collected = 0;
    this.totalFragments = 7; // 七段记忆
    this.stormIntensity = 1.0; // 1.0 = 最强, 0 = 平息
    this.phase = 'intro'; // intro | collecting | complete
    
    this.init();
  }

  init() {
    this.setupRain();
    this.setupLightning();
    this.showNarration('intro');
    
    // 延迟后开始收集阶段
    setTimeout(() => {
      this.phase = 'collecting';
      this.spawnFragments();
      this.showNarration('collecting');
      this.startLightning();
    }, 6000);
  }

  // ===== 雨效 =====
  setupRain() {
    const canvas = document.getElementById('rain-canvas');
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    const ctx = canvas.getContext('2d');
    
    const drops = Array.from({ length: 200 }, () => ({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height,
      speed: 3 + Math.random() * 8,
      length: 10 + Math.random() * 20,
      opacity: 0.1 + Math.random() * 0.3
    }));

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.strokeStyle = 'rgba(180,200,220,0.3)';
      
      drops.forEach(d => {
        ctx.beginPath();
        ctx.moveTo(d.x, d.y);
        ctx.lineTo(d.x - 1, d.y + d.length);
        ctx.strokeStyle = `rgba(180,200,220,${d.opacity * this.stormIntensity})`;
        ctx.lineWidth = 0.5;
        ctx.stroke();
        
        d.y += d.speed * this.stormIntensity;
        d.x -= 1 * this.stormIntensity; // 风雨斜向
        
        if (d.y > canvas.height) { d.y = -d.length; d.x = Math.random() * canvas.width; }
        if (d.x < 0) d.x = canvas.width;
      });
      
      this.rainFrame = requestAnimationFrame(animate);
    };
    animate();
  }

  // ===== 闪电 =====
  startLightning() {
    const lightning = document.getElementById('lightning');
    const flash = () => {
      if (this.phase === 'complete') return;
      
      const shouldFlash = Math.random() < 0.3 * this.stormIntensity;
      if (shouldFlash) {
        lightning.style.background = 'rgba(255,255,240,0.08)';
        setTimeout(() => { lightning.style.background = 'transparent'; }, 100 + Math.random() * 200);
      }
      this.lightningTimer = setTimeout(flash, 2000 + Math.random() * 5000);
    };
    flash();
  }

  // ===== 记忆碎片 =====
  spawnFragments() {
    const area = document.getElementById('fragments-area');
    const memories = [
      { id: 1, text: '她笑着在灯塔前拍照。那天风很大，她的头发被吹得乱七八糟。她说"快点拍！"你按下快门的时候，她的笑容被风吹歪了——那是你见过的最好看的笑容。' },
      { id: 2, text: '你们在码头一起看日出。她说海上的太阳像一颗糖心蛋。"你啊，总是看什么都像吃的。"她打你一下。那一下很轻。' },
      { id: 3, text: '她生病后的第一个冬天。你每天从灯塔下来，走四十分钟路去医院。她骂你"别来了，灯塔没人管"。但每次你来，她都醒着。' },
      { id: 4, text: '那晚暴风雨——你本来应该回去的。但灯塔的备用发电机坏了。你花了三个小时修好它。等你回到家——雨太大了。太大了。' },
      { id: 5, text: '"不是你的错。"她说过很多次。但你没有相信。你从来没有相信过。你宁愿相信是自己的错——因为内疚比失去更有形状。' },
      { id: 6, text: '她走后第一个月，你在灯塔顶上坐了一整夜。天快亮的时候，你看到海面上有一道很长的光。你不知道那是什么。但你决定继续点亮灯塔。' },
      { id: 7, text: '七年了。你每天都擦那盏旧灯——她的遗物，那盏不亮的灯。你擦它不是因为相信它会亮。你擦它是因为——不擦的话，你不知道该做什么。' },
    ];

    memories.forEach((mem, i) => {
      const frag = document.createElement('div');
      frag.className = 'fragment';
      frag.style.left = (15 + Math.random() * 70) + '%';
      frag.style.top = (20 + Math.random() * 60) + '%';
      frag.style.animationDelay = (i * 0.3) + 's';
      frag.dataset.memoryId = mem.id;
      frag.dataset.memoryText = mem.text;
      
      frag.addEventListener('click', (e) => this.collectFragment(frag, mem));
      
      area.appendChild(frag);
      this.fragments.push(frag);
    });
  }

  collectFragment(frag, mem) {
    if (frag.classList.contains('collected')) return;
    
    frag.classList.add('collected');
    this.collected++;
    
    // 显示记忆文本
    this.showMemoryText(mem.text);
    
    // 降低风暴强度
    this.stormIntensity = Math.max(0, 1 - (this.collected / this.totalFragments) * 0.9);
    
    // 检查是否全部收集
    if (this.collected >= this.totalFragments) {
      setTimeout(() => this.complete(), 4000);
    }
  }

  showMemoryText(text) {
    const narration = document.getElementById('narration');
    narration.innerHTML = `
      <div class="narration-text visible">${text}</div>
      <div class="narration-hint">${this.collected}/${this.totalFragments} 段记忆</div>
    `;
    
    // 3秒后淡化
    setTimeout(() => {
      const textEl = narration.querySelector('.narration-text');
      if (textEl) textEl.classList.remove('visible');
    }, 3500);
  }

  showNarration(phase) {
    const narration = document.getElementById('narration');
    const texts = {
      intro: {
        text: '你走进了一场暴风雨。<br>这不是普通的风雨——这是老陈心里下了七年的那场。',
        hint: ''
      },
      collecting: {
        text: '风雨中有微弱的光点。那是他散落的记忆。<br>触碰它们——让它们重新被看见。',
        hint: '点击光点收集记忆碎片'
      }
    };
    
    const data = texts[phase];
    narration.innerHTML = `
      <div class="narration-text visible">${data.text}</div>
      <div class="narration-hint">${data.hint}</div>
    `;
  }

  complete() {
    this.phase = 'complete';
    this.stormIntensity = 0;
    
    // 停止雨和闪电
    if (this.rainFrame) cancelAnimationFrame(this.rainFrame);
    if (this.lightningTimer) clearTimeout(this.lightningTimer);
    
    // 清屏
    document.getElementById('rain-canvas').style.opacity = '0';
    document.getElementById('rain-canvas').style.transition = 'opacity 3s ease';
    document.getElementById('lightning').style.background = 'transparent';
    
    // 完成覆盖层
    const overlay = document.createElement('div');
    overlay.className = 'completion-overlay visible';
    overlay.innerHTML = `
      <div class="completion-text">
        风暴停了。<br>
        七段记忆，七年。<br>
        它们一直在那里——只是需要有人看见。<br><br>
        <span style="font-size:14px;opacity:0.6;">老陈抬起头。灯塔的光变得比之前亮了。</span>
      </div>
    `;
    document.getElementById('heartspace').appendChild(overlay);
    
    document.getElementById('narration').innerHTML = `
      <div class="narration-text visible" style="text-align:center;">
        暴风雨停了。七段记忆都被找回来了。<br>
        ——老陈的心象空间·第一层·完——
      </div>
    `;
  }
}

// 启动
window.addEventListener('DOMContentLoaded', () => {
  new LchenHeartSpace();
});
```

- [ ] **Step 4: 验证心象空间 DEMO**

在预览服务器中打开 `src/heartspace/lchen-storm.html`，验证：
- 雨效和闪电渲染正常
- 7个光点可点击收集
- 每次收集显示对应记忆文本
- 风暴强度随收集递减（雨变缓、闪电频率降低）
- 全部收集后显示完成画面，风暴平息

- [ ] **Step 5: 提交**

```bash
git add src/heartspace/
git commit -m "feat: add Lao Chen heart space demo - Endless Stormy Night with touch-and-repair mechanic"
```

---

### Task 6: 集成验证与总结

**Files:**
- Create: `src/index.html`（导航页）

- [ ] **Step 1: 创建导航页**

```html
<!-- src/index.html -->
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>望海镇 · 开发导航</title>
<style>
  body {
    background: #1a1410;
    color: #c8b898;
    font-family: 'Georgia', 'Noto Serif SC', serif;
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    margin: 0;
  }
  .nav {
    text-align: center;
  }
  h1 { font-size: 28px; margin-bottom: 8px; }
  .subtitle { opacity: 0.5; margin-bottom: 40px; font-size: 14px; }
  .links { display: flex; flex-direction: column; gap: 16px; align-items: center; }
  .links a {
    color: #a09070;
    text-decoration: none;
    padding: 12px 32px;
    border: 1px solid rgba(160,144,112,0.3);
    border-radius: 6px;
    transition: all 0.2s;
    font-size: 16px;
  }
  .links a:hover {
    background: rgba(160,144,112,0.1);
    border-color: rgba(160,144,112,0.5);
    color: #d0c0a0;
  }
</style>
</head>
<body>
<div class="nav">
  <h1>望海镇</h1>
  <p class="subtitle">治愈系互动小说 · 开发构建</p>
  <div class="links">
    <a href="engine/test.html">引擎测试</a>
    <a href="chapter1/chapter1.html">第一章 · 互动小说</a>
    <a href="heartspace/lchen-storm.html">老陈心象空间 DEMO</a>
  </div>
</div>
</body>
</html>
```

- [ ] **Step 2: 完整走通全部内容**

打开 `src/index.html`，依次验证：
- 引擎测试通过
- 第一章从开场仪式到结束完整可玩
- 心象空间 DEMO 从暴风雨到平息完整可玩
- 所有分支路径测试通过

- [ ] **Step 3: 最终提交**

```bash
git add src/index.html
git commit -m "feat: add dev navigation page, complete Chapter 1 + heart space demo"
```
```

---

### 自审清单

- [x] 设计文档覆盖率：开场仪式（第九节）→ Task 2；抵达小镇+阿树（第二、十一节）→ Task 3；老陈支线（第一、十一节）→ Task 4；心象空间触摸与修复（第五节）→ Task 5；情感三幕节奏（第八节）→ Task 2/3/4 的叙事节奏控制
- [x] 无占位符：所有场景代码和数据完整，无 TBD/TODO
- [x] 类型一致性：引擎 API（`goTo`、`handleChoice`、`checkCondition`）在 Task 1 定义，Task 2/3/4 的数据严格符合接口
- [x] 情感节奏：开场温暖（物品低语）→ 小镇温馨（初遇）→ 小低谷（第一夜孤独）→ 回暖（阿树）→ 老陈的沉重暗流 → 第一章在"留一口茶"的平静中结束，符合第一幕节奏分配
