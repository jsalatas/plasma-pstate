/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#ifndef PSTATE_H
#define PSTATE_H


#include <Plasma/Applet>

class Pstate : public Plasma::Applet
{
    Q_OBJECT
    Q_PROPERTY(QString nativeText READ nativeText CONSTANT)

public:
    Pstate( QObject *parent, const QVariantList &args );
    ~Pstate();

    QString nativeText() const;

private:
    QString m_nativeText;
};

#endif
