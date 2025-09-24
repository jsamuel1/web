/* Pi-hole: A black hole for Internet advertisements
 *  (c) 2023 Pi-hole, LLC (https://pi-hole.net)
 *  Network-wide ad blocking via your own hardware.
 *
 *  This file is copyright under the latest version of the EUPL.
 *  Please see LICENSE file for your rights under this license. */

/* global utils:false, REFRESH_INTERVAL:false, Chart:false, customTooltips:false, THEME_COLORS:false */

"use strict";

// Global metrics storage object
const metricsStore = {
  // Page load metrics
  pageLoad: {
    domInteractive: 0,
    domComplete: 0,
    loadEvent: 0,
    firstContentfulPaint: 0,
    currentTime: Date.now()
  },
  // Component render times (key: componentId, value: render time in ms)
  componentRender: new Map(),
  // Network request metrics (key: requestUrl, value: {duration, status, timestamp})
  networkRequests: [],
  // Long-term storage for historical data
  history: {
    pageLoads: [],
    networkRequests: [],
    componentRenders: []
  }
};

// Maximum number of items to keep in history
const MAX_HISTORY_ITEMS = 100;

// Initialize metrics collection
function initMetricsCollection() {
  // Capture page load metrics
  collectPageLoadMetrics();
  
  // Set up network request monitoring
  setupNetworkMonitoring();
  
  // Set up periodic data cleanup and aggregation
  setInterval(cleanupMetricsData, 60 * 60 * 1000); // Clean up once per hour
}

// Collect page load metrics using the Performance API
function collectPageLoadMetrics() {
  // Wait until the page is fully loaded
  window.addEventListener('load', () => {
    // Use Performance API to get timing metrics
    if (window.performance && window.performance.timing) {
      const timing = window.performance.timing;
      
      // Calculate page load metrics
      const navStart = timing.navigationStart;
      metricsStore.pageLoad = {
        domInteractive: timing.domInteractive - navStart,
        domComplete: timing.domComplete - navStart,
        loadEvent: timing.loadEventEnd - navStart,
        currentTime: Date.now()
      };
      
      // Get First Contentful Paint if available
      const paintEntries = performance.getEntriesByType('paint');
      const fcpEntry = paintEntries.find(entry => entry.name === 'first-contentful-paint');
      if (fcpEntry) {
        metricsStore.pageLoad.firstContentfulPaint = fcpEntry.startTime;
      }
      
      // Add to history
      addToHistory('pageLoads', { ...metricsStore.pageLoad });
    }
  });
}

// Setup monitoring for all AJAX requests
function setupNetworkMonitoring() {
  // Store original XMLHttpRequest open and send methods
  const originalOpen = XMLHttpRequest.prototype.open;
  const originalSend = XMLHttpRequest.prototype.send;
  
  // Override the open method to track URL and method
  XMLHttpRequest.prototype.open = function(method, url) {
    this._metricsUrl = url;
    this._metricsMethod = method;
    this._metricsStartTime = Date.now();
    return originalOpen.apply(this, arguments);
  };
  
  // Override the send method to measure request duration
  XMLHttpRequest.prototype.send = function() {
    const request = this;
    request.addEventListener('load', () => {
      const endTime = Date.now();
      const duration = endTime - request._metricsStartTime;
      const requestData = {
        url: request._metricsUrl,
        method: request._metricsMethod,
        status: request.status,
        duration: duration,
        timestamp: endTime
      };
      
      // Store in metrics store
      metricsStore.networkRequests.push(requestData);
      
      // Add to history
      addToHistory('networkRequests', requestData);
    });
    
    return originalSend.apply(this, arguments);
  };
  
  // Also monitor fetch API
  const originalFetch = window.fetch;
  if (originalFetch) {
    window.fetch = function(url, options = {}) {
      const startTime = Date.now();
      
      return originalFetch.apply(this, arguments)
        .then(response => {
          const endTime = Date.now();
          const duration = endTime - startTime;
          const requestData = {
            url: typeof url === 'string' ? url : url.url,
            method: options.method || 'GET',
            status: response.status,
            duration: duration,
            timestamp: endTime
          };
          
          // Store in metrics store
          metricsStore.networkRequests.push(requestData);
          
          // Add to history
          addToHistory('networkRequests', requestData);
          
          return response;
        })
        .catch(error => {
          const endTime = Date.now();
          const duration = endTime - startTime;
          const requestData = {
            url: typeof url === 'string' ? url : url.url,
            method: options.method || 'GET',
            status: 'error',
            duration: duration,
            timestamp: endTime,
            error: error.message
          };
          
          // Store in metrics store
          metricsStore.networkRequests.push(requestData);
          
          // Add to history
          addToHistory('networkRequests', requestData);
          
          throw error;
        });
    };
  }
  
  // Monitor jQuery AJAX requests if jQuery is available
  if (window.jQuery) {
    $(document).ajaxSend((event, jqXHR, settings) => {
      jqXHR._metricsStartTime = Date.now();
    });
    
    $(document).ajaxComplete((event, jqXHR, settings) => {
      const endTime = Date.now();
      const duration = endTime - jqXHR._metricsStartTime;
      const requestData = {
        url: settings.url,
        method: settings.type || 'GET',
        status: jqXHR.status,
        duration: duration,
        timestamp: endTime
      };
      
      // Store in metrics store
      metricsStore.networkRequests.push(requestData);
      
      // Add to history
      addToHistory('networkRequests', requestData);
    });
  }
}

