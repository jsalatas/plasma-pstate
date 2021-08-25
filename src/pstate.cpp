/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "pstate.h"

#include <KLocalizedString>


#define ORGANIZATION    "gr.ictpro.jsalatas.plasma.pstate"
#define APPLICATION     "pstate"


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

void Pstate::startScript()
{
    m_exec->startScript();
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


QStringList Pstate::getProfileList()
{
    QSettings settings(ORGANIZATION, APPLICATION);
    QVariant val = settings.value("profileList");
    QStringList data = val.value<QStringList>();
    return data;
}

void Pstate::saveProfileList(QStringList data)
{
    QSettings settings(ORGANIZATION, APPLICATION);
    settings.setValue("profileList", QVariant::fromValue(data));
}

void Pstate::saveProfile(QString name, QString data)
{
    QSettings settings(ORGANIZATION, APPLICATION);
    settings.beginGroup("profiles");
    settings.setValue(name, data);
    settings.endGroup();
    settings.sync();
}

void Pstate::deleteProfile(QString name)
{
    QSettings settings(ORGANIZATION, APPLICATION);
    settings.beginGroup("profiles");
    settings.remove(name);
    settings.endGroup();
    settings.sync();
}

QString Pstate::getProfile(QString name)
{
    QSettings settings(ORGANIZATION, APPLICATION);
    settings.beginGroup("profiles");
    QVariant val = settings.value(name);
    QString data = val.value<QString>();
    settings.endGroup();
    return data;
}

K_PLUGIN_CLASS_WITH_JSON(Pstate, "metadata.json")

#include "pstate.moc"
