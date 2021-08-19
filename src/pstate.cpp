/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#include "pstate.h"
#include <KLocalizedString>

Pstate::Pstate(QObject *parent, const QVariantList &args)
    : Plasma::Applet(parent, args),
      m_nativeText(i18n("Text coming from C++ plugin"))
{
}

Pstate::~Pstate()
{
}

QString Pstate::nativeText() const
{
    return m_nativeText;
}

K_PLUGIN_CLASS_WITH_JSON(Pstate, "metadata.json")

#include "pstate.moc"
