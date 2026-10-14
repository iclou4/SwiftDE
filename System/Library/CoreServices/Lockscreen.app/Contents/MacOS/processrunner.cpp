#include "processrunner.h"

#include <QProcess>
#include <QFile>
#include <QTextStream>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <pwd.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <fcntl.h>
#include <QDebug>
#include <QRegularExpression>
#include <QLocalServer>
#include <QLocalSocket>
#include <QCoreApplication>
#include <QUrl>
#include <QFileInfo>
#include <QDir>

QString ProcessRunner::homePath() const {
    return QDir::homePath();
}

QString ProcessRunner::swiftdePath() const {
    return getSwiftDEPath();
}

QString ProcessRunner::getSwiftDEPath(const QString &relPath) {
    QString envRoot = qEnvironmentVariable("SWIFTDE_ROOT");
    if (!envRoot.isEmpty() && QDir(envRoot).exists()) {
        return envRoot + relPath;
    }
    QString home = QDir::homePath();
    if (QDir(home + QStringLiteral("/SwiftDE")).exists()) {
        return home + QStringLiteral("/SwiftDE") + relPath;
    }
    return QStringLiteral("/usr/local/share/SwiftDE") + relPath;
}

ProcessRunner::ProcessRunner(QObject *parent) : QObject(parent) {
    // Ensure DBUS_SESSION_BUS_ADDRESS is present for gsettings/dconf
    if (qgetenv("DBUS_SESSION_BUS_ADDRESS").isEmpty()) {
        QString bus = QStringLiteral("/run/user/%1/bus").arg(getuid());
        if (QFile::exists(bus)) {
            qputenv("DBUS_SESSION_BUS_ADDRESS", ("unix:path=" + bus).toLocal8Bit());
        }
    }

    loadDockSettings();
    refreshWallpaper();
    startWallpaperMonitor();

    m_wpTimer = new QTimer(this);
    m_wpTimer->setInterval(2500);
    connect(m_wpTimer, &QTimer::timeout, this, &ProcessRunner::pollWallpaper);
    m_wpTimer->start();

    m_timer = new QTimer(this);
    m_timer->setInterval(80);
    connect(m_timer, &QTimer::timeout, this, &ProcessRunner::pollActiveApp);
    m_timer->start();
    pollActiveApp();

    m_ccTimer = new QTimer(this);
    m_ccTimer->setInterval(1500);
    connect(m_ccTimer, &QTimer::timeout, this, &ProcessRunner::pollControlCenter);
    m_ccTimer->start();
    pollControlCenter();
    refreshWifiNetworks();

    bool isTopbar = false;
    for (const QString &arg : QCoreApplication::arguments()) {
        if (arg == QStringLiteral("--topbar")) isTopbar = true;
    }
    if (isTopbar) {
        m_localServer = new QLocalServer(this);
        QString serverName = QStringLiteral("swiftde-contextmenu-%1").arg(getuid());
        QLocalServer::removeServer(serverName);
        if (m_localServer->listen(serverName)) {
            connect(m_localServer, &QLocalServer::newConnection, this, [this]() {
                while (m_localServer->hasPendingConnections()) {
                    QLocalSocket *client = m_localServer->nextPendingConnection();
                    connect(client, &QLocalSocket::readyRead, this, [this, client]() {
                        QByteArray line = client->readLine().trimmed();
                        if (!line.isEmpty()) {
                            QList<QByteArray> parts = line.split(' ');
                            if (parts.size() >= 2) {
                                int x = parts[0].toInt();
                                int y = parts[1].toInt();
                                emit desktopContextMenuRequested(x, y);
                            }
                        }
                        client->disconnectFromServer();
                    });
                }
            });
        }
    }
}

QString ProcessRunner::userName() {
    if (struct passwd *pw = getpwuid(getuid()))
        return QString::fromLocal8Bit(pw->pw_name);
    return QString();
}

int ProcessRunner::checkPassword(const QString &user, const QString &password) {
    QProcess proc;
    proc.start(QStringLiteral("/usr/local/bin/swiftde-checkpw"), {user});
    if (!proc.waitForStarted(3000))
        return 2;
    proc.write(password.toLocal8Bit() + '\n');
    proc.closeWriteChannel();
    if (!proc.waitForFinished(10000))
        return 2;
    return proc.exitCode();
}

void ProcessRunner::launch(const QString &command) {
    QString fullCmd = QStringLiteral("export XDG_CURRENT_DESKTOP=GNOME:Unity:SwiftDE; unset QT_WAYLAND_SHELL_INTEGRATION; ") + command;
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), fullCmd});
}

void ProcessRunner::launchAboutThisMac() {
    QProcess::execute(QStringLiteral("/usr/bin/pkill"), {QStringLiteral("-f"), QStringLiteral("AboutThisMac")});

    QProcess *proc = new QProcess(this);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.remove(QStringLiteral("QT_WAYLAND_SHELL_INTEGRATION"));
    env.insert(QStringLiteral("QT_WAYLAND_SHELL_INTEGRATION"), QStringLiteral("xdg-shell"));
    env.insert(QStringLiteral("LIBGL_ALWAYS_SOFTWARE"), QStringLiteral("1"));
    env.insert(QStringLiteral("QSG_RHI_BACKEND"), QStringLiteral("opengl"));
    env.insert(QStringLiteral("XDG_CURRENT_DESKTOP"), QStringLiteral("GNOME:Unity:SwiftDE"));
    proc->setProcessEnvironment(env);
    proc->startDetached(getSwiftDEPath(QStringLiteral("/SwiftDE-RunQML")), {getSwiftDEPath(QStringLiteral("/System/Library/CoreServices/AboutThisMac.app/Contents/Resources/AboutThisMac.qml"))});
}

void ProcessRunner::lockScreen() {
    QProcess::startDetached(QStringLiteral("/bin/sh"), {
        QStringLiteral("-c"),
        QString("exec env LIBGL_ALWAYS_SOFTWARE=1 QSG_RHI_BACKEND=opengl %1/SwiftDE-RunQML --layer %1/System/Library/CoreServices/Lockscreen.app/Contents/Resources/Lockscreen.qml").arg(getSwiftDEPath())
    });
}

