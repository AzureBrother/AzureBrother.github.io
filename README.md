# Welcome to Azure Brother ☁️

Your friendly guides to Mastering Microsoft Entra ID & modern Azure identity.

<!-- Tab Navigation Header -->
<div class="tab-nav flex border-b border-slate-700 my-6 gap-2">
    <button onclick="switchTab('tab-tools')" id="btn-tab-tools" class="tab-btn px-5 py-3 font-semibold text-azureBlue border-b-2 border-[#0ea5e9] bg-slate-800/40 rounded-t-lg transition-all">
        🛠️ Interactive Tools
    </button>
    <button onclick="switchTab('tab-articles')" id="btn-tab-articles" class="tab-btn px-5 py-3 font-semibold text-slate-400 border-b-2 border-transparent hover:text-white transition-all">
        🛠️ How-To Articles
    </button>
    <button onclick="switchTab('tab-youtube')" id="btn-tab-youtube" class="tab-btn px-5 py-3 font-semibold text-slate-400 border-b-2 border-transparent hover:text-white transition-all">
        🎬 YouTube Channel
    </button>
</div>

<!-- TAB 1: INTERACTIVE TOOLS -->
<div id="tab-tools" class="tab-content block">
    <h2 class="text-xl font-bold mb-2">Interactive Passkey Decision Flow</h2>
    <p class="mb-4 text-slate-400">Use the tool below to determine the correct Entra ID passkey path for your environment:</p>
    
    <iframe src="/tools/passkey-flow.html" width="100%" height="600px" style="border:none; border-radius:12px; background: #0b1120;" loading="lazy"></iframe>
</div>

<!-- TAB 2: HOW-TO ARTICLES -->
<div id="tab-articles" class="tab-content hidden">
    <h2 class="text-xl font-bold mb-2">🛠️ How-To Articles</h2>
    <p class="mb-4 text-slate-400">Browse the latest guides and scripts to help secure and automate your tenant:</p>

    <ul class="space-y-4">
        <li>
            <a href="/articles/passwordless-day-one" class="text-[#0ea5e9] font-bold hover:underline text-lg">Passwordless from Day One | Windows Autopilot + TAP + WHfB + Passkeys</a>
            <p class="text-slate-300 italic text-sm mt-1">Learn how to onboard new employees with a 100% passwordless experience from day one using Temporary Access Pass, Windows Autopilot, and device/app-bound Passkeys.</p>
        </li>
        <li>
            <a href="/articles/entra-registration-campaigns" class="text-[#0ea5e9] font-bold hover:underline text-lg">Nobody Registers Passkeys... Until You Do This | Entra ID Registration Campaigns</a>
            <p class="text-slate-300 italic text-sm mt-1">Learn how to stop waiting for users to adopt passwordless authentication by configuring Microsoft Entra ID Registration Campaigns to gently (or forcibly) nudge them toward Passkeys.</p>
        </li>
    </ul>
</div>

<!-- TAB 3: YOUTUBE CHANNEL -->
<div id="tab-youtube" class="tab-content hidden">
    <h2 class="text-xl font-bold mb-2">🎬 The YouTube Channel</h2>
    <p class="mb-4">If you prefer video tutorials and visual walkthroughs, check out the companion YouTube channel!</p>
    <p>
        👉 <a href="https://youtube.com/@azurebrothers" target="_blank" class="text-[#0ea5e9] font-bold hover:underline">Subscribe to Azure Brother on YouTube</a>
    </p>
</div>

<!-- Tab Switching Script -->
<script>
    function switchTab(tabId) {
        // Hide all tab contents
        document.querySelectorAll('.tab-content').forEach(el => el.classList.add('hidden'));
        document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('block'));
        
        // Show selected tab content
        const activeTab = document.getElementById(tabId);
        if (activeTab) {
            activeTab.classList.remove('hidden');
            activeTab.classList.add('block');
        }

        // Reset all button styles
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.classList.remove('text-[#0ea5e9]', 'border-[#0ea5e9]', 'bg-slate-800/40');
            btn.classList.add('text-slate-400', 'border-transparent');
        });

        // Highlight selected button
        const activeBtn = document.getElementById('btn-' + tabId);
        if (activeBtn) {
            activeBtn.classList.remove('text-slate-400', 'border-transparent');
            activeBtn.classList.add('text-[#0ea5e9]', 'border-[#0ea5e9]', 'bg-slate-800/40');
        }
    }
</script>
