// SwiftDE QML runner (tiny host for shell QML files).
// Build: g++ runner.cpp -o SwiftDE-RunQML $(pkg-config --cflags --libs Qt6Gui Qt6Qml Qt6Quick) -lLayerShellQtInterface
// --layer: present the window as a layer-shell overlay with exclusive keyboard
// (lockscreen semantics: above everything, Alt+Tab and other shortcuts dead).
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlEngine>
#include <QQuickWindow>
#include <QDebug>
#include <QLockFile>
#include <QDir>
#include <memory>

#include <unistd.h>
#include <QFontDatabase>
#include <LayerShellQt/Shell>
#include <LayerShellQt/Window>

#include "processrunner.h"

int main(int argc, char **argv) {
    qputenv("LIBGL_ALWAYS_SOFTWARE", "1");
    qputenv("QSG_RHI_BACKEND", "opengl");
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM")) {
        qputenv("QT_QPA_PLATFORM", "wayland");
    }
    if (qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) {
        qputenv("WAYLAND_DISPLAY", "wayland-1");
    }
    if (qEnvironmentVariableIsEmpty("XDG_RUNTIME_DIR")) {
        QByteArray runtimeDir = "/run/user/" + QByteArray::number(getuid());
        qputenv("XDG_RUNTIME_DIR", runtimeDir);
    }

    bool layer = false;
    bool topbar = false;
    bool desktop = false;
    bool dock = false;
    for (int i = 1; i < argc; ++i) {
        QString arg = QString::fromLocal8Bit(argv[i]);
        if (arg == QStringLiteral("--layer"))
            layer = true;
        if (arg == QStringLiteral("--topbar"))
            topbar = true;
        if (arg == QStringLiteral("--desktop"))
            desktop = true;
        if (arg == QStringLiteral("--dock"))
            dock = true;
    }
    if (argc < 2 || ((layer || topbar || desktop || dock) && argc < 3)) {
        qWarning() << "usage: SwiftDE-RunQML [--layer|--topbar|--desktop|--dock] <file.qml>";
        return 2;
    }

    const char *qml = argv[argc - 1];
    QString qmlStr = QString::fromLocal8Bit(qml);

    // Single-instance protection for CoreServices to avoid duplicate bars/desktops
    QString lockName;
    if (topbar) lockName = QStringLiteral("swiftde-topbar.lock");
    else if (desktop) lockName = QStringLiteral("swiftde-desktop.lock");
    else if (layer && qmlStr.contains(QStringLiteral("Lockscreen"))) lockName = QStringLiteral("swiftde-lockscreen.lock");
    else if (dock) lockName = QStringLiteral("swiftde-dock.lock");
    else if (qmlStr.contains(QStringLiteral("SystemSettings"))) lockName = QStringLiteral("swiftde-settings.lock");

    std::unique_ptr<QLockFile> lockFile;
    if (!lockName.isEmpty()) {
        QString runtimeDir = qgetenv("XDG_RUNTIME_DIR");
        if (runtimeDir.isEmpty()) runtimeDir = QDir::tempPath();
        lockFile = std::make_unique<QLockFile>(runtimeDir + QLatin1Char('/') + lockName);
        if (!lockFile->tryLock(100)) {
            qWarning() << "Another instance of" << lockName << "is already running. Exiting.";
            return 0;
        }
    }
    if (layer || topbar || desktop || dock) {
        LayerShellQt::Shell::useLayerShell();
    } else {
        qunsetenv("QT_WAYLAND_SHELL_INTEGRATION");
        qputenv("QT_WAYLAND_SHELL_INTEGRATION", "xdg-shell");
    }
    QGuiApplication app(argc, argv);
    QFontDatabase::addApplicationFont(ProcessRunner::getSwiftDEPath(QStringLiteral("/System/Library/Fonts/SF-Symbols-6.otf")));
    QFontDatabase::addApplicationFont(ProcessRunner::getSwiftDEPath(QStringLiteral("/Library/Fonts/SF-Symbols-6.otf")));
    app.setApplicationName(QStringLiteral("Finder"));
    app.setDesktopFileName(QStringLiteral("com.apple.finder"));
    qmlRegisterType<ProcessRunner>("SwiftDE", 1, 0, "SysProc");
    QQmlApplicationEngine engine;
    engine.load(QString::fromLocal8Bit(qml));
    if (engine.rootObjects().isEmpty())
        return 1;
    if (layer || topbar || desktop || dock) {
        if (auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first())) {
            if (auto *ls = LayerShellQt::Window::get(win)) {
                if (topbar) {
                    ls->setLayer(LayerShellQt::Window::LayerTop);
                    LayerShellQt::Window::Anchors anchors;
                    anchors |= LayerShellQt::Window::AnchorTop;
                    anchors |= LayerShellQt::Window::AnchorLeft;
                    anchors |= LayerShellQt::Window::AnchorRight;
                    ls->setAnchors(anchors);
                    ls->setExclusiveZone(25);
                    ls->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
                    ls->setScope(QStringLiteral("topbar"));
                } else if (desktop) {
                    ls->setLayer(LayerShellQt::Window::LayerBackground);
                    LayerShellQt::Window::Anchors anchors;
                    anchors |= LayerShellQt::Window::AnchorTop;
                    anchors |= LayerShellQt::Window::AnchorBottom;
                    anchors |= LayerShellQt::Window::AnchorLeft;
                    anchors |= LayerShellQt::Window::AnchorRight;
                    ls->setAnchors(anchors);
                    ls->setExclusiveZone(-1);
                    ls->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
                    ls->setScope(QStringLiteral("desktop"));
                } else if (dock) {
                    ls->setLayer(LayerShellQt::Window::LayerTop);
                    LayerShellQt::Window::Anchors anchors;
                    anchors |= LayerShellQt::Window::AnchorBottom;
                    anchors |= LayerShellQt::Window::AnchorLeft;
                    anchors |= LayerShellQt::Window::AnchorRight;
                    ls->setAnchors(anchors);
                    ls->setExclusiveZone(68);
                    ls->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
                    ls->setScope(QStringLiteral("dock"));
                } else if (qmlStr.contains(QStringLiteral("Launchpad"))) {
                    ls->setLayer(LayerShellQt::Window::LayerTop);
                    LayerShellQt::Window::Anchors anchors;
                    anchors |= LayerShellQt::Window::AnchorTop;
                    anchors |= LayerShellQt::Window::AnchorBottom;
                    anchors |= LayerShellQt::Window::AnchorLeft;
                    anchors |= LayerShellQt::Window::AnchorRight;
                    ls->setAnchors(anchors);
                    ls->setExclusiveZone(-1);
                    ls->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityExclusive);
                    ls->setScope(QStringLiteral("launchpad"));
                } else {
                    ls->setLayer(LayerShellQt::Window::LayerOverlay);
                    LayerShellQt::Window::Anchors anchors;
                    anchors |= LayerShellQt::Window::AnchorTop;
                    anchors |= LayerShellQt::Window::AnchorBottom;
                    anchors |= LayerShellQt::Window::AnchorLeft;
                    anchors |= LayerShellQt::Window::AnchorRight;
                    ls->setAnchors(anchors);
                    ls->setExclusiveZone(-1);
                    ls->setKeyboardInteractivity(
                        LayerShellQt::Window::KeyboardInteractivityExclusive);
                    ls->setScope(QStringLiteral("lockscreen"));
                }
            } else {
                qWarning() << "layer-shell not supported by compositor";
            }
            win->show();
        }
    } else {
        if (auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first())) {
            if (qmlStr.contains(QStringLiteral("AboutThisMac"))) {
                win->setMinimumSize(QSize(260, 418));
                win->setMaximumSize(QSize(260, 418));
                win->resize(260, 418);
                win->setFlag(Qt::MSWindowsFixedSizeDialogHint, true);
                win->setFlag(Qt::Dialog, true);
                win->setFlag(Qt::FramelessWindowHint, true);
            } else if (qmlStr.contains(QStringLiteral("SystemSettings"))) {
                win->setMinimumSize(QSize(800, 560));
                win->resize(880, 640);
                win->setFlag(Qt::FramelessWindowHint, true);
            }
            win->setVisibility(QWindow::Windowed);
            win->show();
        }
    }
    return app.exec();
}
