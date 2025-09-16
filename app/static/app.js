// Spotify Portfolio App JavaScript

// Global variable for user ID (will be set by template)
let userId = null;

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Any initialization code can go here
    console.log('Spotify Portfolio App loaded');
    console.log('✅ JavaScript functions available:', {
        getTopTracks: typeof getTopTracks,
        getTopArtists: typeof getTopArtists,
        getTopGenres: typeof getTopGenres,
        getAvgPopularity: typeof getAvgPopularity
    });
});

// Function to get user's top tracks
async function getTopTracks() {
    const section = document.getElementById('tracks-data');
    const loading = document.getElementById('tracks-loading');
    const list = document.getElementById('tracks-list');
    
    // Show the section and loading state
    section.style.display = 'block';
    loading.style.display = 'block';
    list.style.display = 'none';
    
    try {
        const response = await fetch('/user/top_tracks');
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        const data = await response.json();
        
        // Build HTML for tracks
        let html = '';
        data.tracks.forEach((track, index) => {
            html += `
                <div class="track-item">
                    <div class="item-index">${index + 1}</div>
                    <div class="item-info">
                        <div class="item-name">${escapeHtml(track.name)}</div>
                        <div class="item-details">by ${escapeHtml(track.artists[0].name)}</div>
                    </div>
                </div>
            `;
        });
        
        // Show results after a short delay for better UX
        setTimeout(() => {
            loading.style.display = 'none';
            list.innerHTML = html;
            list.style.display = 'block';
        }, 500);
        
    } catch (error) {
        console.error('Error loading tracks:', error);
        loading.innerHTML = `<p style="color: #ff4757;">L Error loading tracks: ${error.message}</p>`;
    }
}

// Function to get user's top artists
async function getTopArtists() {
    const section = document.getElementById('artists-data');
    const loading = document.getElementById('artists-loading');
    const list = document.getElementById('artists-list');
    
    // Show the section and loading state
    section.style.display = 'block';
    loading.style.display = 'block';
    list.style.display = 'none';
    
    try {
        const response = await fetch('/user/top_artists');
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        const data = await response.json();
        
        // Build HTML for artists
        let html = '';
        data.artists.forEach((artist, index) => {
            const genres = artist.genres && artist.genres.length > 0 
                ? artist.genres.slice(0, 3).join(', ') 
                : 'Various genres';
            
            html += `
                <div class="artist-item">
                    <div class="item-index">${index + 1}</div>
                    <div class="item-info">
                        <div class="item-name">${escapeHtml(artist.name)}</div>
                        <div class="item-details">${escapeHtml(genres)}</div>
                    </div>
                </div>
            `;
        });
        
        // Show results after a short delay for better UX
        setTimeout(() => {
            loading.style.display = 'none';
            list.innerHTML = html;
            list.style.display = 'block';
        }, 500);
        
    } catch (error) {
        console.error('Error loading artists:', error);
        loading.innerHTML = `<p style="color: #ff4757;">L Error loading artists: ${error.message}</p>`;
    }
}

// Function to delete user account
async function deleteUser() {
    const confirmed = confirm('� Are you sure you want to delete your account? This action cannot be undone.');
    
    if (!confirmed) {
        return;
    }
    
    try {
        const response = await fetch('/user', { 
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        const result = await response.json();
        alert(' Account deleted successfully');
        
        // Redirect to login page
        window.location.href = '/';
        
    } catch (error) {
        console.error('Error deleting account:', error);
        alert('L Error deleting account: ' + error.message);
    }
}

// Utility function to escape HTML and prevent XSS
function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, function(m) { return map[m]; });
}

// Function to show loading spinner
function showLoading(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.innerHTML = `
            <div class="loading">
                <div class="spinner"></div>
                Loading...
            </div>
        `;
    }
}

// Function to show error message
function showError(elementId, message) {
    const element = document.getElementById(elementId);
    if (element) {
        element.innerHTML = `
            <div class="loading">
                <p style="color: #ff4757;">L ${escapeHtml(message)}</p>
            </div>
        `;
    }
}