void ProcessRunner::logout() {
    QProcess::startDetached(QStringLiteral("/bin/sh"), {
        QStringLiteral("-c"),
        QStringLiteral("sudo systemctl restart gdm3 || killall wayfire || pkill -u $USER wayfire || true")
    });
}

void ProcessRunner::restart() {
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), QStringLiteral("systemctl reboot || reboot || true")});
}

void ProcessRunner::shutdown() {
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), QStringLiteral("systemctl poweroff || poweroff || true")});
}

void ProcessRunner::showDesktopContextMenu(int x, int y) {
    QString serverName = QStringLiteral("swiftde-contextmenu-%1").arg(getuid());
    auto *socket = new QLocalSocket(this);
    connect(socket, &QLocalSocket::connected, this, [socket, x, y]() {
        socket->write(QStringLiteral("%1 %2\n").arg(x).arg(y).toUtf8());
        socket->flush();
    });
    connect(socket, &QLocalSocket::bytesWritten, socket, &QObject::deleteLater);
    connect(socket, &QLocalSocket::errorOccurred, socket, &QObject::deleteLater);
    socket->connectToServer(serverName);
}

void ProcessRunner::forceQuitActiveWindow() {
    if (m_activeViewId > 0) {
        QJsonObject d;
        d["id"] = m_activeViewId;
        sendIpc(QStringLiteral("window-rules/close-view"), d);
    }
    sendKey(QStringLiteral("-M super q -m super"));
}

bool ProcessRunner::sendIpc(const QString &method, const QJsonObject &data) {
    QString sockPath = qgetenv("WAYFIRE_SOCKET");
    if (sockPath.isEmpty()) {
        QString runtimeDir = qgetenv("XDG_RUNTIME_DIR");
        QString waylandDisplay = qgetenv("WAYLAND_DISPLAY");
        if (runtimeDir.isEmpty()) runtimeDir = QStringLiteral("/run/user/1000");
        if (waylandDisplay.isEmpty()) waylandDisplay = QStringLiteral("wayland-1");
        sockPath = QStringLiteral("%1/wayfire-%2-.socket").arg(runtimeDir, waylandDisplay);
    }

    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return false;

    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 150000;
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, sockPath.toUtf8().constData(), sizeof(addr.sun_path) - 1);

    if (::connect(fd, (struct sockaddr*)&addr, sizeof(addr)) != 0) {
        ::close(fd);
        return false;
    }

    QJsonObject reqObj;
    reqObj["method"] = method;
    if (!data.isEmpty()) {
        reqObj["data"] = data;
    }

    QByteArray req = QJsonDocument(reqObj).toJson(QJsonDocument::Compact);
    uint32_t len = req.size();
    if (::write(fd, &len, 4) != 4 || ::write(fd, req.constData(), len) != (int)len) {
        ::close(fd);
        return false;
    }

    ::close(fd);
    return true;
}

void ProcessRunner::unfocusAll() {
    QJsonObject d;
    d["id"] = 0;
    sendIpc(QStringLiteral("window-rules/focus-view"), d);
    updateAppInfo(QStringLiteral(""), QStringLiteral(""), -1, false);
}

void ProcessRunner::closeActiveWindow() {
    if (m_activeViewId > 0) {
        QJsonObject d;
        d["id"] = m_activeViewId;
        sendIpc(QStringLiteral("window-rules/close-view"), d);
    } else {
        sendKey(QStringLiteral("-M ctrl w -m ctrl"));
    }
}

void ProcessRunner::toggleFullscreen() {
    if (m_activeViewId > 0) {
        QJsonObject d;
        d["view_id"] = m_activeViewId;
        d["state"] = !m_activeViewFullscreen;
        sendIpc(QStringLiteral("wm-actions/set-fullscreen"), d);
    } else {
        sendKey(QStringLiteral("-k F11"));
    }
}

void ProcessRunner::minimizeActiveWindow() {
    if (m_activeViewId > 0) {
        QJsonObject d;
        d["view_id"] = m_activeViewId;
        d["state"] = true;
        sendIpc(QStringLiteral("wm-actions/set-minimized"), d);
    }
}

void ProcessRunner::snapLeft() {
    if (m_activeViewId > 0) {
        QJsonObject d;
        d["view_id"] = m_activeViewId;
        sendIpc(QStringLiteral("grid/slot_l"), d);
    }
}

void ProcessRunner::snapRight() {
    if (m_activeViewId > 0) {
        QJsonObject d;
        d["view_id"] = m_activeViewId;
        sendIpc(QStringLiteral("grid/slot_r"), d);
    }
}

void ProcessRunner::sendKey(const QString &args) {
    QStringList parts = args.split(QLatin1Char(' '), Qt::SkipEmptyParts);
    QProcess::startDetached(QStringLiteral("/usr/bin/wtype"), parts);
}

