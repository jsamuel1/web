<!-- Pi-hole: A black hole for Internet advertisements
*  (c) 2023 Pi-hole, LLC (https://pi-hole.net)
*  Network-wide ad blocking via your own hardware.
*
*  This file is copyright under the latest version of the EUPL.
*  Please see LICENSE file for your rights under this license. -->
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Security-Policy" content="default-src 'self' 'unsafe-inline'">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="<?lua print(token) ?>">
    <title>Pi-hole - Performance Dashboard</title>

    <link rel="stylesheet" href="style/vendor/bootstrap.min.css">
    <link rel="stylesheet" href="style/vendor/daterangepicker.min.css">
    <link rel="stylesheet" href="style/vendor/animate.min.css">
    <link rel="stylesheet" href="style/vendor/adminLTE.min.css">
    <link rel="stylesheet" href="style/vendor/skin-blue.min.css">
    <link rel="stylesheet" href="style/vendor/fa-all.min.css">
    <link rel="stylesheet" href="style/vendor/nprogress.min.css">

    <link rel="stylesheet" href="style/pi-hole.css">
    <link rel="stylesheet" href="style/metrics.css">
    <link rel="stylesheet" href="style/themes/<?lua if theme then print(theme) else print("default") end ?>.css">
    <link rel="icon" type="image/png" sizes="any" href="img/favicons/favicon.png" referrerpolicy="same-origin">

    <script src="scripts/js/header.js"></script>
</head>
<body class="hold-transition sidebar-mini skin-blue <?lua if boxedlayout then print("layout-boxed") end ?>">
<div class="wrapper">
    <header class="main-header">
        <div class="container-fluid">
            <a href="index.lp" class="logo">
                <span class="logo-mini">P<b>h</b></span>
                <span class="logo-lg">Pi-<b>hole</b></span>
            </a>

            <nav class="navbar navbar-static-top">
                <div class="container-fluid">
                    <div class="navbar-header">
                        <a href="#" class="sidebar-toggle" data-toggle="push-menu" role="button">
                            <span class="sr-only">Toggle navigation</span>
                            <span class="icon-bar"></span>
                            <span class="icon-bar"></span>
                            <span class="icon-bar"></span>
                        </a>
                    </div>
                    <div class="collapse navbar-collapse" id="navbar-collapse">
                        <ul class="nav navbar-nav">
                            <li><a href="index.lp">Dashboard</a></li>
                            <li class="active"><a href="performance.lp">Performance</a></li>
                        </ul>
                    </div>
                </div>
            </nav>
        </div>
    </header>

    <?lua please_include("sidebar.lp") ?>
    
    <div class="content-wrapper">
        <section class="content-header">
            <h1>Performance Dashboard</h1>
        </section>
        
        <!-- Main content -->
        <section class="content" id="performance-dashboard">
            <!-- Performance Summary -->
            <div class="row">
                <div class="col-md-12">
                    <div class="box" id="performance-summary">
                        <div class="box-header with-border">
                            <h3 class="box-title">Performance Summary</h3>
                        </div>
                        <div class="box-body">
                            <div class="row">
                                <div class="col-md-3 col-sm-6 col-xs-12">
                                    <div class="info-box">
                                        <span class="info-box-icon bg-aqua"><i class="fas fa-clock"></i></span>
                                        <div class="info-box-content">
                                            <span class="info-box-text">Avg Page Load</span>
                                            <span class="info-box-number" id="avgPageLoad">0 ms</span>
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="col-md-3 col-sm-6 col-xs-12">
                                    <div class="info-box">
                                        <span class="info-box-icon bg-green"><i class="fas fa-network-wired"></i></span>
                                        <div class="info-box-content">
                                            <span class="info-box-text">Avg Network Time</span>
                                            <span class="info-box-number" id="avgNetworkTime">0 ms</span>
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="col-md-3 col-sm-6 col-xs-12">
                                    <div class="info-box">
                                        <span class="info-box-icon bg-yellow"><i class="fas fa-paint-brush"></i></span>
                                        <div class="info-box-content">
                                            <span class="info-box-text">Avg Render Time</span>
                                            <span class="info-box-number" id="avgRenderTime">0 ms</span>
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="col-md-3 col-sm-6 col-xs-12">
                                    <div class="info-box">
                                        <span class="info-box-icon bg-red"><i class="fas fa-exchange-alt"></i></span>
                                        <div class="info-box-content">
                                            <span class="info-box-text">Total Requests</span>
                                            <span class="info-box-number" id="totalRequests">0</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Current Page Metrics -->
            <div class="row">
                <div class="col-md-12">
                    <div class="box" id="current-page-metrics">
                        <div class="box-header with-border">
                            <h3 class="box-title">Current Page Metrics</h3>
                        </div>
                        <div class="box-body">
                            <div class="row">
                                <div class="col-md-3 col-sm-6">
                                    <div class="metric-box">
                                        <h4>DOM Interactive</h4>
                                        <p id="currentDomInteractive">0 ms</p>
                                    </div>
                                </div>
                                
                                <div class="col-md-3 col-sm-6">
                                    <div class="metric-box">
                                        <h4>DOM Complete</h4>
                                        <p id="currentDomComplete">0 ms</p>
                                    </div>
                                </div>
                                
                                <div class="col-md-3 col-sm-6">
                                    <div class="metric-box">
                                        <h4>Load Event</h4>
                                        <p id="currentLoadEvent">0 ms</p>
                                    </div>
                                </div>
                                
                                <div class="col-md-3 col-sm-6">
                                    <div class="metric-box">
                                        <h4>First Contentful Paint</h4>
                                        <p id="currentFCP">0 ms</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Network Request Performance -->
            <div class="row">
                <div class="col-md-8">
                    <div class="box" id="network-requests-time">
                        <div class="box-header with-border">
                            <h3 class="box-title">Network Request Performance</h3>
                        </div>
                        <div class="box-body">
                            <div class="chart-container" style="position: relative; height:300px;">
                                <canvas id="networkRequestsChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="col-md-4">
                    <div class="box" id="top-slow-requests">
                        <div class="box-header with-border">
                            <h3 class="box-title">Slowest Requests</h3>
                        </div>
                        <div class="box-body">
                            <div class="chart-container" style="position: relative; height:300px;">
                                <canvas id="topSlowRequestsChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Page Load and Component Render Performance -->
            <div class="row">
                <div class="col-md-6">
                    <div class="box" id="page-load-time">
                        <div class="box-header with-border">
                            <h3 class="box-title">Page Load Performance</h3>
                        </div>
                        <div class="box-body">
                            <div class="chart-container" style="position: relative; height:300px;">
                                <canvas id="pageLoadChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="col-md-6">
                    <div class="box" id="component-render-time">
                        <div class="box-header with-border">
                            <h3 class="box-title">Component Render Performance</h3>
                        </div>
                        <div class="box-body">
                            <div class="chart-container" style="position: relative; height:300px;">
                                <canvas id="componentRenderChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    </div>
    
    <footer class="main-footer">
        <div class="container-fluid">
            <p>© Pi-hole LLC</p>
        </div>
    </footer>
</div>

<script src="vendor/jquery/jquery.min.js"></script>
<script src="vendor/bootstrap/js/bootstrap.min.js"></script>
<script src="vendor/nprogress/nprogress.js"></script>
<script src="vendor/moment/moment.min.js"></script>
<script src="vendor/chartjs/chart.min.js"></script>
<script src="vendor/chartjs-plugin-zoom/chartjs-plugin-zoom.min.js"></script>
<script src="vendor/chartjs-adapter-moment/chartjs-adapter-moment.js"></script>
<script src="vendor/waitMe-js/waitMe.js"></script>

<script src="scripts/js/utils.js"></script>
<script src="scripts/js/charts.js"></script>
<script src="scripts/js/metrics.js"></script>
<script src="scripts/js/footer.js"></script>
</body>
</html>