// Function to get user's top genres
async function getTopGenres() {
    console.log('🎨 getTopGenres() function called');
    
    const section = document.getElementById('genres-data');
    const loading = document.getElementById('genres-loading');
    const list = document.getElementById('genres-list');
    
    console.log('Elements found:', { section, loading, list });
    
    if (!section || !loading || !list) {
        console.error('❌ Required DOM elements not found');
        alert('Error: Required page elements not found. Please refresh the page.');
        return;
    }
    
    try {
        // Show the section and loading state
        console.log('📦 Showing section and loading state');
        section.style.display = 'block';
        loading.style.display = 'block';
        list.style.display = 'none';
        
        console.log('🌐 Making API call to /user/top_genres');
        const response = await fetch('/user/top_genres');
        console.log('📡 Response received:', response.status, response.statusText);
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        const data = await response.json();
        console.log('📊 Data received:', data);
        
        // Build HTML for genres
        let html = '';
        if (data.genres && data.genres.length > 0) {
            console.log(`🎵 Building HTML for ${data.genres.length} genres`);
            data.genres.forEach((genre, index) => {
                html += `
                    <div class="genre-item">
                        <div class="item-index">${index + 1}</div>
                        <div class="item-info">
                            <div class="item-name">${escapeHtml(genre.name)}</div>
                            <div class="item-details">${genre.count} artist${genre.count !== 1 ? 's' : ''}</div>
                        </div>
                    </div>
                `;
            });
        } else {
            console.log('🚫 No genres found in data');
            html = '<div class="no-data">No genres found in your top artists</div>';
        }
        
        // Show results after a short delay for better UX
        console.log('⏳ Showing results after delay');
        setTimeout(() => {
            loading.style.display = 'none';
            list.innerHTML = html;
            list.style.display = 'block';
            console.log('✅ Genres displayed successfully');
        }, 500);
        
    } catch (error) {
        console.error('❌ Error loading genres:', error);
        loading.innerHTML = `<p style="color: #ff4757;">❌ Error loading genres: ${error.message}</p>`;
        loading.style.display = 'block';
    }
}

// Function to get user's average popularity score
async function getAvgPopularity() {
    console.log('📊 getAvgPopularity() function called');
    
    const section = document.getElementById('popularity-data');
    const loading = document.getElementById('popularity-loading');
    const scoreDiv = document.getElementById('popularity-score');
    
    console.log('Elements found:', { section, loading, scoreDiv });
    
    if (!section || !loading || !scoreDiv) {
        console.error('❌ Required DOM elements not found');
        alert('Error: Required page elements not found. Please refresh the page.');
        return;
    }
    
    try {
        // Show the section and loading state
        console.log('📦 Showing section and loading state');
        section.style.display = 'block';
        loading.style.display = 'block';
        scoreDiv.style.display = 'none';
        
        console.log('🌐 Making API call to /user/avg_popularity');
        const response = await fetch('/user/avg_popularity');
        console.log('📡 Response received:', response.status, response.statusText);
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        const data = await response.json();
        console.log('📊 Data received:', data);
        
        // Determine popularity level description
        let description = '';
        const score = data.average_popularity;
        console.log('🎯 Popularity score:', score);
        
        if (score >= 80) description = 'Mainstream hits lover!';
        else if (score >= 60) description = 'Popular music fan';
        else if (score >= 40) description = 'Balanced taste';
        else if (score >= 20) description = 'Underground explorer';
        else description = 'Deep cuts connoisseur';
        
        console.log('📝 Description assigned:', description);
        
        // Build HTML for popularity score
        const html = `
            <div class="popularity-display">
                <div class="popularity-score-big">${score}/100</div>
                <div class="popularity-description">${description}</div>
                <div class="popularity-subtitle">Based on your top tracks</div>
            </div>
        `;
        
        // Show results after a short delay for better UX
        console.log('⏳ Showing results after delay');
        setTimeout(() => {
            loading.style.display = 'none';
            scoreDiv.innerHTML = html;
            scoreDiv.style.display = 'block';
            console.log('✅ Popularity score displayed successfully');
        }, 500);
        
    } catch (error) {
        console.error('❌ Error loading popularity:', error);
        loading.innerHTML = `<p style="color: #ff4757;">❌ Error loading popularity: ${error.message}</p>`;
        loading.style.display = 'block';
    }
}

// Export functions for global access
window.getTopTracks = getTopTracks;
window.getTopArtists = getTopArtists;
window.getTopGenres = getTopGenres;
window.getAvgPopularity = getAvgPopularity;
window.deleteUser = deleteUser;

// Debug: Verify functions are properly exported
console.log('🔧 Functions exported to window:', {
    getTopTracks: typeof window.getTopTracks,
    getTopArtists: typeof window.getTopArtists,
    getTopGenres: typeof window.getTopGenres,
    getAvgPopularity: typeof window.getAvgPopularity,
    deleteUser: typeof window.deleteUser
});