void ProcessRunner::pollActiveApp() {
    QString sockPath = qgetenv("WAYFIRE_SOCKET");
    if (sockPath.isEmpty()) {
        QString runtimeDir = qgetenv("XDG_RUNTIME_DIR");
        QString waylandDisplay = qgetenv("WAYLAND_DISPLAY");
        if (runtimeDir.isEmpty()) runtimeDir = QStringLiteral("/run/user/1000");
        if (waylandDisplay.isEmpty()) waylandDisplay = QStringLiteral("wayland-1");
        sockPath = QStringLiteral("%1/wayfire-%2-.socket").arg(runtimeDir, waylandDisplay);
    }

    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return;

    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 100000;
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, sockPath.toUtf8().constData(), sizeof(addr.sun_path) - 1);

    if (::connect(fd, (struct sockaddr*)&addr, sizeof(addr)) != 0) {
        ::close(fd);
        return;
    }

    QByteArray req = "{\"method\":\"window-rules/get-focused-view\"}";
    uint32_t len = req.size();
    if (::write(fd, &len, 4) != 4 || ::write(fd, req.constData(), len) != len) {
        ::close(fd);
        return;
    }

    uint32_t respLen = 0;
    if (::read(fd, &respLen, 4) != 4 || respLen > 65536) {
        ::close(fd);
        return;
    }

    QByteArray buf(respLen, 0);
    int totalRead = 0;
    while (totalRead < (int)respLen) {
        int r = ::read(fd, buf.data() + totalRead, respLen - totalRead);
        if (r <= 0) break;
        totalRead += r;
    }
    // Check list of all open windows every ~240ms
    if (++m_listViewsCounter % 3 == 0) {
        QByteArray reqList = "{\"method\":\"window-rules/list-views\"}";
        uint32_t lenList = reqList.size();
        if (::write(fd, &lenList, 4) == 4 && ::write(fd, reqList.constData(), lenList) == lenList) {
            uint32_t respLenList = 0;
            if (::read(fd, &respLenList, 4) == 4 && respLenList <= 262144) {
                QByteArray bufList(respLenList, 0);
                int readList = 0;
                while (readList < (int)respLenList) {
                    int r = ::read(fd, bufList.data() + readList, respLenList - readList);
                    if (r <= 0) break;
                    readList += r;
                }
                if (readList == (int)respLenList) {
                    QJsonDocument docList = QJsonDocument::fromJson(bufList);
                    if (docList.isArray()) {
                        QStringList running;
                        for (const QJsonValue &v : docList.array()) {
                            if (!v.isObject()) continue;
                            QJsonObject obj = v.toObject();
                            QString role = obj["role"].toString();
                            QString type = obj["type"].toString();
                            if (role != QStringLiteral("toplevel") && type != QStringLiteral("toplevel"))
                                continue;
                            if (!obj["mapped"].toBool(false))
                                continue;
                            QString aId = obj["app-id"].toString().toLower();
                            QString aTitle = obj["title"].toString().toLower();

                            if (aId.contains(QStringLiteral("settings")) || aId.contains(QStringLiteral("control-center")) || aTitle.contains(QStringLiteral("settings"))) {
                                running << QStringLiteral("settings");
                            } else if (aId.contains(QStringLiteral("chrome")) || aId.contains(QStringLiteral("firefox")) || aId.contains(QStringLiteral("safari")) || aId.contains(QStringLiteral("chromium"))) {
                                running << QStringLiteral("safari");
                            } else if (aId.contains(QStringLiteral("telegram")) || aId.contains(QStringLiteral("messages"))) {
                                running << QStringLiteral("messages");
                            } else if (aId.contains(QStringLiteral("thunderbird")) || aId.contains(QStringLiteral("mail")) || aId.contains(QStringLiteral("geary"))) {
                                running << QStringLiteral("mail");
                            } else if (aId.contains(QStringLiteral("maps"))) {
                                running << QStringLiteral("maps");
                            } else if (aId.contains(QStringLiteral("loupe")) || aId.contains(QStringLiteral("eog")) || aId.contains(QStringLiteral("gthumb")) || aId.contains(QStringLiteral("photos"))) {
                                running << QStringLiteral("photos");
                            } else if (aId.contains(QStringLiteral("cheese")) || aId.contains(QStringLiteral("facetime"))) {
                                running << QStringLiteral("facetime");
                            } else if (aId.contains(QStringLiteral("calendar"))) {
                                running << QStringLiteral("calendar");
                            } else if (aId.contains(QStringLiteral("contacts"))) {
                                running << QStringLiteral("contacts");
                            } else if (aId.contains(QStringLiteral("todo")) || aId.contains(QStringLiteral("reminders"))) {
                                running << QStringLiteral("reminders");
                            } else if (aId.contains(QStringLiteral("text-editor")) || aId.contains(QStringLiteral("gedit")) || aId.contains(QStringLiteral("notes"))) {
                                running << QStringLiteral("notes");
                            } else if (aId.contains(QStringLiteral("draw")) || aId.contains(QStringLiteral("libreoffice")) || aId.contains(QStringLiteral("freeform"))) {
                                running << QStringLiteral("freeform");
                            } else if (aId.contains(QStringLiteral("totem")) || aId.contains(QStringLiteral("vlc")) || aId.contains(QStringLiteral("tv"))) {
                                running << QStringLiteral("tv");
                            } else if (aId.contains(QStringLiteral("rhythmbox")) || aId.contains(QStringLiteral("music")) || aId.contains(QStringLiteral("spotify"))) {
                                running << QStringLiteral("music");
                            } else if (aId.contains(QStringLiteral("liferea")) || aId.contains(QStringLiteral("news"))) {
                                running << QStringLiteral("news");
                            } else if (aId.contains(QStringLiteral("software")) || aId.contains(QStringLiteral("snap-store")) || aId.contains(QStringLiteral("appstore"))) {
                                running << QStringLiteral("appstore");
                            } else if (aId.contains(QStringLiteral("terminal")) || aId.contains(QStringLiteral("foot")) || aId.contains(QStringLiteral("ptyxis"))) {
                                running << QStringLiteral("terminal");
                            } else if (aId.contains(QStringLiteral("nautilus")) || aId.contains(QStringLiteral("finder")) || aId.contains(QStringLiteral("files"))) {
                                running << QStringLiteral("finder");
                            }
                        }
                        running.removeDuplicates();
                        if (m_runningApps != running) {
                            m_runningApps = running;
                            emit runningAppsChanged();
                        }
                    }
                }
            }
        }
    }

    ::close(fd);

    if (totalRead != (int)respLen) return;

    QJsonDocument doc = QJsonDocument::fromJson(buf);
    if (!doc.isObject()) return;

    QJsonObject root = doc.object();
    if (!root.contains("info") || root["info"].isNull()) {
        updateAppInfo(QStringLiteral(""), QStringLiteral(""), -1, false);
        return;
    }

    QJsonObject info = root["info"].toObject();
    QString appId = info["app-id"].toString();
    QString title = info["title"].toString();
    int viewId = info["id"].toInt(-1);
    bool fs = info["fullscreen"].toBool(false);
    updateAppInfo(appId, title, viewId, fs);
}