// Track component render time
function trackComponentRender(componentId, renderFunction) {
  const startTime = performance.now();
  const result = renderFunction();
  const endTime = performance.now();
  const renderTime = endTime - startTime;
  
  // Store the render time
  metricsStore.componentRender.set(componentId, renderTime);
  
  // Add to history
  addToHistory('componentRenders', { 
    componentId, 
    renderTime, 
    timestamp: Date.now() 
  });
  
  return result;
}

// Add data to history with limit on size
function addToHistory(type, data) {
  if (!metricsStore.history[type]) {
    metricsStore.history[type] = [];
  }
  
  // Add new item to history
  metricsStore.history[type].push(data);
  
  // Keep history at a reasonable size
  if (metricsStore.history[type].length > MAX_HISTORY_ITEMS) {
    metricsStore.history[type].shift();
  }
}

// Clean up old metrics data
function cleanupMetricsData() {
  // Clear network requests older than 1 hour
  const oneHourAgo = Date.now() - (60 * 60 * 1000);
  metricsStore.networkRequests = metricsStore.networkRequests.filter(
    request => request.timestamp > oneHourAgo
  );
}

// Provide summary metrics for display
function getPerformanceSummary() {
  // Calculate average page load time from history
  let avgPageLoad = 0;
  if (metricsStore.history.pageLoads.length > 0) {
    avgPageLoad = metricsStore.history.pageLoads.reduce(
      (sum, data) => sum + data.loadEvent, 0
    ) / metricsStore.history.pageLoads.length;
  }
  
  // Calculate average network request time
  let avgNetworkTime = 0;
  if (metricsStore.history.networkRequests.length > 0) {
    avgNetworkTime = metricsStore.history.networkRequests.reduce(
      (sum, data) => sum + data.duration, 0
    ) / metricsStore.history.networkRequests.length;
  }
  
  // Calculate average component render time
  let avgRenderTime = 0;
  if (metricsStore.history.componentRenders.length > 0) {
    avgRenderTime = metricsStore.history.componentRenders.reduce(
      (sum, data) => sum + data.renderTime, 0
    ) / metricsStore.history.componentRenders.length;
  }
  
  // Calculate slowest network requests
  const slowestRequests = [...metricsStore.history.networkRequests]
    .sort((a, b) => b.duration - a.duration)
    .slice(0, 5);
  
  // Calculate slowest component renders
  const slowestComponents = [...metricsStore.history.componentRenders]
    .sort((a, b) => b.renderTime - a.renderTime)
    .slice(0, 5);
  
  return {
    avgPageLoad,
    avgNetworkTime,
    avgRenderTime,
    currentPageLoad: metricsStore.pageLoad,
    slowestRequests,
    slowestComponents,
    totalRequests: metricsStore.history.networkRequests.length
  };
}

