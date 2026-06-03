// ================================================================
// Krishi Drishti — Farming Advisory Module
// ================================================================
// Features:
//   - Nearby Services (KBTs, seed shops, fertilizer shops on GIS map)
//   - Crop Farming Calendar (sowing, harvest, pesticide timing)
//   - Pest & Disease Management (detailed measures)
//   - Current Season Tips
// ================================================================

// ── Create the farming advisory views ──

function createFarmingViews() {
    const mainContainer = document.querySelector('.max-w-screen-2xl.mx-auto');
    if (!mainContainer) return;
    
    // Create advisory view
    const advisoryView = document.createElement('div');
    advisoryView.id = 'view-advisory';
    advisoryView.className = 'page-view';
    advisoryView.innerHTML = getAdvisoryHTML();
    mainContainer.appendChild(advisoryView);
    
    // Create nearby services view
    const nearbyView = document.createElement('div');
    nearbyView.id = 'view-nearby-services';
    nearbyView.className = 'page-view';
    nearbyView.innerHTML = getNearbyServicesHTML();
    mainContainer.appendChild(nearbyView);
    
    // Create pest management view
    const pestView = document.createElement('div');
    pestView.id = 'view-pest-management';
    pestView.className = 'page-view';
    pestView.innerHTML = getPestManagementHTML();
    mainContainer.appendChild(pestView);
}

// ── Farming Advisory View ──

function getAdvisoryHTML() {
    return `
        <div class="bg-zinc-900 rounded-2xl sm:rounded-3xl p-5 sm:p-8 border border-zinc-800">
            <div class="flex items-center justify-between mb-6">
                <h2 class="text-2xl font-bold flex items-center gap-3">
                    <span>🌾</span> Farming Advisory
                </h2>
                <span class="text-xs text-zinc-500" id="advisorySeason"></span>
            </div>
            
            <!-- Season Info -->
            <div id="seasonBanner" class="bg-emerald-900/30 border border-emerald-700/40 rounded-2xl p-4 sm:p-6 mb-6">
                <div id="seasonContent" class="text-sm text-zinc-300">Loading season info...</div>
            </div>
            
            <!-- Quick Actions -->
            <div class="grid grid-cols-2 sm:grid-cols-3 gap-3 mb-6">
                <button onclick="showCropCalendar()" class="bg-zinc-800 hover:bg-zinc-700 p-4 rounded-xl text-center transition group">
                    <div class="text-2xl mb-1 group-hover:scale-110 transition">📅</div>
                    <div class="text-xs font-medium">Crop Calendar</div>
                    <div class="text-[10px] text-zinc-500">Sowing & harvest timing</div>
                </button>
                <button onclick="showPestManagement()" class="bg-zinc-800 hover:bg-zinc-700 p-4 rounded-xl text-center transition group">
                    <div class="text-2xl mb-1 group-hover:scale-110 transition">🐛</div>
                    <div class="text-xs font-medium">Pest Control</div>
                    <div class="text-[10px] text-zinc-500">Disease management</div>
                </button>
                <button onclick="showNearbyServices()" class="bg-zinc-800 hover:bg-zinc-700 p-4 rounded-xl text-center transition group">
                    <div class="text-2xl mb-1 group-hover:scale-110 transition">🏪</div>
                    <div class="text-xs font-medium">Nearby Shops</div>
                    <div class="text-[10px] text-zinc-500">KBTs & supply stores</div>
                </button>
            </div>
            
            <!-- Fertilizer Schedule -->
            <div class="section-card bg-zinc-800/50 rounded-2xl p-5 border border-zinc-700/50 mb-6">
                <h3 class="font-semibold text-emerald-400 mb-4">🧪 Fertilizer Schedule</h3>
                <div id="fertilizerContent" class="text-sm text-zinc-300 space-y-2">
                    Loading recommendations...
                </div>
            </div>
            
            <!-- Top Tips -->
            <div class="section-card bg-zinc-800/50 rounded-2xl p-5 border border-zinc-700/50">
                <h3 class="font-semibold text-amber-400 mb-4">💡 Top Tips for This Season</h3>
                <div id="tipsContent" class="text-sm text-zinc-300 space-y-2">
                    Loading tips...
                </div>
            </div>
            
            <button onclick="navigateTo('dashboard')" class="mt-6 w-full py-3 bg-zinc-800 hover:bg-zinc-700 rounded-xl font-semibold text-sm transition">
                ← Back to Dashboard
            </button>
        </div>
    `;
}