void ProcessRunner::updateAppInfo(const QString &id, const QString &title, int viewId, bool fullscreen) {
    QString name = QStringLiteral("Finder");
    if (!id.isEmpty() && id != QStringLiteral("nil")) {
        QString lower = id.toLower();
        if (title.contains(QStringLiteral("About"), Qt::CaseInsensitive) ||
            lower.contains(QStringLiteral("about")) ||
            lower.contains(QStringLiteral("swiftde")) ||
            lower.contains(QStringLiteral("finder")) ||
            lower == QStringLiteral("window")) {
            name = QStringLiteral("Finder");
        } else if (lower.contains(QStringLiteral("terminal")) || lower == QStringLiteral("foot") || lower.contains(QStringLiteral("ptyxis"))) {
            name = QStringLiteral("Terminal");
        } else if (lower.contains(QStringLiteral("nautilus")) || lower.contains(QStringLiteral("files"))) {
            name = QStringLiteral("Finder");
        } else if (lower.contains(QStringLiteral("textedit")) || lower.contains(QStringLiteral("gedit")) || lower.contains(QStringLiteral("text-editor"))) {
            name = QStringLiteral("TextEdit");
        } else if (lower.contains(QStringLiteral("firefox")) || lower.contains(QStringLiteral("chrome")) || lower.contains(QStringLiteral("browser"))) {
            name = QStringLiteral("Safari");
        } else if (lower.contains(QStringLiteral("calc"))) {
            name = QStringLiteral("Calculator");
        } else if (lower.contains(QStringLiteral("settings")) || lower.contains(QStringLiteral("control-center"))) {
            name = QStringLiteral("System Settings");
        } else {
            QString base = id;
            int lastDot = base.lastIndexOf('.');
            if (lastDot >= 0) base = base.mid(lastDot + 1);
            if (!base.isEmpty() && base.toLower() != QStringLiteral("window")) {
                base[0] = base[0].toUpper();
                name = base;
            } else {
                name = QStringLiteral("Finder");
            }
        }
    }

    if (m_activeAppName != name || m_activeAppTitle != title || m_activeAppId != id || m_activeViewId != viewId || m_activeViewFullscreen != fullscreen) {
        m_activeAppName = name;
        m_activeAppTitle = title;
        m_activeAppId = id;
        m_activeViewId = viewId;
        m_activeViewFullscreen = fullscreen;
        emit activeAppChanged();
    }
}

QString ProcessRunner::cpuModel() {
    FILE *f = ::fopen("/proc/cpuinfo", "r");
    if (f) {
        char buf[512];
        while (::fgets(buf, sizeof(buf), f)) {
            char *p = ::strstr(buf, "model name");
            if (p) {
                char *colon = ::strchr(p, ':');
                if (colon) {
                    QString model = QString::fromUtf8(colon + 1).trimmed();
                    ::fclose(f);
                    return model;
                }
            }
        }
        ::fclose(f);
    }
    return QStringLiteral("Apple M1");
}

QString ProcessRunner::memoryTotal() {
    FILE *f = ::fopen("/proc/meminfo", "r");
    if (f) {
        char buf[512];
        while (::fgets(buf, sizeof(buf), f)) {
            if (::strncmp(buf, "MemTotal:", 9) == 0) {
                long long kb = 0;
                if (::sscanf(buf + 9, "%lld", &kb) == 1) {
                    ::fclose(f);
                    int gb = qRound((kb + 500000) / (1024.0 * 1024.0));
                    if (gb < 1) gb = 1;
                    return QStringLiteral("%1 GB").arg(gb);
                }
            }
        }
        ::fclose(f);
    }
    return QStringLiteral("8 GB");
}

QString ProcessRunner::serialNumber() {
    QFile f(QStringLiteral("/etc/machine-id"));
    if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString mid = QString::fromUtf8(f.readAll()).trimmed().toUpper();
        if (mid.length() >= 9) {
            return QStringLiteral("C02%1").arg(mid.left(9));
        }
    }
    return QStringLiteral("C02DX0JEQ6LR");
}

QString ProcessRunner::startupDisk() {
    FILE *f = ::fopen("/sys/block/sda/device/model", "r");
    if (f) {
        char buf[128];
        if (::fgets(buf, sizeof(buf), f)) {
            QString model = QString::fromUtf8(buf).trimmed();
            ::fclose(f);
            if (!model.isEmpty()) {
                return model;
            }
        }
        ::fclose(f);
    }
    return QStringLiteral("VBOX HARDDISK");
}

void ProcessRunner::setVolume(qreal v) {
    if (v < 0.0) v = 0.0;
    if (v > 1.0) v = 1.0;
    m_volume = v;
    emit volumeChanged();
    QString cmd = QStringLiteral("export XDG_RUNTIME_DIR=/run/user/1000; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus; wpctl set-volume @DEFAULT_AUDIO_SINK@ %1").arg(v, 0, 'f', 2);
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), cmd});
}

void ProcessRunner::setMuted(bool m) {
    m_muted = m;
    emit mutedChanged();
    QString cmd = QStringLiteral("export XDG_RUNTIME_DIR=/run/user/1000; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus; wpctl set-mute @DEFAULT_AUDIO_SINK@ %1").arg(m ? 1 : 0);
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), cmd});
}

void ProcessRunner::toggleMute() {
    setMuted(!m_muted);
}

void ProcessRunner::setBrightness(qreal b) {
    if (b < 0.05) b = 0.05;
    if (b > 1.0) b = 1.0;
    m_brightness = b;
    emit brightnessChanged();
    int pct = qRound(b * 100.0);
    QString cmd = QStringLiteral("brightnessctl set %1% || true").arg(pct);
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), cmd});
}

void ProcessRunner::setWifiEnabled(bool enabled) {
    m_wifiEnabled = enabled;
    emit wifiEnabledChanged();
    QString cmd = QStringLiteral("nmcli radio wifi %1").arg(enabled ? QStringLiteral("on") : QStringLiteral("off"));
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), cmd});
}

void ProcessRunner::toggleWifi() {
    setWifiEnabled(!m_wifiEnabled);
}

