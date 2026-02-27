<?php
date_default_timezone_set('America/New_York');
$data_file = 'streams.json';
$api_key = '18243bf79ece4a9597583acf1de91056';
$jellyfin_url = 'http://172.18.0.8:8096';
$task_id = 'bea9b218c97bbf98c5dc1303bdb9a0ca';
$proxy_ip = '172.18.0.15';

$channels = [
    'usanetwork' => ['name' => 'USA Network', 'logo' => 'https://img.zuzz.tv/assets/channels/3DkMPY1wYO7mFGTGispHwPtw5VWwLGQvfhJGodUp4isSONVxwI.png'],
    'nhlnetwork' => ['name' => 'NHL Network', 'logo' => 'https://img.zuzz.tv/assets/channels/fmmBmmJBXkKtQQPtny0LyE8eS3AIU6yY5mroBTv0Q6SLuriMQy.png'],
    'nflnetwork' => ['name' => 'NFL Network', 'logo' => 'https://img.zuzz.tv/assets/channels/3DkMPY1wYO7mFGTGispHwPtw5VWwLGQvfhJGodUp4isSONVxwI.png'],
    'redzone'    => ['name' => 'NFL Redzone', 'logo' => 'https://img.zuzz.tv/assets/channels/QNw5GGgZ1VLbCNOXockuk9xTRBgXzRGkZBvWzXw4PZ6hMB6Pn7.png'],
    'sneast'     => ['name' => 'NHL Pens',    'logo' => '']
];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['channel']) && isset($_POST['url'])) {
    $streams = file_exists($data_file) ? json_decode(file_get_contents($data_file), true) : [];
    $streams[$_POST['channel']] = [
        'url' => $_POST['url'],
        'event' => $_POST['event'] ?: 'Live',
        'updated' => date('g:i A'),
        'ts' => time()
    ];
    file_put_contents($data_file, json_encode($streams));
    header("Location: index.php?updated=" . urlencode($_POST['channel']));
    exit;
}

if (isset($_GET['refresh'])) {
    // Clear Jellyfin's XMLTV cache so it re-fetches fresh guide data instead of
    // using a stale cached file. Cache files are named by listing-provider ID.
    $xmltv_cache_dir = '/jellyfin-cache/xmltv/';
    if (is_dir($xmltv_cache_dir)) {
        foreach (glob($xmltv_cache_dir . '*.xml') as $f) {
            @unlink($f);
        }
    }

    // Trigger Jellyfin's Refresh Guide scheduled task
    $url = $jellyfin_url . "/ScheduledTasks/Running/" . $task_id . "?api_key=" . $api_key;
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_exec($ch);
    curl_close($ch);
    header("Location: index.php?refreshed=1");
    exit;
}

if (isset($_GET['stream'])) {
    $streams = file_exists($data_file) ? json_decode(file_get_contents($data_file), true) : [];
    if (isset($streams[$_GET['stream']])) {
        $url = is_array($streams[$_GET['stream']]) ? $streams[$_GET['stream']]['url'] : $streams[$_GET['stream']];
        header("Location: " . $url);
        exit;
    }
}

// M3U - stable tvg-name so Jellyfin doesn't create duplicate channels on every update
if (isset($_GET['m3u'])) {
    header('Content-Type: audio/x-mpegurl');
    echo "#EXTM3U\n";
    foreach ($channels as $id => $info) {
        // tvg-name must never change — Jellyfin uses it as the channel identity key
        echo "#EXTINF:-1 tvg-id=\"$id\" tvg-name=\"{$info['name']}\" tvg-logo=\"{$info['logo']}\" group-title=\"Sports\",{$info['name']}\n";
        echo "http://$proxy_ip/index.php?stream=$id\n\n";
    }
    exit;
}

if (isset($_GET['epg'])) {
    $streams = file_exists($data_file) ? json_decode(file_get_contents($data_file), true) : [];
    header('Content-Type: application/xml; charset=utf-8');
    echo '<?xml version="1.0" encoding="UTF-8"?><tv>';
    foreach ($channels as $id => $info) {
        echo '<channel id="'.$id.'"><display-name>'.htmlspecialchars($info['name']).'</display-name></channel>';
    }
    foreach ($channels as $id => $info) {
        $item = isset($streams[$id]) && is_array($streams[$id]) ? $streams[$id] : ['event' => 'Live Sports', 'updated' => 'Never', 'ts' => time()];
        $title = htmlspecialchars($item['event'] . " (" . $item['updated'] . ")");

        // Use the stream's last-update timestamp as programme start.
        // This makes each update a unique programme entry so Jellyfin never
        // deduplicates it against a cached entry with the same start time.
        $ts    = isset($item['ts']) ? (int)$item['ts'] : time();
        $start = date('YmdHis O', $ts);
        $stop  = date('YmdHis O', $ts + 86400);

        echo '<programme start="'.$start.'" stop="'.$stop.'" channel="'.$id.'">';
        echo '<title>'.$title.'</title>';
        echo '<desc>Updated at '.$item['updated'].'</desc>';
        echo '</programme>';
    }
    echo '</tv>';
    exit;
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Zuzz Stream Manager</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: sans-serif; background: #1a1a1a; color: white; padding: 20px; text-align: center; }
        .card { background: #2a2a2a; padding: 20px; border-radius: 8px; max-width: 500px; margin: auto; }
        input, select, button { padding: 12px; margin: 10px 0; width: 100%; box-sizing: border-box; border-radius: 4px; background: #333; color: white; border: 1px solid #444; }
        button { background: #0078d4; border: none; font-weight: bold; cursor: pointer; }
        .refresh-btn { background: #28a745; }
        .status { margin-top: 20px; font-size: 0.9em; color: #aaa; text-align: left; }
        .alert { padding: 10px; background: #444; color: #0f0; margin-bottom: 10px; border: 1px solid #0f0; }
    </style>
</head>
<body>
    <div class="card">
        <?php if(isset($_GET['updated']) || isset($_GET['refreshed'])): ?><div class="alert">Success! Refreshing Jellyfin...</div><?php endif; ?>
        <h2>Update Zuzz Stream</h2>
        <form method="POST">
            <select name="channel"><?php foreach($channels as $id => $info): ?><option value="<?php echo $id; ?>"><?php echo $info['name']; ?></option><?php endforeach; ?></select>
            <input type="text" name="event" placeholder="Game Name">
            <input type="text" name="url" placeholder="Paste Link" required>
            <button type="submit">1. Update Link</button>
        </form>
        <button class="refresh-btn" onclick="location.href='index.php?refresh=1'">2. Force Jellyfin Refresh</button>
        <div class="status">
            <h3>Active Channels</h3>
            <?php
            $streams = file_exists($data_file) ? json_decode(file_get_contents($data_file), true) : [];
            foreach ($channels as $id => $info) {
                $item = isset($streams[$id]) && is_array($streams[$id]) ? $streams[$id] : ['event' => 'None', 'updated' => 'Never'];
                echo "<div><strong>{$info['name']}:</strong> {$item['event']} ({$item['updated']})</div>";
            }
            ?>
        </div>
    </div>
</body>
</html>