// ── Nearby Services View ──

function getNearbyServicesHTML() {
    return `
        <div class="bg-zinc-900 rounded-2xl sm:rounded-3xl p-5 sm:p-8 border border-zinc-800">
            <div class="flex items-center justify-between mb-4">
                <h2 class="text-2xl font-bold flex items-center gap-3">
                    <span>🏪</span> Nearby Agri Services
                </h2>
                <button onclick="refreshNearbyServices()" class="px-3 py-2 bg-emerald-600 hover:bg-emerald-700 rounded-xl text-xs font-semibold transition">🔄 Refresh</button>
            </div>
            
            <div class="text-xs text-zinc-500 mb-4">
                <span>📍 Showing services near your location</span>
                <span class="mx-2">•</span>
                <span id="serviceCount">Searching...</span>
            </div>
            
            <!-- Services Map Placeholder -->
            <div class="bg-zinc-800/60 rounded-2xl p-4 mb-6 border border-zinc-700/50">
                <div id="servicesMapContainer" style="height:250px; border-radius:12px; background:#1a1a2e;" class="flex items-center justify-center">
                    <div class="text-center">
                        <div class="text-4xl mb-2">🗺️</div>
                        <div class="text-sm text-zinc-400">Nearby Services Map</div>
                        <div class="text-xs text-zinc-500 mt-1">Shows KBTs, seed shops & fertilizer stores</div>
                    </div>
                </div>
            </div>
            
            <!-- Service Filters -->
            <div class="flex flex-wrap gap-2 mb-4">
                <button onclick="filterServices('all')" class="service-filter px-3 py-1.5 bg-emerald-600 text-white rounded-lg text-xs font-semibold transition" data-filter="all">All</button>
                <button onclick="filterServices('kbt')" class="service-filter px-3 py-1.5 bg-zinc-700 hover:bg-zinc-600 rounded-lg text-xs transition" data-filter="kbt">🏛️ KBTs</button>
                <button onclick="filterServices('seed_shop')" class="service-filter px-3 py-1.5 bg-zinc-700 hover:bg-zinc-600 rounded-lg text-xs transition" data-filter="seed_shop">🌱 Seed Shops</button>
                <button onclick="filterServices('fertilizer_shop')" class="service-filter px-3 py-1.5 bg-zinc-700 hover:bg-zinc-600 rounded-lg text-xs transition" data-filter="fertilizer_shop">🧪 Fertilizer</button>
                <button onclick="filterServices('pesticide_shop')" class="service-filter px-3 py-1.5 bg-zinc-700 hover:bg-zinc-600 rounded-lg text-xs transition" data-filter="pesticide_shop">🧴 Pesticides</button>
            </div>
            
            <!-- Services List -->
            <div id="servicesList" class="space-y-3">
                <div class="text-zinc-500 text-sm py-8 text-center">🔍 Loading nearby services...</div>
            </div>
            
            <button onclick="navigateTo('advisory')" class="mt-4 w-full py-3 bg-zinc-800 hover:bg-zinc-700 rounded-xl font-semibold text-sm transition">
                ← Back to Advisory
            </button>
        </div>
    `;
}

// ── Pest Management View ──