void ProcessRunner::refreshWifiNetworks() {
    QVariantList list;
    QProcess proc;
    proc.start(QStringLiteral("/usr/bin/nmcli"), {QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("active,ssid,signal,security"), QStringLiteral("dev"), QStringLiteral("wifi")});
    if (proc.waitForFinished(1000)) {
        QString out = QString::fromUtf8(proc.readAllStandardOutput());
        const QStringList lines = out.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        QSet<QString> seenSsids;
        for (const QString &line : lines) {
            QStringList parts = line.split(QLatin1Char(':'));
            if (parts.size() >= 3) {
                bool active = (parts[0] == QStringLiteral("yes"));
                QString ssid = parts[1].trimmed();
                if (ssid.isEmpty() || seenSsids.contains(ssid)) continue;
                seenSsids.insert(ssid);
                int sig = parts[2].toInt();
                int bars = 3;
                if (sig < 40) bars = 1;
                else if (sig < 70) bars = 2;
                QString sec = parts.size() >= 4 ? parts[3] : QString();
                bool secured = !sec.isEmpty() && sec != QStringLiteral("--");
                QVariantMap item;
                item[QStringLiteral("ssid")] = ssid;
                item[QStringLiteral("active")] = active;
                item[QStringLiteral("bars")] = bars;
                item[QStringLiteral("secured")] = secured;
                if (active) {
                    m_wifiSsid = ssid;
                    emit wifiSsidChanged();
                }
                list.append(item);
            }
        }
    }

    if (list.isEmpty()) {
        QString activeSsid = m_wifiSsid;
        if (activeSsid.isEmpty() || activeSsid == QStringLiteral("Wi-Fi")) {
            activeSsid = QStringLiteral("SwiftOS-5G");
            m_wifiSsid = activeSsid;
            emit wifiSsidChanged();
        }
        QVariantMap n1;
        n1[QStringLiteral("ssid")] = activeSsid;
        n1[QStringLiteral("active")] = true;
        n1[QStringLiteral("bars")] = 3;
        n1[QStringLiteral("secured")] = true;
        list.append(n1);

        QVariantMap n2;
        n2[QStringLiteral("ssid")] = QStringLiteral("Home-Network-Ext");
        n2[QStringLiteral("active")] = false;
        n2[QStringLiteral("bars")] = 3;
        n2[QStringLiteral("secured")] = true;
        list.append(n2);

        QVariantMap n3;
        n3[QStringLiteral("ssid")] = QStringLiteral("Airport_Extreme_5GHz");
        n3[QStringLiteral("active")] = false;
        n3[QStringLiteral("bars")] = 2;
        n3[QStringLiteral("secured")] = true;
        list.append(n3);

        QVariantMap n4;
        n4[QStringLiteral("ssid")] = QStringLiteral("Public_Guest_WiFi");
        n4[QStringLiteral("active")] = false;
        n4[QStringLiteral("bars")] = 1;
        n4[QStringLiteral("secured")] = false;
        list.append(n4);
    }

    m_wifiNetworks = list;
    emit wifiNetworksChanged();
}

void ProcessRunner::connectToNetwork(const QString &ssid) {
    if (ssid.isEmpty()) return;
    QString cmd = QStringLiteral("nmcli dev wifi connect \"%1\" || true").arg(ssid);
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), cmd});

    m_wifiSsid = ssid;
    emit wifiSsidChanged();

    for (int i = 0; i < m_wifiNetworks.size(); ++i) {
        QVariantMap item = m_wifiNetworks[i].toMap();
        item[QStringLiteral("active")] = (item[QStringLiteral("ssid")].toString() == ssid);
        m_wifiNetworks[i] = item;
    }
    emit wifiNetworksChanged();
}

void ProcessRunner::setBluetoothEnabled(bool enabled) {
    m_bluetoothEnabled = enabled;
    emit bluetoothEnabledChanged();
    QString cmd = QStringLiteral("bluetoothctl power %1 || rfkill %2 bluetooth || true")
        .arg(enabled ? QStringLiteral("on") : QStringLiteral("off"),
             enabled ? QStringLiteral("unblock") : QStringLiteral("block"));
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), cmd});
}

void ProcessRunner::toggleBluetooth() {
    setBluetoothEnabled(!m_bluetoothEnabled);
}

void ProcessRunner::setAirdropState(const QString &state) {
    m_airdropState = state;
    emit airdropStateChanged();
}

void ProcessRunner::cycleAirdrop() {
    if (m_airdropState == QStringLiteral("Everyone"))
        setAirdropState(QStringLiteral("Contacts Only"));
    else if (m_airdropState == QStringLiteral("Contacts Only"))
        setAirdropState(QStringLiteral("Off"));
    else
        setAirdropState(QStringLiteral("Everyone"));
}

void ProcessRunner::setFocusEnabled(bool enabled) {
    m_focusEnabled = enabled;
    emit focusEnabledChanged();
    if (enabled) {
        QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), QStringLiteral("notify-send -t 1500 'Focus' 'Do Not Disturb Enabled' || true")});
    }
}

void ProcessRunner::toggleFocus() {
    setFocusEnabled(!m_focusEnabled);
}

void ProcessRunner::setStageManagerEnabled(bool enabled) {
    m_stageManagerEnabled = enabled;
    emit stageManagerEnabledChanged();
}

void ProcessRunner::toggleStageManager() {
    setStageManagerEnabled(!m_stageManagerEnabled);
}

void ProcessRunner::setScreenMirroringEnabled(bool enabled) {
    m_screenMirroringEnabled = enabled;
    emit screenMirroringEnabledChanged();
}

void ProcessRunner::toggleScreenMirroring() {
    setScreenMirroringEnabled(!m_screenMirroringEnabled);
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), QStringLiteral("gnome-control-center display || true")});
}

void ProcessRunner::mediaPlayPause() {
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), QStringLiteral("playerctl play-pause || true")});
    m_mediaPlaying = !m_mediaPlaying;
    emit mediaChanged();
}

void ProcessRunner::mediaNext() {
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), QStringLiteral("playerctl next || true")});
}

