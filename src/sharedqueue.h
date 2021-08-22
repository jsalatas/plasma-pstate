/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
#ifndef SHAREDQUEUE_H
#define SHAREDQUEUE_H

#include <queue>
#include <mutex>
#include <condition_variable>


template <typename T>
class SharedQueue
{
private:
    std::mutex m_mutex;
    std::condition_variable m_cond;

    std::deque<T> m_queue;

public:
    SharedQueue();
    ~SharedQueue();

    int size();

    T& front();
    void pop_front();

    void push_back(const T& item);
    void push_back(T&& item);
};

template <typename T>
SharedQueue<T>::SharedQueue()
{

}

template <typename T>
SharedQueue<T>::~SharedQueue()
{

}

template <typename T>
T& SharedQueue<T>::front()
{
    std::unique_lock<std::mutex> mlock(this->m_mutex);
    while (this->m_queue.empty())
    {
        this->m_cond.wait(mlock);
    }
    return this->m_queue.front();
}

template <typename T>
void SharedQueue<T>::pop_front()
{
    std::unique_lock<std::mutex> mlock(this->m_mutex);
    while (this->m_queue.empty())
    {
        this->m_cond.wait(mlock);
    }
    this->m_queue.pop_front();
}

template <typename T>
void SharedQueue<T>::push_back(const T& item)
{
    std::unique_lock<std::mutex> mlock(this->m_mutex);
    this->m_queue.push_back(item);
    mlock.unlock();
    this->m_cond.notify_one();

}

template <typename T>
void SharedQueue<T>::push_back(T&& item)
{
    std::unique_lock<std::mutex> mlock(this->m_mutex);
    this->m_queue.push_back(std::move(item));
    mlock.unlock();
    this->m_cond.notify_one();

}

template <typename T>
int SharedQueue<T>::size()
{
    std::unique_lock<std::mutex> mlock(this->m_mutex);
    int size = this->m_queue.size();
    mlock.unlock();
    return size;
}

#endif /* SHAREDQUEUE_H */
