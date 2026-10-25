import asyncio
import logging
import shutil
import subprocess
import sys

from dbus_next import BusType, Message, MessageType
from dbus_next.aio import MessageBus
from dbus_next.service import ServiceInterface, method

DBUS_NAME = "org.freedesktop.impl.portal.desktop.logind"
OBJECT_PATH = "/org/freedesktop/portal/desktop"

SCREENSAVER_NAME = "org.freedesktop.ScreenSaver"
SCREENSAVER_PATH = "/org/freedesktop/ScreenSaver"
SCREENSAVER_INTERFACE = "org.freedesktop.ScreenSaver"

INHIBIT_LOGOUT = 1
INHIBIT_SWITCH = 2
INHIBIT_SUSPEND = 4
INHIBIT_IDLE = 8

log = logging.getLogger("portal-logind")


def _truncate(value, limit):
    return value[:limit] if value else ""


def _spawn_logind_inhibitor(what, app_id, reason):
    executable = shutil.which("systemd-inhibit")
    if executable is None:
        log.error("systemd-inhibit not found, cannot inhibit %s", what)
        return None

    command = [
        executable,
        f"--what={what}",
        f"--who={_truncate(app_id or 'portal', 255)}",
        f"--why={_truncate(reason or 'inhibited by application', 255)}",
        "--mode=block",
        "sleep",
        "infinity",
    ]

    try:
        return subprocess.Popen(command)
    except OSError as error:
        log.error("failed to start systemd-inhibit: %s", error)
        return None


def _stop_process(process):
    if process.poll() is not None:
        return
    process.terminate()
    try:
        process.wait(timeout=2)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()


async def _screensaver_call(bus, member, signature, body):
    reply = await bus.call(
        Message(
            destination=SCREENSAVER_NAME,
            path=SCREENSAVER_PATH,
            interface=SCREENSAVER_INTERFACE,
            member=member,
            signature=signature,
            body=body,
        )
    )
    if reply.message_type != MessageType.METHOD_RETURN:
        raise RuntimeError(reply.error_name or "screensaver call failed")
    return reply.body


async def _inhibit_idle(bus, app_id, reason):
    try:
        body = await _screensaver_call(
            bus, "Inhibit", "ss", [app_id or "portal", reason or ""]
        )
        return body[0]
    except Exception as error:
        log.debug("org.freedesktop.ScreenSaver.Inhibit unavailable: %s", error)
        return None


async def _uninhibit_idle(bus, cookie):
    try:
        await _screensaver_call(bus, "UnInhibit", "u", [cookie])
    except Exception as error:
        log.warning("failed to release idle inhibition %s: %s", cookie, error)


class Inhibition:
    def __init__(self):
        self._processes = []
        self._idle_cookies = []

    async def acquire(self, bus, app_id, reason, flags):
        if flags & INHIBIT_SUSPEND:
            process = _spawn_logind_inhibitor("sleep", app_id, reason)
            if process is not None:
                self._processes.append(process)

        if flags & INHIBIT_IDLE:
            cookie = await _inhibit_idle(bus, app_id, reason)
            if cookie is not None:
                self._idle_cookies.append(cookie)
            else:
                process = _spawn_logind_inhibitor("idle", app_id, reason)
                if process is not None:
                    self._processes.append(process)

        if flags & (INHIBIT_LOGOUT | INHIBIT_SWITCH):
            log.info("ignoring logout/user-switch inhibition request")

    async def release(self, bus):
        for process in self._processes:
            _stop_process(process)
        self._processes.clear()

        for cookie in self._idle_cookies:
            await _uninhibit_idle(bus, cookie)
        self._idle_cookies.clear()


class Request(ServiceInterface):
    def __init__(self, path, bus, inhibition):
        super().__init__("org.freedesktop.impl.portal.Request")
        self._path = path
        self._bus = bus
        self._inhibition = inhibition
        self._released = False

    @method()
    async def Close(self):
        await self._release()

    async def _release(self):
        if self._released:
            return
        self._released = True
        await self._inhibition.release(self._bus)
        self._bus.unexport(self._path)


class Inhibit(ServiceInterface):
    def __init__(self, bus):
        super().__init__("org.freedesktop.impl.portal.Inhibit")
        self._bus = bus

    @method()
    async def Inhibit(
        self,
        handle: "o",
        app_id: "s",
        window: "s",
        flags: "u",
        options: "a{sv}",
    ):
        reason = ""
        if "reason" in options:
            reason = options["reason"].value

        log.info("inhibit app=%s flags=%d reason=%r", app_id, flags, reason)

        inhibition = Inhibition()
        await inhibition.acquire(self._bus, app_id, reason, flags)
        self._bus.export(handle, Request(handle, self._bus, inhibition))


async def main():
    logging.basicConfig(level=logging.INFO, stream=sys.stderr)

    bus = await MessageBus(bus_type=BusType.SESSION).connect()
    bus.export(OBJECT_PATH, Inhibit(bus))
    await bus.request_name(DBUS_NAME)

    log.info("exported %s at %s", DBUS_NAME, OBJECT_PATH)
    await bus.wait_for_disconnect()


if __name__ == "__main__":
    asyncio.run(main())