void ProcessRunner::pollControlCenter() {
    // 1. Audio query
    QProcess procAudio;
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("XDG_RUNTIME_DIR"), QStringLiteral("/run/user/1000"));
    env.insert(QStringLiteral("DBUS_SESSION_BUS_ADDRESS"), QStringLiteral("unix:path=/run/user/1000/bus"));
    procAudio.setProcessEnvironment(env);
    procAudio.start(QStringLiteral("/usr/bin/wpctl"), {QStringLiteral("get-volume"), QStringLiteral("@DEFAULT_AUDIO_SINK@")});
    if (procAudio.waitForFinished(300)) {
        QString out = QString::fromUtf8(procAudio.readAllStandardOutput());
        int idx = out.indexOf(QStringLiteral("Volume:"));
        if (idx >= 0) {
            QString sub = out.mid(idx + 7).trimmed();
            QStringList tokens = sub.split(QRegularExpression(QStringLiteral("\\s+")), Qt::SkipEmptyParts);
            if (!tokens.isEmpty()) {
                bool ok = false;
                qreal v = tokens[0].toDouble(&ok);
                if (ok && qAbs(v - m_volume) > 0.01) {
                    m_volume = v;
                    emit volumeChanged();
                }
            }
            bool isMuted = out.contains(QStringLiteral("[MUTED]"));
            if (isMuted != m_muted) {
                m_muted = isMuted;
                emit mutedChanged();
            }
        }
    }

    // 2. Wi-Fi status query
    QProcess procWifi;
    procWifi.start(QStringLiteral("/usr/bin/nmcli"), {QStringLiteral("radio"), QStringLiteral("wifi")});
    if (procWifi.waitForFinished(300)) {
        QString out = QString::fromUtf8(procWifi.readAllStandardOutput()).trimmed();
        bool en = (out == QStringLiteral("enabled"));
        if (en != m_wifiEnabled) {
            m_wifiEnabled = en;
            emit wifiEnabledChanged();
        }
    }

    // Active Wi-Fi SSID
    QProcess procSsid;
    procSsid.start(QStringLiteral("/usr/bin/nmcli"), {QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("active,ssid"), QStringLiteral("dev"), QStringLiteral("wifi")});
    if (procSsid.waitForFinished(300)) {
        QString out = QString::fromUtf8(procSsid.readAllStandardOutput());
        QString currentSsid = QStringLiteral("Wi-Fi");
        const QStringList lines = out.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            if (line.startsWith(QStringLiteral("yes:"))) {
                currentSsid = line.mid(4).trimmed();
                break;
            }
        }
        if (currentSsid.isEmpty()) currentSsid = QStringLiteral("Wi-Fi");
        if (currentSsid != m_wifiSsid) {
            m_wifiSsid = currentSsid;
            emit wifiSsidChanged();
        }
    }

    // 3. Media Player status query
    QProcess procPlayer;
    procPlayer.setProcessEnvironment(env);
    procPlayer.start(QStringLiteral("/usr/bin/playerctl"), {QStringLiteral("status")});
    if (procPlayer.waitForFinished(200)) {
        QString status = QString::fromUtf8(procPlayer.readAllStandardOutput()).trimmed();
        bool playing = (status.compare(QStringLiteral("Playing"), Qt::CaseInsensitive) == 0);
        if (playing != m_mediaPlaying) {
            m_mediaPlaying = playing;
            emit mediaChanged();
        }
    }

    QProcess procTitle;
    procTitle.setProcessEnvironment(env);
    procTitle.start(QStringLiteral("/usr/bin/playerctl"), {QStringLiteral("metadata"), QStringLiteral("title")});
    if (procTitle.waitForFinished(200)) {
        QString title = QString::fromUtf8(procTitle.readAllStandardOutput()).trimmed();
        if (!title.isEmpty() && title != m_mediaTitle) {
            m_mediaTitle = title;
            emit mediaChanged();
        }
    }
}

void ProcessRunner::loadDockSettings() {
    QString configPath = QDir::homePath() + QStringLiteral("/.config/swiftde/dock.json");
    QFile f(configPath);
    if (f.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
        if (doc.isObject()) {
            m_dockSettings = doc.object();
            emit dockSettingsChanged();
            return;
        }
    }
    // Default dock settings
    m_dockSettings[QStringLiteral("size")] = 60;
    m_dockSettings[QStringLiteral("magnification")] = true;
    m_dockSettings[QStringLiteral("maxSize")] = 92;
    m_dockSettings[QStringLiteral("position")] = QStringLiteral("bottom");
    m_dockSettings[QStringLiteral("autohide")] = false;
    m_dockSettings[QStringLiteral("genie")] = true;
    emit dockSettingsChanged();
}

void ProcessRunner::setDockSetting(const QString &key, const QVariant &value) {
    m_dockSettings[key] = QJsonValue::fromVariant(value);
    emit dockSettingsChanged();

    QString dirPath = QDir::homePath() + QStringLiteral("/.config/swiftde");
    QDir().mkpath(dirPath);
    QFile f(dirPath + QStringLiteral("/dock.json"));
    if (f.open(QIODevice::WriteOnly)) {
        f.write(QJsonDocument(m_dockSettings).toJson());
        f.close();
    }
}

