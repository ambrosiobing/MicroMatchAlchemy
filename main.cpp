// main.cpp: Felgo bootstrap for MicroMatchAlchemy (Qt 6 + Felgo SDK).
//
// AUTO-LOGGING: writes <project>/logs/run_TS.log + latest.log; falls back
// to QStandardPaths::AppDataLocation if source-dir is not writable.
//
// CONFIG.JSON SELF-HEAL: writes a stub to multiple plausible locations so
// Felgo SDK 4.x can find it regardless of CWD.

#include <QApplication>
#include <FelgoApplication>
#include <QQmlApplicationEngine>

#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QLoggingCategory>
#include <QMutex>
#include <QStandardPaths>
#include <QStringList>
#include <QSysInfo>
#include <QTextStream>
#include <QtGlobal>

#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace {

QFile        g_logFile;
QTextStream  g_logStream;
QMutex       g_logMutex;

void messageHandler(QtMsgType type,
                    const QMessageLogContext &ctx,
                    const QString &msg)
{
    QMutexLocker<QMutex> lock(&g_logMutex);
    const char *level = "INFO ";
    switch (type) {
        case QtDebugMsg:    level = "DEBUG"; break;
        case QtInfoMsg:     level = "INFO "; break;
        case QtWarningMsg:  level = "WARN "; break;
        case QtCriticalMsg: level = "ERROR"; break;
        case QtFatalMsg:    level = "FATAL"; break;
    }
    QString cat;
    if (ctx.category && *ctx.category && std::strcmp(ctx.category, "default") != 0)
        cat = QString::fromLatin1("%1: ").arg(QLatin1String(ctx.category));
    QString src;
    if (ctx.file)
        src = QString::fromLatin1(" (%1:%2)").arg(QLatin1String(ctx.file)).arg(ctx.line);
    const QString line = QString("[%1] [%2] %3%4%5\n")
        .arg(QDateTime::currentDateTime().toString("hh:mm:ss.zzz"))
        .arg(QLatin1String(level)).arg(cat).arg(msg).arg(src);
    std::fputs(line.toUtf8().constData(), stderr);
    std::fflush(stderr);
    if (g_logStream.device()) { g_logStream << line; g_logStream.flush(); }
    if (type == QtFatalMsg) std::abort();
}

QString tryOpenLog(const QString &baseDir)
{
    const QString logDir = baseDir + QStringLiteral("/logs");
    std::fprintf(stderr, "MicroMatchAlchemy: trying log dir: %s\n", qPrintable(logDir));
    if (!QDir().mkpath(logDir)) {
        std::fprintf(stderr, "MicroMatchAlchemy:   mkpath FAILED for %s\n", qPrintable(logDir));
        return QString();
    }
    const QString stamp  = QDateTime::currentDateTime().toString("yyyy-MM-dd_HH-mm-ss");
    const QString runLog = logDir + QStringLiteral("/run_") + stamp + QStringLiteral(".log");
    g_logFile.setFileName(runLog);
    if (!g_logFile.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        std::fprintf(stderr, "MicroMatchAlchemy:   open FAILED for %s\n", qPrintable(runLog));
        return QString();
    }
    return runLog;
}

void ensureConfigJson()
{
    static const char *kStub = R"JSON({
    "stage":   "production",
    "appName": "MicroMatchAlchemy"
}
)JSON";

    QStringList dirs;
    dirs << QCoreApplication::applicationDirPath();
    dirs << QDir::currentPath();
    dirs << QFileInfo(QCoreApplication::applicationDirPath()).absolutePath();
#ifdef MMA_SOURCE_DIR
    dirs << QStringLiteral(MMA_SOURCE_DIR);