function getPestManagementHTML() {
    return `
        <div class="bg-zinc-900 rounded-2xl sm:rounded-3xl p-5 sm:p-8 border border-zinc-800">
            <div class="flex items-center justify-between mb-6">
                <h2 class="text-2xl font-bold flex items-center gap-3">
                    <span>🐛</span> Pest & Disease Management
                </h2>
            </div>
            
            <!-- Pest Selection -->
            <div class="grid grid-cols-2 gap-2 mb-6">
                <button onclick="showPestDetail('blast_rice')" class="bg-zinc-800 hover:bg-zinc-700 p-4 rounded-xl text-center transition group">
                    <div class="text-2xl mb-1">🌾</div>
                    <div class="text-xs font-medium">Blast Disease</div>
                    <div class="text-[10px] text-zinc-500">Rice</div>
                </button>
                <button onclick="showPestDetail('rust_wheat')" class="bg-zinc-800 hover:bg-zinc-700 p-4 rounded-xl text-center transition group">
                    <div class="text-2xl mb-1">🌾</div>
                    <div class="text-xs font-medium">Rust Disease</div>
                    <div class="text-[10px] text-zinc-500">Wheat</div>
                </button>
                <button onclick="showPestDetail('bollworm_cotton')" class="bg-zinc-800 hover:bg-zinc-700 p-4 rounded-xl text-center transition group">
                    <div class="text-2xl mb-1">🧶</div>
                    <div class="text-xs font-medium">Bollworm</div>
                    <div class="text-[10px] text-zinc-500">Cotton</div>
                </button>
                <button onclick="showPestDetail('powdery_mildew')" class="bg-zinc-800 hover:bg-zinc-700 p-4 rounded-xl text-center transition group">
                    <div class="text-2xl mb-1">🍚</div>
                    <div class="text-xs font-medium">Powdery Mildew</div>
                    <div class="text-[10px] text-zinc-500">Multiple crops</div>
                </button>
            </div>
            
            <!-- Pest Detail -->
            <div id="pestDetail" class="text-zinc-500 text-sm py-4 text-center">
                👆 Select a pest/disease above for detailed management information
            </div>
            
            <button onclick="navigateTo('advisory')" class="mt-4 w-full py-3 bg-zinc-800 hover:bg-zinc-700 rounded-xl font-semibold text-sm transition">
                ← Back to Advisory
            </button>
        </div>
    `;
}

// ── Crop Calendar Modal ──

function showCropCalendar() {
    const modal = createModal();
    modal.innerHTML = `
        <div class="bg-zinc-900 rounded-3xl p-6 sm:p-8 max-w-4xl w-full max-h-[90vh] overflow-auto border border-emerald-700 modal-overlay slide-up">
            <div class="flex justify-between items-start mb-6">
                <h3 class="text-xl font-bold">📅 Crop Calendar 2026</h3>
                <button onclick="this.closest('.fixed').remove()" class="text-zinc-400 hover:text-white text-xl">✕</button>
            </div>
            <div class="space-y-4 text-sm">
                ${getCropCalendarHTML()}
            </div>
            <button onclick="this.closest('.fixed').remove()" class="mt-6 w-full py-3 bg-emerald-600 hover:bg-emerald-700 rounded-xl font-bold text-sm transition">Close</button>
        </div>
    `;
    document.body.appendChild(modal);
}

