class XPSystem {
    constructor() {
        this.jobs = {
            pizza_delivery: { xp: 0, level: 1, xpToLevel: 100, icon: '🍕' },
            gardening: { xp: 0, level: 1, xpToLevel: 100, icon: '🌱' },
            coding: { xp: 0, level: 1, xpToLevel: 100, icon: '💻' },
            dog_walking: { xp: 0, level: 1, xpToLevel: 100, icon: '🐕' }
        };
        
        this.init();
        this.setupEventListeners();
        this.requestXPData();
    }

    init() {
        this.renderJobCards();
        this.updateStats();
    }

    setupEventListeners() {
        // Close button
        document.getElementById('closeBtn').addEventListener('click', () => {
            this.closeUI();
        });

        // ESC key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeUI();
            }
        });

        if (typeof GetParentResourceName !== 'undefined') {
            // FiveM environment
            window.addEventListener('message', (event) => {
                const data = event.data;
                switch (data.type) {
                    case 'showUI':
                        this.showUI();
                        break;
                    case 'hideUI':
                        this.hideUI();
                        break;
                    case 'updateXP':
                        this.updateJobXP(data.job, data.xp, data.level, data.xpToLevel, data.leveledUp);
                        break;
                    case 'loadXP':
                        this.loadXPData(data.xpData);
                        break;
                    case 'xpGain':
                        this.showXPGain(data.job, data.amount);
                        break;
                }
            });
        }
    }

    renderJobCards() {
        const jobsGrid = document.getElementById('jobsGrid');
        jobsGrid.innerHTML = '';

        Object.entries(this.jobs).forEach(([jobName, jobData]) => {
            const jobCard = this.createJobCard(jobName, jobData);
            jobsGrid.appendChild(jobCard);
        });
    }

    createJobCard(jobName, jobData) {
        const card = document.createElement('div');
        card.className = 'job-card';
        card.innerHTML = `
            <div class="job-header">
                <div>
                    <div class="job-icon">${jobData.icon}</div>
                    <div class="job-name">${this.formatJobName(jobName)}</div>
                </div>
                <div class="job-level">Level ${jobData.level}</div>
            </div>
            <div class="xp-info">
                <div class="xp-text">
                    <span class="current-xp">${jobData.xp} XP</span>
                    <span class="max-xp">/ ${jobData.xpToLevel} XP</span>
                </div>
                <div class="xp-bar-container">
                    <div class="xp-bar" style="width: ${(jobData.xp / jobData.xpToLevel) * 100}%"></div>
                </div>
            </div>
        `;
        return card;
    }

    formatJobName(jobName) {
        return jobName.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
    }

    updateJobXP(job, xp, level, xpToLevel, leveledUp) {
        if (!this.jobs[job]) return;

        const oldLevel = this.jobs[job].level;
        this.jobs[job] = { ...this.jobs[job], xp, level, xpToLevel };

        this.renderJobCards();
        this.updateStats();

        if (leveledUp && level > oldLevel) {
            this.showLevelUp(job, level);
        }
    }

    loadXPData(xpData) {
        Object.entries(xpData).forEach(([job, data]) => {
            if (this.jobs[job]) {
                this.jobs[job] = {
                    ...this.jobs[job],
                    xp: data.xp || 0,
                    level: data.level || 1,
                    xpToLevel: data.xpToLevel || 100
                };
            }
        });

        this.renderJobCards();
        this.updateStats();
    }

    updateStats() {
        const totalLevel = Object.values(this.jobs).reduce((sum, job) => sum + job.level, 0);
        const totalXP = Object.values(this.jobs).reduce((sum, job) => sum + job.xp, 0);
        const highestLevel = Math.max(...Object.values(this.jobs).map(job => job.level));

        document.getElementById('totalLevel').textContent = totalLevel;
        document.getElementById('totalXP').textContent = totalXP.toLocaleString();
        document.getElementById('highestLevel').textContent = highestLevel;
    }

    showLevelUp(job, level) {
        const overlay = document.getElementById('levelUpOverlay');
        const jobElement = document.getElementById('levelUpJob');
        const levelElement = document.getElementById('levelUpLevel');

        jobElement.textContent = this.formatJobName(job);
        levelElement.textContent = `Level ${level}`;

        overlay.classList.add('show');


        setTimeout(() => {
            overlay.classList.remove('show');
        }, 3000);
    }

    showXPGain(job, amount) {
        const toast = document.getElementById('xpToast');
        const amountElement = document.getElementById('toastAmount');
        const jobElement = document.getElementById('toastJob');

        amountElement.textContent = `+${amount} XP`;
        jobElement.textContent = this.formatJobName(job);

        toast.classList.add('show');

        setTimeout(() => {
            toast.classList.remove('show');
        }, 2000);
    }

    showUI() {
        this.requestXPData();
        document.body.style.display = 'flex';
        document.getElementById('closeBtn').focus();
    }

    hideUI() {
        document.body.style.display = 'none';
    }

    closeUI() {
        if (typeof GetParentResourceName !== 'undefined') {
            fetch(`https://${GetParentResourceName()}/closeUI`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({})
            });
        }
        this.hideUI();
    }

    requestXPData() {
        if (typeof GetParentResourceName !== 'undefined') {
            fetch(`https://${GetParentResourceName()}/getJobLevels`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({})
            })
            .then(res => res.json())
            .then(jobData => {
                const jobsObj = {};
                jobData.forEach(job => {
                    jobsObj[job.name] = {
                        xp: job.xp,
                        level: job.level,
                        xpToLevel: job.xpToLevel,
                        icon: this.jobs[job.name] ? this.jobs[job.name].icon : ''
                    };
                });
                this.jobs = jobsObj;
                this.renderJobCards();
                this.updateStats();
            });
        } else {
            this.loadDemoData();
        }
    }

    loadDemoData() {
        const demoData = {
            pizza_delivery: { xp: 75, level: 2, xpToLevel: 125 },
            gardening: { xp: 200, level: 3, xpToLevel: 156 },
            coding: { xp: 50, level: 1, xpToLevel: 100 },
            dog_walking: { xp: 300, level: 4, xpToLevel: 195 }
        };
        
        setTimeout(() => {
            this.loadXPData(demoData);
        }, 500);

        setInterval(() => {
            const jobs = Object.keys(this.jobs);
            const randomJob = jobs[Math.floor(Math.random() * jobs.length)];
            const randomAmount = Math.floor(Math.random() * 50) + 10;
            this.showXPGain(randomJob, randomAmount);
        }, 3000);

        setInterval(() => {
            const jobs = Object.keys(this.jobs);
            const randomJob = jobs[Math.floor(Math.random() * jobs.length)];
            const currentLevel = this.jobs[randomJob].level;
            this.showLevelUp(randomJob, currentLevel + 1);
        }, 10000);
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const xpSystem = new XPSystem();
    
    window.xpSystem = xpSystem;
});

function handleNUIMessage(data) {
    if (window.xpSystem) {
        window.dispatchEvent(new CustomEvent('message', { detail: { data } }));
    }
}