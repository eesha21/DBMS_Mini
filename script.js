const API_BASE_URL = 'http://127.0.0.1:5000';
let appData = { users: [], events: [], organisers: [], staff: [], security: [], tickets: [] };
let currentUser = null;

// --- DOM Elements ---
const loginPage = document.getElementById('login-page');
const dashboardPage = document.getElementById('dashboard-page');
const detailPage = document.getElementById('detail-page');
const bookingModal = document.getElementById('booking-modal');
const toast = document.getElementById('toast');
const toastMessage = document.getElementById('toast-message');

// --- API CALLS ---
async function fetchInitialData() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/data`);
        if (!response.ok) throw new Error('Network response was not ok');
        appData = await response.json();
        console.log('Data fetched from backend:', appData);
    } catch (error) {
        console.error('Failed to fetch initial data:', error);
        showToast('Error: Could not connect to the backend.');
    }
}

// --- PAGE NAVIGATION ---
function showPage(pageId) {
    [loginPage, dashboardPage, detailPage].forEach(page => page.classList.add('hidden'));
    document.getElementById(pageId).classList.remove('hidden');
}

// --- UI RENDERING ---
function renderEvents(filterLocation = '') {
    const eventsContainer = document.getElementById('events-container');
    const ongoingContainer = document.getElementById('ongoing-events-container');
    eventsContainer.innerHTML = '';
    ongoingContainer.innerHTML = '';
    const now = new Date();

    const filteredEvents = appData.events.filter(event => 
        filterLocation ? event.City.toLowerCase().includes(filterLocation.toLowerCase()) : true
    );

    if (filteredEvents.length === 0) {
        eventsContainer.innerHTML = `<p class="text-gray-500 col-span-full">No events found for this location.</p>`;
    }

    filteredEvents.forEach(event => {
        const startTime = new Date(event.StartTime);
        const endTime = new Date(event.EndTime);
        const isOngoing = now >= startTime && now <= endTime;

        const cardHTML = `
            <div class="bg-white rounded-xl shadow-lg overflow-hidden transform hover:-translate-y-1 transition-all duration-300 cursor-pointer" onclick="showEventDetail(${event.EventID})">
                <div class="p-6">
                    <p class="text-sm text-indigo-500 font-semibold">${event.VenueName}, ${event.City}</p>
                    <h3 class="text-xl font-bold mt-2">${event.EventName}</h3>
                    <p class="text-gray-600 mt-2">${startTime.toDateString()}</p>
                </div>
            </div>`;
        if (isOngoing && !filterLocation) {
            ongoingContainer.innerHTML += cardHTML;
        } else {
            eventsContainer.innerHTML += cardHTML;
        }
    });

    if (ongoingContainer.innerHTML === '' && !filterLocation) {
        ongoingContainer.innerHTML = `<p class="text-gray-500">No events are currently ongoing.</p>`;
    }
    lucide.createIcons();
}

function showEventDetail(eventId) {
    const event = appData.events.find(e => e.EventID === eventId);
    const organiser = appData.organisers.find(o => o.OrgID === event.OrgID);
    const eventStaff = appData.staff.filter(s => s.EventID === eventId);
    const totalRevenue = appData.tickets.filter(t => t.EventID === eventId).reduce((sum, ticket) => sum + ticket.Price, 0);

    const detailHTML = `
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div class="lg:col-span-2">
                <h2 class="text-5xl font-extrabold text-gray-900">${event.EventName}</h2>
                <p class="mt-4 text-xl text-gray-600">${new Date(event.StartTime).toLocaleString()}</p>
                <p class="mt-2 text-lg text-indigo-600 font-semibold">${event.VenueName}, ${event.City}</p>
                <button id="book-ticket-button" data-eventid="${eventId}" class="mt-8 w-full md:w-auto bg-green-600 text-white font-bold py-4 px-8 rounded-lg text-lg hover:bg-green-700 transition">Book Ticket</button>
            </div>
            <div class="space-y-6">
                <div class="bg-gray-100 p-6 rounded-lg"><h3 class="text-lg font-bold flex items-center"><i data-lucide="banknote" class="mr-2 h-5 w-5"></i>Total Revenue</h3><p class="text-3xl font-bold text-green-600 mt-2">₹${totalRevenue.toFixed(2)}</p></div>
                <div class="bg-gray-100 p-6 rounded-lg"><h3 class="text-lg font-bold">Organiser</h3><p class="text-gray-700 mt-1">${organiser.OrgName}</p></div>
            </div>
        </div>
        <div class="mt-12 grid grid-cols-1 md:grid-cols-2 gap-8">
            <div class="bg-gray-50 p-6 rounded-lg"><h3 class="text-2xl font-bold mb-4">Staff on Duty</h3><ul class="space-y-2">${eventStaff.map(s => `<li class="text-gray-700">${s.StaffName}</li>`).join('') || '<li>No staff assigned yet.</li>'}</ul></div>
            <div class="bg-gray-50 p-6 rounded-lg"><h3 class="text-2xl font-bold mb-4">Security Details</h3><ul class="space-y-2">${appData.security.map(s => `<li class="text-gray-700">${s.Name} (${s.Zone})</li>`).join('')}</ul></div>
        </div>`;
    document.getElementById('event-detail-container').innerHTML = detailHTML;
    document.getElementById('book-ticket-button').addEventListener('click', () => openBookingModal(eventId));
    lucide.createIcons();
    showPage('detail-page');
    window.scrollTo(0, 0);
}

function openBookingModal(eventId) {
    document.getElementById('booking-event-id').value = eventId;
    updateBookingPrice();
    bookingModal.classList.remove('hidden');
    setTimeout(() => bookingModal.querySelector('.modal').classList.replace('scale-95', 'scale-100'), 10);
}

function closeBookingModal() {
    bookingModal.querySelector('.modal').classList.replace('scale-100', 'scale-95');
    setTimeout(() => bookingModal.classList.add('hidden'), 300);
}

function updateBookingPrice() {
    const select = document.getElementById('booking-ticket-type');
    const price = select.options[select.selectedIndex].dataset.price;
    document.getElementById('booking-price').textContent = `₹${parseFloat(price).toFixed(2)}`;
}

function showToast(message) {
    toastMessage.textContent = message;
    toast.classList.replace('opacity-0', 'opacity-100');
    toast.classList.replace('translate-y-10', 'translate-y-0');
    setTimeout(() => {
        toast.classList.replace('opacity-100', 'opacity-0');
        toast.classList.replace('translate-y-0', 'translate-y-10');
    }, 3000);
}

// --- EVENT LISTENERS ---
document.addEventListener('DOMContentLoaded', () => {
    lucide.createIcons();
    showPage('login-page');

    document.getElementById('login-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        await fetchInitialData();
        const fname = e.target['login-fname'].value;
        currentUser = appData.users.find(u => u.FName.toLowerCase() === fname.toLowerCase());
        if (!currentUser) {
             currentUser = appData.users[0] || { UserID: 1, FName: fname, LName: ''};
        }
        document.getElementById('welcome-message').textContent = `Welcome, ${currentUser.FName}!`;
        renderEvents();
        showPage('dashboard-page');
    });

    document.getElementById('add-user-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const fName = e.target['signup-fname'].value;
        const lName = e.target['signup-lname'].value;
        try {
            const response = await fetch(`${API_BASE_URL}/api/users`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ FName: fName, LName: lName })
            });
            const result = await response.json();
            if (!response.ok) throw new Error(result.error);
            await fetchInitialData();
            showToast(`User "${fName} ${lName}" created successfully!`);
            e.target.reset();
        } catch (error) {
            console.error('Failed to add user:', error);
            showToast(`Error: ${error.message}`);
        }
    });

    document.getElementById('logout-button').addEventListener('click', () => {
        currentUser = null;
        appData = {};
        showPage('login-page');
    });

    document.getElementById('search-button').addEventListener('click', () => {
        const location = document.getElementById('location-search').value;
        renderEvents(location);
    });

    document.getElementById('back-to-dashboard').addEventListener('click', () => showPage('dashboard-page'));
    
    document.getElementById('cancel-booking').addEventListener('click', closeBookingModal);

    document.getElementById('booking-ticket-type').addEventListener('change', updateBookingPrice);
    
    document.getElementById('booking-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const eventId = parseInt(document.getElementById('booking-event-id').value);
        const select = document.getElementById('booking-ticket-type');
        const ticketType = select.value;
        const price = parseFloat(select.options[select.selectedIndex].dataset.price);
        try {
             const response = await fetch(`${API_BASE_URL}/api/book_ticket`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    UserID: currentUser.UserID,
                    EventID: eventId,
                    TicketType: ticketType,
                    Price: price
                })
            });
            const result = await response.json();
            if (!response.ok) throw new Error(result.error);
            await fetchInitialData();
            showToast(`Successfully booked a ${ticketType} ticket!`);
            closeBookingModal();
        } catch (error) {
            console.error('Failed to book ticket:', error);
            showToast(`Error: ${error.message}`);
        }
    });
});
