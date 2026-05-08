// src/heartspace/lchen-storm.js
// Lao Chen's Heart Space — Endless Stormy Night
// Core mechanic: Touch and Repair — collect memory fragments to calm the storm

class LchenHeartSpace {
  constructor() {
    this.fragments = [];
    this.collected = 0;
    this.totalFragments = 7;
    this.stormIntensity = 1.0;
    this.phase = 'intro';
    this.init();
  }

  init() {
    this.setupRain();
    this.showNarration('intro');
    setTimeout(() => {
      this.phase = 'collecting';
      this.spawnFragments();
      this.showNarration('collecting');
      this.startLightning();
    }, 6000);
  }

  setupRain() {
    const canvas = document.getElementById('rain-canvas');
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    const ctx = canvas.getContext('2d');

    const drops = Array.from({ length: 200 }, () => ({
      x: Math.random() * canvas.width, y: Math.random() * canvas.height,
      speed: 3 + Math.random() * 8, length: 10 + Math.random() * 20,
      opacity: 0.1 + Math.random() * 0.3
    }));

    const self = this;
    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      drops.forEach(d => {
        ctx.beginPath();
        ctx.moveTo(d.x, d.y);
        ctx.lineTo(d.x - 1, d.y + d.length);
        ctx.strokeStyle = `rgba(180,200,220,${d.opacity * self.stormIntensity})`;
        ctx.lineWidth = 0.5;
        ctx.stroke();
        d.y += d.speed * self.stormIntensity;
        d.x -= 1 * self.stormIntensity;
        if (d.y > canvas.height) { d.y = -d.length; d.x = Math.random() * canvas.width; }
        if (d.x < 0) d.x = canvas.width;
      });
      self.rainFrame = requestAnimationFrame(animate);
    };
    animate();
  }

  startLightning() {
    const lightning = document.getElementById('lightning');
    const self = this;
    const flash = () => {
      if (self.phase === 'complete') return;
      if (Math.random() < 0.3 * self.stormIntensity) {
        lightning.style.background = 'rgba(255,255,240,0.08)';
        setTimeout(() => { lightning.style.background = 'transparent'; }, 100 + Math.random() * 200);
      }
      self.lightningTimer = setTimeout(flash, 2000 + Math.random() * 5000);
    };
    flash();
  }

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

    const self = this;
    memories.forEach((mem, i) => {
      const frag = document.createElement('div');
      frag.className = 'fragment';
      frag.style.left = (15 + Math.random() * 70) + '%';
      frag.style.top = (20 + Math.random() * 60) + '%';
      frag.style.animationDelay = (i * 0.3) + 's';
      frag.addEventListener('click', () => self.collectFragment(frag, mem));
      area.appendChild(frag);
      this.fragments.push(frag);
    });
  }

  collectFragment(frag, mem) {
    if (frag.classList.contains('collected')) return;
    frag.classList.add('collected');
    this.collected++;
    this.showMemoryText(mem.text);
    this.stormIntensity = Math.max(0.05, 1 - (this.collected / this.totalFragments) * 0.95);
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
    setTimeout(() => {
      const textEl = narration.querySelector('.narration-text');
      if (textEl) textEl.classList.remove('visible');
    }, 3500);
  }

  showNarration(phase) {
    const narration = document.getElementById('narration');
    const texts = {
      intro: { text: '你走进了一场暴风雨。<br>这不是普通的风雨——这是老陈心里下了七年的那场。', hint: '' },
      collecting: { text: '风雨中有微弱的光点。那是他散落的记忆。<br>触碰它们——让它们重新被看见。', hint: '点击光点收集记忆碎片' }
    };
    const data = texts[phase];
    narration.innerHTML = `<div class="narration-text visible">${data.text}</div><div class="narration-hint">${data.hint}</div>`;
  }

  complete() {
    this.phase = 'complete';
    this.stormIntensity = 0;
    if (this.rainFrame) cancelAnimationFrame(this.rainFrame);
    if (this.lightningTimer) clearTimeout(this.lightningTimer);

    document.getElementById('rain-canvas').style.opacity = '0';
    document.getElementById('rain-canvas').style.transition = 'opacity 3s ease';
    document.getElementById('lightning').style.background = 'transparent';

    const overlay = document.createElement('div');
    overlay.className = 'completion-overlay visible';
    overlay.innerHTML = `
      <div class="completion-text">
        风暴停了。<br>七段记忆，七年。<br>
        它们一直在那里——只是需要有人看见。<br><br>
        <span style="font-size:14px;opacity:0.6;">老陈抬起头。灯塔的光变得比之前亮了。</span>
      </div>`;
    document.getElementById('heartspace').appendChild(overlay);

    document.getElementById('narration').innerHTML = `
      <div class="narration-text visible" style="text-align:center;">
        暴风雨停了。七段记忆都被找回来了。<br>——老陈的心象空间·完——
      </div>`;
  }
}

window.addEventListener('DOMContentLoaded', () => { new LchenHeartSpace(); });
