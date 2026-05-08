class StoryEngine {
  constructor(containerId, storyData) {
    this.container = document.getElementById(containerId);
    this.storyData = storyData;
    this.state = {
      currentScene: null,
      history: [],
      inventory: [],
      flags: {},
      relationships: {}
    };
    this.typingTimer = null;
  }

  start(sceneId) {
    this.goTo(sceneId);
  }

  goTo(sceneId) {
    const scene = this.storyData[sceneId];
    if (!scene) { console.error(`Scene "${sceneId}" not found`); return; }
    this.state.currentScene = sceneId;
    this.state.history.push(sceneId);
    this.renderScene(scene);
  }

  renderScene(scene) {
    this.clearTyping();
    const box = this.container.querySelector('.story-content');

    let html = '';
    if (scene.title) { html += `<h2 class="scene-title">${scene.title}</h2>`; }
    scene.paragraphs.forEach(p => { html += `<p class="story-text">${p}</p>`; });

    // Visible choices (filter by condition)
    const visibleChoices = (scene.choices || []).filter(c =>
      !c.condition || this.checkCondition(c.condition)
    );

    if (visibleChoices.length > 0) {
      html += '<div class="choices">';
      visibleChoices.forEach((choice, i) => {
        html += `<button class="choice-btn" data-index="${i}">${choice.text}</button>`;
      });
      html += '</div>';
    }

    // Auto-advance when no choices but has next
    if (scene.next && visibleChoices.length === 0) {
      html += '<button class="choice-btn continue-btn">继续...</button>';
    }

    box.innerHTML = html;
    this.bindEvents(scene, visibleChoices);

    if (scene.onEnter) { scene.onEnter(this.state); }
    box.scrollTop = 0;
  }

  bindEvents(scene, visibleChoices) {
    const buttons = this.container.querySelectorAll('.choice-btn');
    buttons.forEach(btn => {
      btn.addEventListener('click', () => {
        if (btn.classList.contains('continue-btn')) {
          this.handleAutoAdvance(scene);
        } else {
          const index = parseInt(btn.dataset.index);
          const choice = visibleChoices[index];
          this.handleChoice(scene, choice);
        }
      });
    });
  }

  handleChoice(scene, choice) {
    if (choice.setFlag) { this.state.flags[choice.setFlag] = true; }
    if (choice.addItem) { this.state.inventory.push(choice.addItem); }
    if (choice.setRelationship) {
      const rel = choice.setRelationship;
      this.state.relationships[rel.npc] = (this.state.relationships[rel.npc] || 0) + rel.change;
    }

    this.fadeOut(() => {
      const target = choice.next || scene.next;
      if (target) { this.goTo(target); }
    });
  }

  handleAutoAdvance(scene) {
    this.fadeOut(() => {
      if (scene.next) { this.goTo(scene.next); }
    });
  }

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

  fadeOut(callback) {
    const box = this.container.querySelector('.story-content');
    box.style.opacity = '0';
    box.style.transition = 'opacity 0.3s ease';
    setTimeout(() => {
      callback();
      box.style.opacity = '1';
    }, 300);
  }

  clearTyping() {
    if (this.typingTimer) { clearTimeout(this.typingTimer); this.typingTimer = null; }
  }
}

if (typeof module !== 'undefined') module.exports = { StoryEngine };
