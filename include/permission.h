/*
 * Permission.h
 *
 *  Created on: Nov 28, 2019
 *      Author: armin
 */

#ifndef COMMON_PERMISSION_H_
#define COMMON_PERMISSION_H_

#include <stdint.h>
#include <vector>
#include <semaphore.h>
#include <pthread.h>

class Permission {
	bool write;
	uint32_t start, end;
	pthread_mutex_t permitLock;
	pthread_mutex_t waitingSemaphoresLock;
	bool locked;
	std::vector<sem_t*> waitingSemaphores;
public:
	Permission(uint32_t start, uint32_t end, bool write) :
		start(start), end(end), write(write) {
		pthread_mutex_init(&permitLock, nullptr);
		pthread_mutex_init(&waitingSemaphoresLock, nullptr);
		locked = false;
	}
	virtual ~Permission();

	uint32_t getEnd() const {
		return end;
	}

	void setEnd(uint32_t end) {
		this->end = end;
	}

	uint32_t getStart() const {
		return start;
	}

	void setStart(uint32_t start) {
		this->start = start;
	}

	bool isWrite() const {
		return write;
	}

	void setWrite(bool write) {
		this->write = write;
	}

	bool addWaitingSemaphore(sem_t* sem) {
		pthread_mutex_lock(&waitingSemaphoresLock);
		if(locked) {
			waitingSemaphores.push_back(sem);
			pthread_mutex_unlock(&waitingSemaphoresLock);
			return true;
		}
		pthread_mutex_unlock(&waitingSemaphoresLock);
		return false;
	}

	bool isShared(uint32_t s, uint32_t e);
	bool isInclusiveShared(uint32_t s, uint32_t e);

	void lock();
	void unlock();
};

#endif /* COMMON_PERMISSION_H_ */
