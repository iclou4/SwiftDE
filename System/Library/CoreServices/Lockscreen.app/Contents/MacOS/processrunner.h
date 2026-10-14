#pragma once
#include <QObject>
#include <QString>
#include <QTimer>
#include <QJsonObject>

class ProcessRunner : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString activeAppName READ activeAppName NOTIFY activeAppChanged)
    Q_PROPERTY(QString activeAppTitle READ activeAppTitle NOTIFY activeAppChanged)
    Q_PROPERTY(QString activeAppId READ activeAppId NOTIFY activeAppChanged)
    Q_PROPERTY(int activeViewId READ activeViewId NOTIFY activeAppChanged)
    Q_PROPERTY(bool activeViewFullscreen READ activeViewFullscreen NOTIFY activeAppChanged)

    // Control Center properties
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)
    Q_PROPERTY(qreal brightness READ brightness WRITE setBrightness NOTIFY brightnessChanged)
    Q_PROPERTY(bool wifiEnabled READ wifiEnabled WRITE setWifiEnabled NOTIFY wifiEnabledChanged)
    Q_PROPERTY(QString wifiSsid READ wifiSsid NOTIFY wifiSsidChanged)
    Q_PROPERTY(bool bluetoothEnabled READ bluetoothEnabled WRITE setBluetoothEnabled NOTIFY bluetoothEnabledChanged)
    Q_PROPERTY(QString airdropState READ airdropState WRITE setAirdropState NOTIFY airdropStateChanged)
    Q_PROPERTY(bool focusEnabled READ focusEnabled WRITE setFocusEnabled NOTIFY focusEnabledChanged)
    Q_PROPERTY(bool stageManagerEnabled READ stageManagerEnabled WRITE setStageManagerEnabled NOTIFY stageManagerEnabledChanged)
    Q_PROPERTY(bool screenMirroringEnabled READ screenMirroringEnabled WRITE setScreenMirroringEnabled NOTIFY screenMirroringEnabledChanged)
    Q_PROPERTY(QString mediaTitle READ mediaTitle NOTIFY mediaChanged)
    Q_PROPERTY(QString mediaArtist READ mediaArtist NOTIFY mediaChanged)
    Q_PROPERTY(bool mediaPlaying READ mediaPlaying NOTIFY mediaChanged)
    Q_PROPERTY(QVariantList wifiNetworks READ wifiNetworks NOTIFY wifiNetworksChanged)

    // Wallpaper, Appearance & Dock Settings
    Q_PROPERTY(QString wallpaperUrl READ wallpaperUrl NOTIFY wallpaperUrlChanged)
    Q_PROPERTY(QString wallpaperName READ wallpaperName NOTIFY wallpaperNameChanged)
    Q_PROPERTY(QString wallpaperOptions READ wallpaperOptions NOTIFY wallpaperOptionsChanged)
    Q_PROPERTY(QString wallpaperColor READ wallpaperColor NOTIFY wallpaperColorChanged)
    Q_PROPERTY(QString colorScheme READ colorScheme WRITE setColorScheme NOTIFY colorSchemeChanged)
    Q_PROPERTY(QString accentColor READ accentColor WRITE setAccentColor NOTIFY accentColorChanged)
    Q_PROPERTY(QJsonObject dockSettings READ dockSettings NOTIFY dockSettingsChanged)
    Q_PROPERTY(QStringList runningApps READ runningApps NOTIFY runningAppsChanged)