// Get time series data for charts
function getTimeSeriesData() {
  // Group network requests by time (5-minute intervals)
  const networkTimeSeries = groupByTimeInterval(
    metricsStore.history.networkRequests,
    request => request.timestamp,
    request => request.duration
  );
  
  // Group component renders by time
  const renderTimeSeries = groupByTimeInterval(
    metricsStore.history.componentRenders,
    render => render.timestamp,
    render => render.renderTime
  );
  
  // Group page loads by time
  const pageLoadTimeSeries = groupByTimeInterval(
    metricsStore.history.pageLoads,
    load => load.currentTime,
    load => load.loadEvent
  );
  
  return {
    networkTimeSeries,
    renderTimeSeries,
    pageLoadTimeSeries
  };
}

// Group data by time intervals (5-minute intervals)
function groupByTimeInterval(data, timestampFn, valueFn) {
  const INTERVAL = 5 * 60 * 1000; // 5 minutes in milliseconds
  const result = [];
  
  if (data.length === 0) {
    return [];
  }
  
  // Sort data by timestamp
  const sortedData = [...data].sort((a, b) => timestampFn(a) - timestampFn(b));
  
  // Find the start and end times
  const startTime = Math.floor(timestampFn(sortedData[0]) / INTERVAL) * INTERVAL;
  const endTime = Math.ceil(timestampFn(sortedData[sortedData.length - 1]) / INTERVAL) * INTERVAL;
  
  // Group data into intervals
  for (let time = startTime; time <= endTime; time += INTERVAL) {
    const intervalData = sortedData.filter(
      item => timestampFn(item) >= time && timestampFn(item) < time + INTERVAL
    );
    
    if (intervalData.length > 0) {
      const avgValue = intervalData.reduce((sum, item) => sum + valueFn(item), 0) / intervalData.length;
      result.push({
        timestamp: new Date(time),
        value: avgValue,
        count: intervalData.length
      });
    } else {
      // Include empty intervals for better visualization
      result.push({
        timestamp: new Date(time),
        value: 0,
        count: 0
      });
    }
  }
  
  return result;
}

// Create charts for performance dashboard
function createPerformanceCharts() {
  const timeSeriesData = getTimeSeriesData();
  
  // Create network requests chart
  createTimeSeriesChart(
    'networkRequestsChart', 
    'Network Request Duration (ms)',
    timeSeriesData.networkTimeSeries
  );
  
  // Create component render chart
  createTimeSeriesChart(
    'componentRenderChart', 
    'Component Render Time (ms)',
    timeSeriesData.renderTimeSeries
  );
  
  // Create page load chart
  createTimeSeriesChart(
    'pageLoadChart', 
    'Page Load Time (ms)',
    timeSeriesData.pageLoadTimeSeries
  );
  
  // Create top slow requests chart
  createTopSlowRequestsChart();
}

