/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "pstate.h"

#include <KLocalizedString>


Pstate::Pstate(QObject *parent, const QVariantList &args)
    : Plasma::Applet(parent, args)
{
    m_exec = new SetPrefs{this};

    QObject::connect(m_exec, &SetPrefs::procStarted,
                     this, &Pstate::setPrefsStarted);
    QObject::connect(m_exec, &SetPrefs::procFinished,
                     this, &Pstate::setPrefsFinished);
    QObject::connect(m_exec, &SetPrefs::commandFinished,
                     this, &Pstate::setPrefsCommandFinished);
}

Pstate::~Pstate()
{
    if (m_exec)
        delete m_exec;
}

bool Pstate::isReady()
{
    return m_isReady;
}

void Pstate::setPrefsStarted()
{
    m_isReady = true;
    emit isReadyChanged(m_isReady);
}

void Pstate::setPrefsFinished()
{
    m_isReady = false;
    emit isReadyChanged(m_isReady);
}

void Pstate::setPrefs(const QStringList &args)
{
    if (m_exec) {
        m_exec->runCommand(args);
    }
}

void Pstate::setPrefsCommandFinished(CommandResult* data)
{
    emit commandFinished(data);
}


K_PLUGIN_CLASS_WITH_JSON(Pstate, "metadata.json")

#include "pstate.moc"
