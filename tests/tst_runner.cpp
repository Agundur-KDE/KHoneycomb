#include <QtQuickTest>
#include <QQmlContext>
#include <QQmlEngine>
#include <QTemporaryDir>
#include <KLocalizedContext>

class Setup : public QObject {
    Q_OBJECT
    QTemporaryDir directory;
public slots:
    void qmlEngineAvailable(QQmlEngine *engine) {
        qputenv("XDG_DATA_HOME", (directory.path() + "/data").toUtf8());
        auto *context = new KLocalizedContext(engine);
        context->setTranslationDomain("plasma_applet_de.agundur.khoneycomb");
        engine->rootContext()->setContextObject(context);
        engine->rootContext()->setContextProperty("backupTestDirectory", directory.path());
    }
};

QUICK_TEST_MAIN_WITH_SETUP(plasmoid, Setup)
#include "tst_runner.moc"