void ProcessRunner::refreshWallpaper() {
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    if (env.value(QStringLiteral("DBUS_SESSION_BUS_ADDRESS")).isEmpty()) {
        QString bus = QStringLiteral("/run/user/%1/bus").arg(getuid());
        if (QFile::exists(bus)) {
            env.insert(QStringLiteral("DBUS_SESSION_BUS_ADDRESS"), QStringLiteral("unix:path=") + bus);
        }
    }

    // Check color scheme from GNOME interface settings
    bool schemeChanged = false;
    QProcess procScheme;
    procScheme.setProcessEnvironment(env);
    procScheme.start(QStringLiteral("gsettings"), {QStringLiteral("get"), QStringLiteral("org.gnome.desktop.interface"), QStringLiteral("color-scheme")});
    if (procScheme.waitForFinished(300)) {
        QString scheme = QString::fromUtf8(procScheme.readAllStandardOutput()).trimmed();
        scheme.remove('\'');
        if (!scheme.isEmpty() && scheme != m_colorScheme) {
            m_colorScheme = scheme;
            schemeChanged = true;
        }
    }

    // Also check GTK theme for dark mode indicator
    bool dark = (m_colorScheme == QStringLiteral("prefer-dark") || m_colorScheme == QStringLiteral("dark"));
    if (!dark) {
        QProcess procGtk;
        procGtk.setProcessEnvironment(env);
        procGtk.start(QStringLiteral("gsettings"), {QStringLiteral("get"), QStringLiteral("org.gnome.desktop.interface"), QStringLiteral("gtk-theme")});
        if (procGtk.waitForFinished(300)) {
            QString gtkTheme = QString::fromUtf8(procGtk.readAllStandardOutput()).trimmed();
            if (gtkTheme.contains(QStringLiteral("dark"), Qt::CaseInsensitive)) {
                dark = true;
            }
        }
    }
    if (m_isDark != dark) {
        m_isDark = dark;
        schemeChanged = true;
    }
    if (schemeChanged) {
        emit colorSchemeChanged();
    }

    // Check wallpaper URI
    QString primaryKey = m_isDark ? QStringLiteral("picture-uri-dark") : QStringLiteral("picture-uri");
    QString fallbackKey = m_isDark ? QStringLiteral("picture-uri") : QStringLiteral("picture-uri-dark");

    QProcess procUri;
    procUri.setProcessEnvironment(env);
    procUri.start(QStringLiteral("gsettings"), {QStringLiteral("get"), QStringLiteral("org.gnome.desktop.background"), primaryKey});
    QString uri;
    if (procUri.waitForFinished(300)) {
        uri = QString::fromUtf8(procUri.readAllStandardOutput()).trimmed();
        uri.remove('\'');
    }

    if (uri.isEmpty() || uri == QStringLiteral("none")) {
        QProcess procFallback;
        procFallback.setProcessEnvironment(env);
        procFallback.start(QStringLiteral("gsettings"), {QStringLiteral("get"), QStringLiteral("org.gnome.desktop.background"), fallbackKey});
        if (procFallback.waitForFinished(300)) {
            uri = QString::fromUtf8(procFallback.readAllStandardOutput()).trimmed();
            uri.remove('\'');
        }
    }

    if (uri.isEmpty() || uri == QStringLiteral("none")) {
        uri = QStringLiteral("file://") + getSwiftDEPath(QStringLiteral("/Library/DesktopPictures/Wallpaper.jpg"));
    } else if (!uri.startsWith(QStringLiteral("file://")) && uri.startsWith(QStringLiteral("/"))) {
        uri = QStringLiteral("file://") + uri;
    }

    if (uri != m_wallpaperUrl) {
        m_wallpaperUrl = uri;
        QString localPath = QUrl(uri).toLocalFile();
        QString fileName = QFileInfo(localPath).baseName();
        if (fileName.contains(QStringLiteral("Sequoia"), Qt::CaseInsensitive)) m_wallpaperName = QStringLiteral("Sequoia Sunrise");
        else if (fileName.contains(QStringLiteral("Sonoma"), Qt::CaseInsensitive)) m_wallpaperName = QStringLiteral("Sonoma Horizon");
        else if (fileName.contains(QStringLiteral("Bluebells"), Qt::CaseInsensitive)) m_wallpaperName = QStringLiteral("Bluebells Suspended In Time");
        else if (fileName.contains(QStringLiteral("Acer"), Qt::CaseInsensitive)) m_wallpaperName = QStringLiteral("Red Acer");
        else if (fileName.contains(QStringLiteral("Winter"), Qt::CaseInsensitive)) m_wallpaperName = QStringLiteral("Winter Grand Triangle");
        else if (fileName.contains(QStringLiteral("Big_Dipper"), Qt::CaseInsensitive)) m_wallpaperName = QStringLiteral("Big Dipper");
        else if (!fileName.isEmpty()) m_wallpaperName = fileName;

        emit wallpaperUrlChanged();
        emit wallpaperNameChanged();
    }
}

void ProcessRunner::pollWallpaper() {
    refreshWallpaper();
}

void ProcessRunner::startWallpaperMonitor() {
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    if (env.value(QStringLiteral("DBUS_SESSION_BUS_ADDRESS")).isEmpty()) {
        QString bus = QStringLiteral("/run/user/%1/bus").arg(getuid());
        if (QFile::exists(bus)) {
            env.insert(QStringLiteral("DBUS_SESSION_BUS_ADDRESS"), QStringLiteral("unix:path=") + bus);
        }
    }

    // Monitor wallpaper changes
    if (!m_wallpaperMonitor) {
        m_wallpaperMonitor = new QProcess(this);
        m_wallpaperMonitor->setProcessEnvironment(env);
        connect(m_wallpaperMonitor, &QProcess::readyReadStandardOutput, this, [this]() {
            refreshWallpaper();
        });
        connect(m_wallpaperMonitor, &QProcess::finished, this, [this]() {
            m_wallpaperMonitor = nullptr;
            QTimer::singleShot(2000, this, &ProcessRunner::startWallpaperMonitor);
        });
        m_wallpaperMonitor->start(QStringLiteral("gsettings"), {QStringLiteral("monitor"), QStringLiteral("org.gnome.desktop.background")});
    }

    // Monitor interface changes (dark/light mode, gtk-theme)
    if (!m_interfaceMonitor) {
        m_interfaceMonitor = new QProcess(this);
        m_interfaceMonitor->setProcessEnvironment(env);
        connect(m_interfaceMonitor, &QProcess::readyReadStandardOutput, this, [this]() {
            refreshWallpaper();
        });
        connect(m_interfaceMonitor, &QProcess::finished, this, [this]() {
            m_interfaceMonitor = nullptr;
            QTimer::singleShot(2000, this, &ProcessRunner::startWallpaperMonitor);
        });
        m_interfaceMonitor->start(QStringLiteral("gsettings"), {QStringLiteral("monitor"), QStringLiteral("org.gnome.desktop.interface")});
    }
}