// Create a time series chart
function createTimeSeriesChart(chartId, label, data) {
  const ctx = document.getElementById(chartId);
  if (!ctx) return null;
  
  const gridColor = utils.getCSSval("graphs-grid", "background-color");
  const ticksColor = utils.getCSSval("graphs-ticks", "color");
  
  return new Chart(ctx, {
    type: 'line',
    data: {
      labels: data.map(point => point.timestamp),
      datasets: [{
        label: label,
        data: data.map(point => point.value),
        backgroundColor: THEME_COLORS[0],
        borderColor: THEME_COLORS[0],
        borderWidth: 2,
        fill: false,
        tension: 0.4
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      interaction: {
        mode: 'index',
        intersect: false,
      },
      plugins: {
        tooltip: {
          enabled: false,
          external: customTooltips,
          callbacks: {
            title(tooltipItems) {
              const date = new Date(tooltipItems[0].parsed.x);
              return date.toLocaleString();
            },
            label(tooltipItem) {
              return `${tooltipItem.dataset.label}: ${tooltipItem.parsed.y.toFixed(2)} ms`;
            }
          }
        }
      },
      scales: {
        x: {
          type: 'time',
          time: {
            unit: 'minute',
            displayFormats: {
              minute: 'HH:mm'
            }
          },
          grid: {
            color: gridColor
          },
          ticks: {
            color: ticksColor
          }
        },
        y: {
          beginAtZero: true,
          grid: {
            color: gridColor
          },
          ticks: {
            color: ticksColor
          }
        }
      }
    }
  });
}

// Create chart for top slowest requests
function createTopSlowRequestsChart() {
  const ctx = document.getElementById('topSlowRequestsChart');
  if (!ctx) return null;
  
  const summary = getPerformanceSummary();
  const slowestRequests = summary.slowestRequests;
  
  const gridColor = utils.getCSSval("graphs-grid", "background-color");
  const ticksColor = utils.getCSSval("graphs-ticks", "color");
  
  // Extract path from URL for cleaner labels
  const labels = slowestRequests.map(req => {
    try {
      const url = new URL(req.url, window.location.origin);
      return url.pathname;
    } catch (e) {
      return req.url;
    }
  });
  
  return new Chart(ctx, {
    type: 'bar',
    data: {
      labels: labels,
      datasets: [{
        label: 'Request Duration (ms)',
        data: slowestRequests.map(req => req.duration),
        backgroundColor: slowestRequests.map((_, i) => THEME_COLORS[i % THEME_COLORS.length]),
        borderColor: slowestRequests.map((_, i) => THEME_COLORS[i % THEME_COLORS.length]),
        borderWidth: 1
      }]
    },
    options: {
      indexAxis: 'y',
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        tooltip: {
          callbacks: {
            title(tooltipItems) {
              return slowestRequests[tooltipItems[0].dataIndex].url;
            },
            label(tooltipItem) {
              const request = slowestRequests[tooltipItem.dataIndex];
              return [
                `Duration: ${request.duration} ms`,
                `Status: ${request.status}`,
                `Method: ${request.method}`
              ];
            }
          }
        }
      },
      scales: {
        x: {
          beginAtZero: true,
          grid: {
            color: gridColor
          },
          ticks: {
            color: ticksColor
          }
        },
        y: {
          grid: {
            color: gridColor
          },
          ticks: {
            color: ticksColor
          }
        }
      }
    }
  });
}

// Update the dashboard with the latest data
function updatePerformanceDashboard() {
  const summary = getPerformanceSummary();
  
  // Update summary metrics
  document.getElementById('avgPageLoad').textContent = summary.avgPageLoad.toFixed(2) + ' ms';
  document.getElementById('avgNetworkTime').textContent = summary.avgNetworkTime.toFixed(2) + ' ms';
  document.getElementById('avgRenderTime').textContent = summary.avgRenderTime.toFixed(2) + ' ms';
  document.getElementById('totalRequests').textContent = summary.totalRequests;
  
  // Update current page metrics
  document.getElementById('currentDomInteractive').textContent = 
    summary.currentPageLoad.domInteractive.toFixed(2) + ' ms';
  document.getElementById('currentDomComplete').textContent = 
    summary.currentPageLoad.domComplete.toFixed(2) + ' ms';
  document.getElementById('currentLoadEvent').textContent = 
    summary.currentPageLoad.loadEvent.toFixed(2) + ' ms';
  document.getElementById('currentFCP').textContent = 
    summary.currentPageLoad.firstContentfulPaint.toFixed(2) + ' ms';
  
  // Recreate charts with fresh data
  createPerformanceCharts();
}

// Initialize metrics when document is ready
$(() => {
  initMetricsCollection();
  
  // If we're on the performance dashboard page, set up periodic updates
  if (document.getElementById('performance-dashboard')) {
    updatePerformanceDashboard();
    utils.setTimer(updatePerformanceDashboard, REFRESH_INTERVAL.summary);
  }
});

// Export to global scope for use in other scripts
globalThis.metrics = (function() {
  return {
    trackComponentRender,
    getPerformanceSummary,
    getTimeSeriesData,
    updatePerformanceDashboard,
    createPerformanceCharts
  };
})();