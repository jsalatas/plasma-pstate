/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
#ifndef SETPREFS_H
#define SETPREFS_H

#include <QDebug>
#include <QProcess>
#include <QtCore>
#include <Plasma/Applet>

#include "sharedqueue.h"
#include "command_result.h"

class Pstate;

class SetPrefs : public QObject {
    Q_OBJECT

    QTextCodec *m_codec;
    SharedQueue<QStringList> m_args;
    QProcess m_proc{this};

public:
	SetPrefs(QObject *parent = nullptr);
    ~SetPrefs();

    void startScript();
    void runCommand(QStringList args);

signals:
    void procStarted();
    void procFinished();

    // Emit command results to main Plasma Applet
    void commandFinished(CommandResult* data);

public slots:
    void read();
    void started();
    void finished();
};


#endif