void ProcessRunner::setWallpaper(const QString &url, const QString &name) {
    if (url.isEmpty()) return;
    m_wallpaperUrl = url;
    if (!name.isEmpty()) m_wallpaperName = name;
    emit wallpaperUrlChanged();
    emit wallpaperNameChanged();

    QString cleanUrl = url;
    if (!cleanUrl.startsWith(QStringLiteral("file://"))) {
        if (cleanUrl.startsWith(QStringLiteral("/"))) {
            cleanUrl = QStringLiteral("file://") + cleanUrl;
        } else {
            cleanUrl = QStringLiteral("file://") + getSwiftDEPath(QStringLiteral("/") + cleanUrl);
        }
    }
    QString localFile = QUrl(cleanUrl).toLocalFile();

    QString cmd = QStringLiteral(
        "gsettings set org.gnome.desktop.background picture-uri \"%1\"; "
        "gsettings set org.gnome.desktop.background picture-uri-dark \"%1\"; "
        "mkdir -p \"%3/Library/DesktopPictures\"; "
        "if [ -f \"%2\" ]; then cp -f \"%2\" \"%3/Library/DesktopPictures/Wallpaper.jpg\" 2>/dev/null || true; fi"
    ).arg(cleanUrl, localFile, getSwiftDEPath());

    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), cmd});
}

void ProcessRunner::setColorScheme(const QString &scheme) {
    m_colorScheme = scheme;
    m_isDark = (scheme == QStringLiteral("prefer-dark") || scheme == QStringLiteral("dark"));
    emit colorSchemeChanged();
    QString cmd = QStringLiteral("gsettings set org.gnome.desktop.interface color-scheme \"%1\"").arg(scheme);
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), cmd});
    refreshWallpaper();
}

void ProcessRunner::setAccentColor(const QString &color) {
    m_accentColor = color;
    emit accentColorChanged();
}

void ProcessRunner::openSystemSettings(const QString &tab) {
    QProcess *proc = new QProcess(this);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.remove(QStringLiteral("QT_WAYLAND_SHELL_INTEGRATION"));
    env.insert(QStringLiteral("QT_WAYLAND_SHELL_INTEGRATION"), QStringLiteral("xdg-shell"));
    env.insert(QStringLiteral("LIBGL_ALWAYS_SOFTWARE"), QStringLiteral("1"));
    env.insert(QStringLiteral("QSG_RHI_BACKEND"), QStringLiteral("opengl"));
    env.insert(QStringLiteral("XDG_CURRENT_DESKTOP"), QStringLiteral("GNOME:Unity:SwiftDE"));
    proc->setProcessEnvironment(env);
    QString qmlPath = getSwiftDEPath(QStringLiteral("/System/Library/CoreServices/SystemSettings.app/Contents/Resources/SystemSettings.qml"));
    QStringList args;
    args << qmlPath;
    if (!tab.isEmpty()) args << tab;
    proc->startDetached(getSwiftDEPath(QStringLiteral("/SwiftDE-RunQML")), args);
}

void ProcessRunner::toggleLaunchpad() {
    QProcess check;
    check.start(QStringLiteral("pgrep"), {QStringLiteral("-f"), QStringLiteral("Launchpad.qml")});
    if (check.waitForFinished(200) && !check.readAllStandardOutput().trimmed().isEmpty()) {
        QProcess::execute(QStringLiteral("pkill"), {QStringLiteral("-f"), QStringLiteral("Launchpad.qml")});
        return;
    }

    QProcess *proc = new QProcess(this);
    proc->setProgram(getSwiftDEPath(QStringLiteral("/SwiftDE-RunQML")));
    proc->setArguments({
        QStringLiteral("--layer"),
        getSwiftDEPath(QStringLiteral("/System/Library/CoreServices/Launchpad.app/Contents/Resources/Launchpad.qml"))
    });
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    if (env.value(QStringLiteral("WAYLAND_DISPLAY")).isEmpty()) env.insert(QStringLiteral("WAYLAND_DISPLAY"), QStringLiteral("wayland-1"));
    if (env.value(QStringLiteral("XDG_RUNTIME_DIR")).isEmpty()) env.insert(QStringLiteral("XDG_RUNTIME_DIR"), QStringLiteral("/run/user/%1").arg(getuid()));
    if (env.value(QStringLiteral("DBUS_SESSION_BUS_ADDRESS")).isEmpty()) env.insert(QStringLiteral("DBUS_SESSION_BUS_ADDRESS"), QStringLiteral("unix:path=/run/user/%1/bus").arg(getuid()));
    env.remove(QStringLiteral("QT_WAYLAND_SHELL_INTEGRATION"));
    env.insert(QStringLiteral("LIBGL_ALWAYS_SOFTWARE"), QStringLiteral("1"));
    env.insert(QStringLiteral("QSG_RHI_BACKEND"), QStringLiteral("opengl"));
    env.insert(QStringLiteral("XDG_CURRENT_DESKTOP"), QStringLiteral("GNOME:Unity:SwiftDE"));
    proc->setProcessEnvironment(env);
    proc->startDetached();
}

QString ProcessRunner::loadLaunchpadLayout() {
    QString userConfig = QDir::homePath() + QStringLiteral("/.config/swiftde/launchpad.json");
    if (QFile::exists(userConfig)) {
        QFile f(userConfig);
        if (f.open(QIODevice::ReadOnly)) return QString::fromUtf8(f.readAll());
    }
    QString systemConfig = getSwiftDEPath(QStringLiteral("/Library/Preferences/launchpad.json"));
    QFile f(systemConfig);
    if (f.open(QIODevice::ReadOnly)) {
        return QString::fromUtf8(f.readAll());
    }
    return QString();
}

void ProcessRunner::saveLaunchpadLayout(const QString &json) {
    QString userDir = QDir::homePath() + QStringLiteral("/.config/swiftde");
    QDir().mkpath(userDir);
    QFile f(userDir + QStringLiteral("/launchpad.json"));
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        f.write(json.toUtf8());
        f.close();
    }
    QString systemConfig = getSwiftDEPath(QStringLiteral("/Library/Preferences/launchpad.json"));
    QFile fSys(systemConfig);
    if (fSys.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        fSys.write(json.toUtf8());
        fSys.close();
    }
}