public:
    explicit ProcessRunner(QObject *parent = nullptr);

    QString activeAppName() const { return m_activeAppName; }
    QString activeAppTitle() const { return m_activeAppTitle; }
    QString activeAppId() const { return m_activeAppId; }
    int activeViewId() const { return m_activeViewId; }
    bool activeViewFullscreen() const { return m_activeViewFullscreen; }

    qreal volume() const { return m_volume; }
    Q_INVOKABLE void setVolume(qreal v);
    bool muted() const { return m_muted; }
    Q_INVOKABLE void setMuted(bool m);
    qreal brightness() const { return m_brightness; }
    Q_INVOKABLE void setBrightness(qreal b);
    bool wifiEnabled() const { return m_wifiEnabled; }
    Q_INVOKABLE void setWifiEnabled(bool enabled);
    QString wifiSsid() const { return m_wifiSsid; }
    bool bluetoothEnabled() const { return m_bluetoothEnabled; }
    Q_INVOKABLE void setBluetoothEnabled(bool enabled);
    QString airdropState() const { return m_airdropState; }
    Q_INVOKABLE void setAirdropState(const QString &state);
    bool focusEnabled() const { return m_focusEnabled; }
    Q_INVOKABLE void setFocusEnabled(bool enabled);
    bool stageManagerEnabled() const { return m_stageManagerEnabled; }
    Q_INVOKABLE void setStageManagerEnabled(bool enabled);
    bool screenMirroringEnabled() const { return m_screenMirroringEnabled; }
    Q_INVOKABLE void setScreenMirroringEnabled(bool enabled);
    QString mediaTitle() const { return m_mediaTitle; }
    QString mediaArtist() const { return m_mediaArtist; }
    bool mediaPlaying() const { return m_mediaPlaying; }

    Q_INVOKABLE QString userName();
    Q_INVOKABLE int checkPassword(const QString &user, const QString &password);
    Q_INVOKABLE void launch(const QString &command);
    Q_INVOKABLE void launchAboutThisMac();
    Q_INVOKABLE void lockScreen();
    Q_INVOKABLE void logout();
    Q_INVOKABLE void restart();
    Q_INVOKABLE void shutdown();

    // Active window & input controls
    Q_INVOKABLE void closeActiveWindow();
    Q_INVOKABLE void forceQuitActiveWindow();
    Q_INVOKABLE void toggleFullscreen();
    Q_INVOKABLE void minimizeActiveWindow();
    Q_INVOKABLE void snapLeft();
    Q_INVOKABLE void snapRight();
    Q_INVOKABLE void sendKey(const QString &args);
    Q_INVOKABLE bool sendIpc(const QString &method, const QJsonObject &data = QJsonObject());
    Q_INVOKABLE void unfocusAll();

    // Control Center actions
    QVariantList wifiNetworks() const { return m_wifiNetworks; }
    Q_INVOKABLE void refreshWifiNetworks();
    Q_INVOKABLE void connectToNetwork(const QString &ssid);
    Q_INVOKABLE void toggleWifi();
    Q_INVOKABLE void toggleBluetooth();
    Q_INVOKABLE void cycleAirdrop();
    Q_INVOKABLE void toggleFocus();
    Q_INVOKABLE void toggleStageManager();
    Q_INVOKABLE void toggleScreenMirroring();
    Q_INVOKABLE void toggleMute();
    Q_INVOKABLE void mediaPlayPause();
    Q_INVOKABLE void mediaNext();

    // System specifications for About This Mac
    Q_INVOKABLE QString cpuModel();
    Q_INVOKABLE QString memoryTotal();
    Q_INVOKABLE QString serialNumber();
    Q_INVOKABLE QString startupDisk();

    // Desktop Context Menu IPC
    Q_INVOKABLE void showDesktopContextMenu(int x, int y);

    // Wallpaper & Settings
    QString wallpaperUrl() const { return m_wallpaperUrl; }
    QString wallpaperName() const { return m_wallpaperName; }
    QString wallpaperOptions() const { return m_wallpaperOptions; }
    QString wallpaperColor() const { return m_wallpaperColor; }
    QString colorScheme() const { return m_colorScheme; }
    Q_INVOKABLE void setColorScheme(const QString &scheme);
    QString accentColor() const { return m_accentColor; }
    Q_INVOKABLE void setAccentColor(const QString &color);

    QJsonObject dockSettings() const { return m_dockSettings; }
    Q_INVOKABLE void setDockSetting(const QString &key, const QVariant &value);

    Q_INVOKABLE void setWallpaper(const QString &url, const QString &name = QString());
    Q_INVOKABLE void refreshWallpaper();
    Q_INVOKABLE void openSystemSettings(const QString &tab = QStringLiteral("wallpaper"));

    QStringList runningApps() const { return m_runningApps; }
    Q_INVOKABLE bool isAppRunning(const QString &appId) const { return m_runningApps.contains(appId); }
    Q_INVOKABLE void toggleLaunchpad();
    Q_INVOKABLE QString loadLaunchpadLayout();
    Q_INVOKABLE void saveLaunchpadLayout(const QString &json);

signals:
    void activeAppChanged();
    void volumeChanged();
    void mutedChanged();
    void brightnessChanged();
    void wifiEnabledChanged();
    void wifiSsidChanged();
    void bluetoothEnabledChanged();
    void airdropStateChanged();
    void focusEnabledChanged();
    void stageManagerEnabledChanged();
    void screenMirroringEnabledChanged();
    void mediaChanged();
    void wifiNetworksChanged();
    void desktopContextMenuRequested(int x, int y);
    void wallpaperUrlChanged();
    void wallpaperNameChanged();
    void wallpaperOptionsChanged();
    void wallpaperColorChanged();
    void colorSchemeChanged();
    void accentColorChanged();
    void dockSettingsChanged();
    void runningAppsChanged();

private slots:
    void pollActiveApp();
    void pollControlCenter();
    void pollWallpaper();

private:
    QString m_activeAppName = QStringLiteral("Finder");
    QString m_activeAppTitle;
    QString m_activeAppId;
    int m_activeViewId = -1;
    bool m_activeViewFullscreen = false;
    QTimer *m_timer = nullptr;
    QTimer *m_ccTimer = nullptr;
    QTimer *m_wpTimer = nullptr;
    class QLocalServer *m_localServer = nullptr;

    // Wallpaper, Appearance & Dock state
    QString m_wallpaperUrl;
    QString m_wallpaperName = QStringLiteral("Sequoia Sunrise");
    QString m_wallpaperOptions = QStringLiteral("zoom");
    QString m_wallpaperColor = QStringLiteral("#000000");
    QString m_colorScheme = QStringLiteral("default");
    QString m_accentColor = QStringLiteral("#007aff");
    QJsonObject m_dockSettings;
    class QProcess *m_wallpaperMonitor = nullptr;
    void startWallpaperMonitor();
    void loadDockSettings();

    // Control Center state
    qreal m_volume = 0.5;
    bool m_muted = false;
    qreal m_brightness = 0.8;
    bool m_wifiEnabled = true;
    QString m_wifiSsid = QStringLiteral("Wi-Fi");
    QVariantList m_wifiNetworks;
    bool m_bluetoothEnabled = true;
    QString m_airdropState = QStringLiteral("Everyone");
    bool m_focusEnabled = false;
    bool m_stageManagerEnabled = false;
    bool m_screenMirroringEnabled = false;
    QString m_mediaTitle = QStringLiteral("Music");
    QString m_mediaArtist;
    bool m_mediaPlaying = false;

    void updateAppInfo(const QString &id, const QString &title, int viewId, bool fullscreen);

    QStringList m_runningApps;
    int m_listViewsCounter = 0;
};
