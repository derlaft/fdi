import tables, times, locks, os

import ./util, strutils

# little redis-like kv storage
# TTL is checked on access for all the entries
# @TODO: generic support

type

  # value of table
  composed = object
    value: int
    expireAt: Time

  # locks are not really necessary for fdi
  # but let it be there for easy code reuse
  expiretable* = ref object
    lock: TLock
    table {.guard: lock.}: Table[string, composed]


# drop out-of-date entries`
proc clean(t: expiretable) =
  withLock t.lock:
    for k, v in t.table:
      if v.expireAt < getTime():
        t.table.del(k)
        D("Deleting key $1" % k)

# get value
proc get*(t: expiretable, key: string): int =
  clean t

  withLock t.lock:
    if t.table.hasKey(key):
      return t.table[key].value

  return 0

# put value
proc put*(t: expiretable, key: string, value: int, ttl: TimeInterval = 2.minutes) =
  withLock t.lock:
    t.table[key] = composed(
      value: value,
      expireAt: getTime() + ttl
    )

# increment value
proc inc*(t: expiretable, key: string, ttl: TimeInterval = 20.seconds) =
  withLock t.lock:
    if t.table.hasKey(key):
      var val = t.table[key]
      val.value = val.value + 1
      t.table[key] = val
      return

  t.put(key, 1, ttl)

# create new table
proc newExpire*(): expiretable =
  let res = expiretable(
    table: initTable[string, composed]()
  )
  initLock(res.lock)
  return res