#endif
    dirs.removeDuplicates();

    std::fprintf(stderr, "MicroMatchAlchemy: QDir::currentPath() = %s\n",
                 qPrintable(QDir::currentPath()));

    for (const QString &dir : dirs) {
        const QString p = dir + QStringLiteral("/config.json");
        if (QFile::exists(p)) {
            std::fprintf(stderr, "MicroMatchAlchemy: config.json EXISTS at %s\n",
                         qPrintable(p));
            continue;
        }
        QFile f(p);
        if (f.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
            f.write(kStub);
            f.close();
            std::fprintf(stderr, "MicroMatchAlchemy: wrote config.json to %s\n",
                         qPrintable(p));
        } else {
            std::fprintf(stderr, "MicroMatchAlchemy: could not write config.json to %s\n",
                         qPrintable(p));
        }
    }
}

void initRunLogging()
{
    std::fprintf(stderr, "MicroMatchAlchemy: --- initRunLogging() entered ---\n");
    std::fflush(stderr);

    QString srcDir;
#ifdef MMA_SOURCE_DIR
    srcDir = QStringLiteral(MMA_SOURCE_DIR);
    std::fprintf(stderr, "MicroMatchAlchemy: MMA_SOURCE_DIR = %s\n", qPrintable(srcDir));
#else
    srcDir = QDir::currentPath();
    std::fprintf(stderr, "MicroMatchAlchemy: MMA_SOURCE_DIR not defined; using cwd %s\n", qPrintable(srcDir));
#endif

    QString runLog = tryOpenLog(srcDir);
    if (runLog.isEmpty()) {
        const QString fallback =
            QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        std::fprintf(stderr, "MicroMatchAlchemy: falling back to AppData: %s\n",
                     qPrintable(fallback));
        runLog = tryOpenLog(fallback);
    }
    if (runLog.isEmpty()) {
        std::fputs("MicroMatchAlchemy: ALL log paths failed; logging only to stderr.\n", stderr);
        std::fflush(stderr);
        qInstallMessageHandler(messageHandler);
        return;
    }

    g_logStream.setDevice(&g_logFile);
    g_logStream.setEncoding(QStringConverter::Utf8);
    const QString latest = QFileInfo(runLog).absolutePath() + QStringLiteral("/latest.log");

    g_logStream << "===== MicroMatchAlchemy run log =====\n"
                << "Started     : " << QDateTime::currentDateTime().toString(Qt::ISODate) << "\n"
                << "Qt version  : " << QT_VERSION_STR << "\n"
                << "Built ABI   : " << QSysInfo::buildAbi()           << "\n"
                << "Running on  : " << QSysInfo::prettyProductName()  << "\n"
                << "Run log     : " << runLog << "\n"
                << "Latest copy : " << latest << "\n"
                << "================================\n";
    g_logStream.flush();
    QFile::remove(latest);
    QFile::copy(runLog, latest);

    QLoggingCategory::setFilterRules(QStringLiteral(
        "*.debug=true\n"
        "qt.qml.diskcache.debug=false\n"
        "qt.scenegraph.general.debug=false\n"));

    qInstallMessageHandler(messageHandler);
    std::fprintf(stderr,
        "================================================\n"
        "MicroMatchAlchemy: LOG WRITTEN TO:\n  %s\n  (latest: %s)\n"
        "================================================\n",
        qPrintable(runLog), qPrintable(latest));
    std::fflush(stderr);
    qInfo("logging initialised; writing to %s", qPrintable(runLog));
}

} // namespace

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("ambrosio"));
    app.setApplicationName(QStringLiteral("MicroMatchAlchemy"));

    ensureConfigJson();
    initRunLogging();

    FelgoApplication felgo;
    felgo.setMainQmlFileName(QStringLiteral("qml/Main.qml"));

    QQmlApplicationEngine engine;
    felgo.initialize(&engine);
    felgo.setPreservePlatformFonts(true);
    engine.load(QUrl(felgo.mainQmlFileName()));

    const int rc = app.exec();
    qInfo("MicroMatchAlchemy exited with code %d", rc);
    if (g_logStream.device()) { g_logStream.flush(); g_logFile.close(); }
    return rc;
}
