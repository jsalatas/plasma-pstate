/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef PSTATE_H
#define PSTATE_H


#include <QtCore/QObject>
#include <Plasma/Applet>

#include "command_result.h"
#include "set_prefs.h"


class Pstate : public Plasma::Applet
{
    Q_OBJECT
    Q_PROPERTY(bool isReady READ isReady NOTIFY isReadyChanged)

    SetPrefs* m_exec;


public:
    Pstate( QObject *parent, const QVariantList &args );
    ~Pstate();

    bool isReady();

signals:
    // Emit command results to QML
    void commandFinished(CommandResult* data);

    void isReadyChanged(bool isReady);

public slots:
    void setPrefs(const QStringList &args);

private:
    bool m_isReady;

private slots:
    void setPrefsStarted();
    void setPrefsFinished();
    void setPrefsCommandFinished(CommandResult* data);
};

#endif