function getCropCalendarHTML() {
    const crops = [
        { name: '🌾 Rice', season: 'Kharif (Monsoon)', sow: 'June - July', harvest: 'Sept - Oct', days: '120-150', temp: '25-35°C', rain: '100-200 cm' },
        { name: '🌾 Wheat', season: 'Rabi (Winter)', sow: 'Oct - Dec', harvest: 'Feb - April', days: '120-150', temp: '15-25°C', rain: '50-100 cm' },
        { name: '🧶 Cotton', season: 'Kharif', sow: 'May - June', harvest: 'Oct - Nov', days: '180-200', temp: '21-30°C', rain: '75-100 cm' },
        { name: '🎋 Sugarcane', season: 'Annual', sow: 'Feb - March', harvest: 'Dec - March', days: '300-360', temp: '21-27°C', rain: '75-120 cm' },
        { name: '🫘 Pulses', season: 'Kharif/Rabi', sow: 'June-July/Oct', harvest: 'Sept-Dec', days: '90-140', temp: '20-30°C', rain: '60-80 cm' },
    ];
    
    return `
        <div class="overflow-auto">
            <table class="w-full text-xs">
                <thead>
                    <tr class="bg-zinc-800 text-zinc-300">
                        <th class="p-3 text-left">Crop</th>
                        <th class="p-3 text-left">Season</th>
                        <th class="p-3 text-left">Sowing</th>
                        <th class="p-3 text-left">Harvest</th>
                        <th class="p-3 text-left">Duration</th>
                        <th class="p-3 text-left">Temp</th>
                        <th class="p-3 text-left">Rainfall</th>
                    </tr>
                </thead>
                <tbody>
                    ${crops.map(c => `
                        <tr class="border-b border-zinc-800 hover:bg-zinc-800/50">
                            <td class="p-3 font-medium">${c.name}</td>
                            <td class="p-3 text-zinc-400">${c.season}</td>
                            <td class="p-3 text-emerald-400">${c.sow}</td>
                            <td class="p-3 text-amber-400">${c.harvest}</td>
                            <td class="p-3 text-zinc-400">${c.days}</td>
                            <td class="p-3 text-zinc-400">${c.temp}</td>
                            <td class="p-3 text-sky-400">${c.rain}</td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
        <div class="mt-4 p-4 bg-zinc-800/50 rounded-xl">
            <p class="font-semibold text-emerald-400 mb-2">💡 Key Tips</p>
            <ul class="text-xs text-zinc-300 space-y-1 list-disc list-inside">
                <li><strong>Kharif</strong> = Monsoon crops (June-Nov). Sow with first rains.</li>
                <li><strong>Rabi</strong> = Winter crops (Oct-April). Sow after monsoon ends.</li>
                <li><strong>Zaid</strong> = Summer crops (Feb-May). Short duration between seasons.</li>
                <li>Always use certified seeds from authorized KBTs for best yields.</li>
                <li>Get soil tested before every season for fertilizer recommendations.</li>
            </ul>
        </div>
    `;
}

// ── Pest Detail View ──

function showPestDetail(pestKey) {
    const container = document.getElementById('pestDetail');
    if (!container) return;
    
    const pestDB = {
        blast_rice: {
            name: '🌾 Blast Disease (Rice)',
            crops: 'Rice',
            symptoms: 'Diamond-shaped spots on leaves with grey center. Lesions on nodes and panicles. Can cause complete crop loss.',
            causes: 'Fungal pathogen. High humidity (90%+) and 25-28°C. Spreads through airborne spores.',
            prevention: ['Use resistant varieties (IR64, Pusa Basmati-1)', 'Avoid excessive nitrogen fertilizer', 'Maintain proper spacing (20×15cm)', 'Keep fields weed-free'],
            organic: ['Neem oil (5ml/liter water) - spray every 10 days', 'Trichoderma viride (2.5kg/acre) - soil application', 'Bordeaux mixture (1%) spray', 'Cow urine (1:10 dilution) weekly'],
            chemical: ['Carbendazim 50% WP (1g/liter water)', 'Tricyclazole 75% WP (0.6g/liter water)', 'Edifenphos 50% EC (1ml/liter water)', 'Repeat every 10-15 days in severe cases'],
        },
        rust_wheat: {
            name: '🌾 Rust Disease (Wheat)',
            crops: 'Wheat, Barley',
            symptoms: 'Yellow/orange/brown pustules on leaves and stems. Rust-colored powder rubs off on fingers. Reduces grain filling.',
            causes: 'Fungal pathogen Puccinia spp. Wind-blown spores. Moderate temps (15-22°C) and high humidity.',
            prevention: ['Grow resistant varieties (HD 2967, PBW 550)', 'Avoid late sowing (before Nov 15)', 'Remove volunteer wheat plants', 'Crop rotation with non-host crops'],
            organic: ['Sulfur powder (15-20kg/acre) dusting', 'Garlic bulb extract spray', 'Baking soda (5g/liter water) weekly spray'],
            chemical: ['Propiconazole 25% EC (1ml/liter water)', 'Tebuconazole 25% WG (1g/liter water)', 'Zineb 75% WP (2g/liter water)', '2-3 sprays at 15-day intervals'],
        },
        bollworm_cotton: {
            name: '🧶 American Bollworm (Cotton)',
            crops: 'Cotton, Tomato, Chickpea',
            symptoms: 'Round bore holes on bolls. Larvae feed inside bolls destroying fibers. Premature boll drop.',
            causes: 'Helicoverpa armigera insect. Develops resistance quickly. Favored by moderate temps and flowering stage.',
            prevention: ['Grow Bt cotton varieties', 'Install pheromone traps (5-6/acre)', 'Plant marigold as trap crop', 'Avoid continuous cotton cultivation'],
            organic: ['Neem kernel extract (5%) weekly', 'Bacillus thuringiensis (2g/liter water)', 'HaNPV virus (250 LE/acre) evening spray', 'Custard apple seed extract'],
            chemical: ['Indoxacarb 14.5% SC (0.5ml/liter water)', 'Spinosad 45% SC (0.3ml/liter water)', 'Chlorantraniliprole 18.5% SC (0.3ml/liter)', 'Rotate insecticides to avoid resistance'],
        },
        powdery_mildew: {
            name: '🍚 Powdery Mildew',
            crops: 'Wheat, Pulses, Vegetables, Grapes',
            symptoms: 'White/gray powdery coating on leaves and stems. Leaves curl and turn yellow. Reduced photosynthesis.',
            causes: 'Fungal pathogen. Moderate temps (20-25°C) and high humidity. Spreads by wind.',
            prevention: ['Plant resistant varieties', 'Ensure proper spacing for air circulation', 'Avoid overhead irrigation', 'Remove infected plant debris'],
            organic: ['Milk spray (1:9 milk:water) weekly', 'Baking soda + oil spray', 'Neem oil (3ml/liter) every 7-10 days', 'Sulfur dusting (15kg/acre)'],
            chemical: ['Carbendazim 50% WP (1g/liter water)', 'Hexaconazole 5% EC (1ml/liter water)', 'Dinocap 48% EC (0.5ml/liter water)', '2-3 sprays at 10-day intervals'],
        }
    };
    
    const pest = pestDB[pestKey];
    if (!pest) {
        container.innerHTML = '<div class="text-red-400 text-sm py-4 text-center">Pest information not available</div>';
        return;
    }
    
    container.innerHTML = `
        <div class="space-y-4 slide-up">
            <div class="bg-red-900/20 border border-red-700/30 rounded-2xl p-5">
                <h3 class="text-lg font-bold text-red-400 mb-3">${pest.name}</h3>
                <div class="grid grid-cols-1 gap-3">
                    <div class="bg-zinc-800/50 rounded-xl p-3">
                        <span class="text-xs text-zinc-400">Affects:</span>
                        <span class="text-sm text-zinc-200 ml-2">${pest.crops}</span>
                    </div>
                </div>
            </div>
            
            <div class="bg-zinc-800/50 rounded-2xl p-5">
                <h4 class="font-semibold text-amber-400 mb-2">🔍 Symptoms</h4>
                <p class="text-sm text-zinc-300">${pest.symptoms}</p>
            </div>
            
            <div class="bg-zinc-800/50 rounded-2xl p-5">
                <h4 class="font-semibold text-orange-400 mb-2">⚠️ Causes</h4>
                <p class="text-sm text-zinc-300">${pest.causes}</p>
            </div>
            
            <div class="bg-zinc-800/50 rounded-2xl p-5">
                <h4 class="font-semibold text-emerald-400 mb-2">🛡️ Prevention</h4>
                <ul class="text-sm text-zinc-300 space-y-1">
                    ${pest.prevention.map(p => `<li class="flex items-start gap-2"><span class="text-emerald-500 mt-0.5">✅</span> ${p}</li>`).join('')}
                </ul>
            </div>
            
            <div class="bg-green-900/20 border border-green-700/30 rounded-2xl p-5">
                <h4 class="font-semibold text-green-400 mb-2">🌱 Organic Control</h4>
                <ul class="text-sm text-zinc-300 space-y-1">
                    ${pest.organic.map(o => `<li class="flex items-start gap-2"><span class="text-green-500 mt-0.5">🌿</span> ${o}</li>`).join('')}
                </ul>
            </div>
            
            <div class="bg-zinc-800/50 rounded-2xl p-5">
                <h4 class="font-semibold text-sky-400 mb-2">🧪 Chemical Control</h4>
                <ul class="text-sm text-zinc-300 space-y-1">
                    ${pest.chemical.map(c => `<li class="flex items-start gap-2"><span class="text-sky-500 mt-0.5">💊</span> ${c}</li>`).join('')}
                </ul>
            </div>
            
            <div class="bg-amber-900/20 border border-amber-700/30 rounded-2xl p-4">
                <p class="text-xs text-amber-300 font-medium">⏰ Critical: Apply treatment within 24-48 hours of first symptom appearance!</p>
            </div>
        </div>
    `;
}

// ── Show Pest Management View ──

function showPestManagement() {
    navigateTo('pest-management');
}

// ── Show Nearby Services View ──

function showNearbyServices() {
    navigateTo('nearby-services');
    loadNearbyServices();
}

// ── Load Nearby Services ──

async function loadNearbyServices() {
    const list = document.getElementById('servicesList');
    const count = document.getElementById('serviceCount');
    if (!list) return;
    
    list.innerHTML = '<div class="text-zinc-500 text-sm py-8 text-center"><div class="spinner mx-auto mb-4"></div>🔍 Searching for nearby agricultural services...</div>';
    
    try {
        // Get user location or use default (Varanasi demo)
        let lat = 25.3176, lng = 82.9739;
        if (APP.state.currentFarm) {
            lat = APP.state.currentFarm.lat;
            lng = APP.state.currentFarm.lng;
        }
        
        // Try the backend API first
        let services = [];
        try {
            const resp = await fetch(`${APP.config.apiBase}/api/v1/farming/nearby-services?lat=${lat}&lng=${lng}&radius=10`);
            const data = await resp.json();
            services = data.services || [];
        } catch(e) {
            // Fallback to local demo data
            services = getDemoServices(lat, lng);
        }
        
        window.currentServices = services;
        renderServices(services);
        count.textContent = `Found ${services.length} services nearby`;
        
    } catch(e) {
        list.innerHTML = '<div class="text-red-400 text-sm py-8 text-center">❌ Could not load services. Using demo data.</div>';
        const services = getDemoServices(25.3176, 82.9739);
        window.currentServices = services;
        renderServices(services);
    }
}

function getDemoServices(lat, lng) {
    return [
        { name: 'Krishi Bhandar - KBT Center', category: 'kbt', icon: '🏛️', latitude: lat + 0.008, longitude: lng - 0.005, address: 'Near Main Market', distance_km: 1.0, phone: '', opening_hours: '9:00 AM - 5:00 PM' },
        { name: 'Green Seed Store', category: 'seed_shop', icon: '🌱', latitude: lat - 0.006, longitude: lng + 0.004, address: 'Opposite Bus Stand', distance_km: 0.8, phone: '', opening_hours: '8:00 AM - 8:00 PM' },
        { name: 'Fertilizer Supply Co.', category: 'fertilizer_shop', icon: '🧪', latitude: lat + 0.005, longitude: lng + 0.008, address: 'Industrial Area', distance_km: 1.2, phone: '', opening_hours: '9:00 AM - 6:00 PM' },
        { name: 'Pesticide & Chemical Store', category: 'pesticide_shop', icon: '🧴', latitude: lat - 0.004, longitude: lng - 0.007, address: 'Market Road', distance_km: 0.9, phone: '', opening_hours: '9:00 AM - 7:00 PM' },
        { name: 'Krishi Vigyan Kendra', category: 'kbt', icon: '🏛️', latitude: lat + 0.012, longitude: lng - 0.002, address: 'Agricultural University', distance_km: 1.7, phone: '', opening_hours: '10:00 AM - 5:00 PM' },
        { name: 'Agri Tool Rental Center', category: 'agricultural_shop', icon: '🛒', latitude: lat - 0.003, longitude: lng + 0.010, address: 'Village Road Crossing', distance_km: 1.1, phone: '', opening_hours: '7:00 AM - 7:00 PM' },
        { name: 'Organic Fertilizer Depot', category: 'fertilizer_shop', icon: '🧪', latitude: lat + 0.007, longitude: lng - 0.010, address: 'Gram Panchayat Road', distance_km: 1.4, phone: '', opening_hours: '9:00 AM - 6:00 PM' },
        { name: 'Premium Seed House', category: 'seed_shop', icon: '🌱', latitude: lat - 0.009, longitude: lng + 0.006, address: 'Near Railway Station', distance_km: 1.3, phone: '', opening_hours: '8:00 AM - 8:00 PM' },
    ];
}

function renderServices(services) {
    const list = document.getElementById('servicesList');
    if (!list) return;
    
    if (!services || services.length === 0) {
        list.innerHTML = '<div class="text-zinc-500 text-sm py-8 text-center">No services found in your area.</div>';
        return;
    }
    
    list.innerHTML = services.map(s => `
        <div class="service-item bg-zinc-800/60 rounded-xl p-4 border border-zinc-700/50 flex items-start gap-3" data-category="${s.category}">
            <div class="text-2xl shrink-0 mt-1">${s.icon}</div>
            <div class="min-w-0 flex-1">
                <div class="font-semibold text-sm">${s.name}</div>
                <div class="text-xs text-zinc-400">${s.address}</div>
                <div class="flex flex-wrap gap-2 mt-1">
                    <span class="text-[10px] px-2 py-0.5 bg-zinc-700 rounded-full text-zinc-400">${s.distance_km ? s.distance_km + ' km' : ''}</span>
                    <span class="text-[10px] px-2 py-0.5 bg-zinc-700 rounded-full text-zinc-400">${s.category.replace('_', ' ')}</span>
                    ${s.opening_hours ? `<span class="text-[10px] px-2 py-0.5 bg-zinc-700 rounded-full text-zinc-400">${s.opening_hours}</span>` : ''}
                </div>
            </div>
        </div>
    `).join('');
}

function filterServices(category) {
    const items = document.querySelectorAll('.service-item');
    const buttons = document.querySelectorAll('.service-filter');
    
    buttons.forEach(b => {
        if (b.dataset.filter === category) {
            b.className = 'service-filter px-3 py-1.5 bg-emerald-600 text-white rounded-lg text-xs font-semibold transition';
        } else {
            b.className = 'service-filter px-3 py-1.5 bg-zinc-700 hover:bg-zinc-600 rounded-lg text-xs transition';
        }
    });
    
    items.forEach(item => {
        if (category === 'all' || item.dataset.category === category) {
            item.style.display = 'flex';
        } else {
            item.style.display = 'none';
        }
    });
}

function refreshNearbyServices() {
    loadNearbyServices();
}

// ── Load Season & Tips ──

async function loadFarmingData() {
    const seasonDiv = document.getElementById('seasonContent');
    const tipsDiv = document.getElementById('tipsContent');
    const fertilizerDiv = document.getElementById('fertilizerContent');
    const seasonLabel = document.getElementById('advisorySeason');
    
    if (!seasonDiv) return;
    
    try {
        const resp = await fetch(`${APP.config.apiBase}/api/v1/farming/farming-tips`);
        const data = await resp.json();
        
        if (data.success) {
            seasonDiv.innerHTML = `
                <div class="flex items-start gap-3">
                    <span class="text-2xl">🌤️</span>
                    <div>
                        <p class="font-semibold">${data.current_season}</p>
                        <p class="text-xs text-zinc-400 mt-1">Recommended crops: <strong>${data.recommended_crops.join(', ')}</strong></p>
                    </div>
                </div>
            `;
            if (seasonLabel) seasonLabel.textContent = data.current_season.split('—')[0] || '';
            
            tipsDiv.innerHTML = data.tips.map(t => 
                `<div class="flex items-start gap-2"><span class="text-emerald-500 shrink-0">✓</span><span>${t}</span></div>`
            ).join('');
        }
    } catch(e) {
        // Fallback to local data
        const month = new Date().getMonth();
        let season, crops, tips;
        if (month >= 5 && month <= 8) {
            season = 'Kharif (Monsoon)';
            crops = ['Rice', 'Cotton', 'Sugarcane'];
            tips = ['🌱 Complete sowing before July end', '💧 Ensure proper drainage', '🧪 Apply basal fertilizer', '🐛 Monitor for stem borer'];
        } else if (month >= 9 || month <= 1) {
            season = 'Rabi (Winter)';
            crops = ['Wheat', 'Mustard', 'Chickpea'];
            tips = ['🌱 Sow wheat before November 15', '💧 First irrigation at 20-25 days', '🧪 Apply full P & K as basal', '🐛 Watch for rust in wheat'];
        } else {
            season = 'Zaid (Summer)';
            crops = ['Summer Moong', 'Vegetables'];
            tips = ['🌱 Short-duration crops', '💧 Regular irrigation', '🧪 Organic mulching', '🐛 Monitor for thrips'];
        }
        
        seasonDiv.innerHTML = `<div class="flex items-start gap-3"><span class="text-2xl">🌤️</span><div><p class="font-semibold">${season} Season</p><p class="text-xs text-zinc-400 mt-1">Recommended: <strong>${crops.join(', ')}</strong></p></div></div>`;
        tipsDiv.innerHTML = tips.map(t => `<div class="flex items-start gap-2"><span class="text-emerald-500 shrink-0">✓</span><span>${t}</span></div>`).join('');
        if (seasonLabel) seasonLabel.textContent = season;
    }
    
    // Fertilizer recommendations
    if (fertilizerDiv) {
        const month = new Date().getMonth();
        let recs;
        if (month >= 5 && month <= 8) {
            recs = ['🌾 Rice: DAP 50kg + MOP 30kg/acre (basal)', '🧶 Cotton: DAP 40kg + MOP 30kg/acre (basal)', '🎋 Sugarcane: DAP 80kg + MOP 40kg/acre'];
        } else if (month >= 9 || month <= 1) {
            recs = ['🌾 Wheat: DAP 50kg + MOP 25kg/acre (basal)', '🫘 Pulses: DAP 30kg/acre (no extra N needed)', '🌱 Mustard: DAP 40kg + MOP 20kg/acre'];
        } else {
            recs = ['🥬 Vegetables: Compost 5ton/acre + NPK 50kg', '🌿 Fodder: Urea 40kg/acre after each cutting', '🌱 Soil testing recommended before application'];
        }
        fertilizerDiv.innerHTML = recs.map(r => `<div class="flex items-start gap-2"><span class="text-emerald-500 shrink-0">🧪</span><span>${r}</span></div>`).join('');
    }
}

// ── Expose functions globally ──

// Auto-init when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        setTimeout(createFarmingViews, 100);
        setTimeout(loadFarmingData, 1500);
    });
} else {
    setTimeout(createFarmingViews, 100);
    setTimeout(loadFarmingData, 1500);
}
