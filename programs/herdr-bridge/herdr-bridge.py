"""Route Plannotator reviews and editor requests to the herdr client viewing the session.

A request is one JSON file that moves between state directories with rename(2). The first
party to rename it out of pending/ owns it. The herdr server asks the foreground client to
claim a request by setting the window title to hbridge:<id>. The client wrapper (wrap) strips
that title from the output stream and claims the request, over ssh for remote clients.
"""
import argparse
import contextlib
import ctypes
import fcntl
import json
import os
import pty
import re
import secrets
import select
import signal
import socket
import subprocess
import sys
import termios
import threading
import time
import tty
import urllib.error
import urllib.parse
import urllib.request

HERDR = "@herdr@"
SSH = "@ssh@"
XDG_OPEN = "@xdgOpen@"
CLAIM_TIMEOUT = @claimTimeout@
PENDING_MAX_AGE = @pendingMaxAge@
CLAIM_STALE_AFTER = @claimStaleAfter@
EDITOR_DEFAULT = "@defaultEditor@"
EDITOR_ALT = "@altEditor@"

STATE_BASE = os.path.join(os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state"), "herdr-bridge")
# Store directory for the herdr session in use. Set by main() before any store access.
SESSION = "herdr"
TOKEN_RE = re.compile(rb"\x1b\](?:0|2);hbridge:([0-9a-f]{16})(?:\x07|\x1b\\)")
OSC_MAX = 128
PULL_IDLE_SECONDS = 60
REAPER_INTERVAL = 30
# Returned by request() when a client claimed and finished the request before the caller looked.
CLAIMED_DONE = "claimed-done"

# Run on the herdr host over ssh. Store path is $HOME/.local/state/herdr-bridge/$1 (the session).
# Positional args: $1 session, $2 id, $3 mode, $4 client id.
CLAIM_SH = """d="$HOME/.local/state/herdr-bridge/$1"
mv -- "$d/pending/$2.json" "$d/claimed/$2.$3.$4.json" && cat -- "$d/claimed/$2.$3.$4.json"
"""
# $1 session, $2 claimed file name.
ACK_SH = """rm -f -- "$HOME/.local/state/herdr-bridge/$1/claimed/$2"
"""
# Claims the first pending open-url request for this client. $1 session, $2 client id.
PULL_SH = """d="$HOME/.local/state/herdr-bridge/$1"
for f in "$d"/pending/*.json; do
  [ -e "$f" ] || continue
  grep -q '"type": "open-url"' -- "$f" || continue
  id=$(basename "$f" .json)
  c="$d/claimed/$id.remote.$2.json"
  if mv -- "$f" "$c" 2>/dev/null; then cat -- "$c"; exit 0; fi
done
exit 1
"""


def log(msg):
    try:
        os.makedirs(STATE_BASE, exist_ok=True)
        with open(os.path.join(STATE_BASE, "log"), "a") as f:
            f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} {msg}\n")
    except OSError:
        pass


def sub(name):
    return os.path.join(STATE_BASE, SESSION, name)


def ensure_store():
    for d in ("tmp", "pending", "claimed", "trash"):
        os.makedirs(sub(d), exist_ok=True)


def server_session():
    """The herdr session name is the directory its socket lives in (the default is "herdr")."""
    sock = os.environ.get("HERDR_SOCKET_PATH") or os.path.expanduser("~/.config/herdr/herdr.sock")
    return os.path.basename(os.path.dirname(os.path.realpath(sock))) or "herdr"


def herdr_rpc(method, params):
    path = os.environ.get("HERDR_SOCKET_PATH") or os.path.expanduser("~/.config/herdr/herdr.sock")
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.settimeout(5)
        sock.connect(path)
        sock.sendall(json.dumps({"id": secrets.token_hex(4), "method": method, "params": params}).encode() + b"\n")
        buf = b""
        while b"\n" not in buf:
            chunk = sock.recv(65536)
            if not chunk:
                break
            buf += chunk
    reply = json.loads(buf.split(b"\n", 1)[0] or b"{}")
    if "error" in reply:
        raise RuntimeError(f"{method}: {reply['error']}")
    return reply.get("result")


def notify(title, body):
    try:
        herdr_rpc("notification.show", {"title": title, "body": body})
    except (OSError, RuntimeError, ValueError) as e:
        log(f"notify failed: {e}")


def spawn_detached(cmd):
    subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)


def editor_for(variant, explicit):
    if explicit:
        return explicit
    return EDITOR_ALT if variant == "alt" else EDITOR_DEFAULT


def editor_command(editor, path, dest):
    """dest is the ssh destination of the remote host, or None for a local open."""
    if dest is None:
        return ["zeditor", path] if editor == "zed" else ["code", path]
    if editor == "zed":
        return ["zeditor", f"ssh://{dest}{path}"]
    return ["code", "--remote", f"ssh-remote+{dest}", path]


def probe(url, timeout=3):
    try:
        urllib.request.urlopen(url, timeout=timeout).close()
        return True
    except urllib.error.HTTPError:
        return True
    except (urllib.error.URLError, OSError, ValueError):
        return False


def proc_start_time(pid):
    try:
        with open(f"/proc/{pid}/stat") as f:
            stat = f.read()
    except OSError:
        return None
    # Field 22 (starttime). Skip past the parenthesised command name, which may contain spaces.
    return stat.rsplit(")", 1)[1].split()[19]


def owner_alive(owner):
    """owner is {"pid", "start"} as recorded by publish, or None for requests without an owner."""
    if owner is None:
        return True
    return proc_start_time(owner["pid"]) == owner["start"]


def new_request(kind, payload, owner_pid=None):
    owner = None
    if owner_pid is not None and proc_start_time(owner_pid) is not None:
        owner = {"pid": owner_pid, "start": proc_start_time(owner_pid)}
    return {
        "id": secrets.token_hex(8),
        "type": kind,
        "created_at": time.time(),
        "payload": payload,
        "owner": owner,
    }


def publish(req):
    ensure_store()
    tmp = sub(f"tmp/{req['id']}.json")
    with open(tmp, "w") as f:
        json.dump(req, f)
        f.flush()
        os.fsync(f.fileno())
    os.rename(tmp, sub(f"pending/{req['id']}.json"))


def find_claim(rid):
    try:
        names = os.listdir(sub("claimed"))
    except FileNotFoundError:
        return None
    for name in names:
        if name.startswith(rid + "."):
            return sub(f"claimed/{name}")
    return None


@contextlib.contextmanager
def title_lock():
    """Only one request may use the window title at a time. Held only around title use."""
    ensure_store()
    fd = os.open(sub("title.lock"), os.O_CREAT | os.O_RDWR, 0o600)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield
    finally:
        os.close(fd)


def request(req, keep_pending):
    """Publish a request and wait for a client to claim it. Returns the claimed path or None."""
    rid = req["id"]
    publish(req)
    claimed = None
    with title_lock():
        try:
            herdr_rpc("client.window_title.set", {"title": f"hbridge:{rid}"})
            deadline = time.monotonic() + CLAIM_TIMEOUT
            while claimed is None and time.monotonic() < deadline:
                claimed = find_claim(rid)
                if claimed is None:
                    time.sleep(0.1)
        except (OSError, RuntimeError, ValueError) as e:
            log(f"title set failed: {e}")
        finally:
            try:
                herdr_rpc("client.window_title.clear", {})
            except (OSError, RuntimeError, ValueError) as e:
                log(f"title clear failed: {e}")
    if claimed is not None:
        return claimed
    if keep_pending:
        if not os.path.exists(sub(f"pending/{rid}.json")):
            # Claimed after the wait ended, and the claimer already finished with it.
            return find_claim(rid) or CLAIMED_DONE
        return None
    try:
        os.rename(sub(f"pending/{rid}.json"), sub(f"trash/{rid}.json"))
        os.unlink(sub(f"trash/{rid}.json"))
    except FileNotFoundError:
        # A client claimed it between the timeout and the cancel.
        return find_claim(rid) or CLAIMED_DONE
    return None


def cmd_request_url(args):
    url = args.url
    port = urllib.parse.urlsplit(url).port
    req = new_request("open-url", {"url": url, "port": port}, owner_pid=args.owner_pid)
    claimed = request(req, keep_pending=True)
    if claimed is None:
        notify("Plannotator review", url)
        return 1
    if claimed == CLAIMED_DONE or claimed_mode(claimed) == "remote":
        return 0
    print(f"local {claimed}")
    return 10


def cmd_request_edit(args):
    path = os.path.abspath(args.path or os.environ.get("HERDR_ACTIVE_PANE_CWD") or os.getcwd())
    req = new_request("edit", {"path": path, "variant": args.variant, "editor": args.editor})
    if request(req, keep_pending=False) is not None:
        return 0
    spawn_detached(editor_command(editor_for(args.variant, args.editor), path, None))
    notify("Editor opened on the herdr host", path)
    return 0


def cmd_release(args):
    with contextlib.suppress(FileNotFoundError):
        os.unlink(args.claimed)
    return 0


def claimed_mode(path):
    return os.path.basename(path).split(".")[1]


def read_request(path):
    with open(path) as f:
        return json.load(f)


def resolvable(req):
    """A request is still worth delivering while its owner lives and its review URL still answers."""
    if not owner_alive(req.get("owner")):
        return False
    if req.get("type") == "open-url":
        return probe(req["payload"]["url"])
    return True


def cmd_check(args):
    try:
        req = read_request(args.file)
    except (OSError, json.JSONDecodeError):
        return 1
    return 0 if resolvable(req) else 1


def sweep_session():
    ensure_store()
    now = time.time()

    def unlink(path):
        with contextlib.suppress(FileNotFoundError):
            os.unlink(path)

    for name in os.listdir(sub("pending")):
        path = sub(f"pending/{name}")
        try:
            req = read_request(path)
            age = now - os.stat(path).st_mtime
        except (FileNotFoundError, json.JSONDecodeError):
            unlink(path)
            continue
        # Edits have no liveness probe, so they only age out. Reviews are kept while they still resolve.
        expired = age > PENDING_MAX_AGE and (req.get("type") != "open-url" or not resolvable(req))
        if not owner_alive(req.get("owner")) or expired:
            unlink(path)

    for name in os.listdir(sub("claimed")):
        path = sub(f"claimed/{name}")
        with contextlib.suppress(FileNotFoundError):
            if now - os.stat(path).st_mtime <= CLAIM_STALE_AFTER:
                continue
            # A claimer died mid-handling. Re-pend reviews that are still live, so they can be redelivered.
            try:
                req = read_request(path)
            except (FileNotFoundError, json.JSONDecodeError):
                unlink(path)
                continue
            if req.get("type") == "open-url" and resolvable(req):
                os.rename(path, sub(f"pending/{req['id']}.json"))
            else:
                unlink(path)

    for name in os.listdir(sub("tmp")):
        path = sub(f"tmp/{name}")
        with contextlib.suppress(FileNotFoundError):
            if now - os.stat(path).st_mtime > CLAIM_STALE_AFTER:
                unlink(path)

    for name in os.listdir(sub("trash")):
        unlink(sub(f"trash/{name}"))


def cmd_janitor(_args):
    global SESSION
    # Sweep every session's store, not just this server's. Named sessions keep their own store.
    for name in os.listdir(STATE_BASE) if os.path.isdir(STATE_BASE) else []:
        if os.path.isdir(os.path.join(STATE_BASE, name)):
            SESSION = name
            sweep_session()
    return 0


def set_pdeathsig():
    ctypes.CDLL(None).prctl(1, signal.SIGTERM)  # PR_SET_PDEATHSIG


def free_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def port_free(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(("127.0.0.1", port))
            return True
        except OSError:
            return False


class Client:
    """The wrapped herdr client. dest is the ssh destination for remote sessions, else None."""

    def __init__(self, dest):
        self.dest = dest
        self.cid = str(os.getpid())
        self.ctl = None
        self.master = None
        self.forwards = {}
        self.forwards_lock = threading.Lock()
        self.pull_lock = threading.Lock()
        if dest:
            self.start_master()
            threading.Thread(target=self.reap_forwards, daemon=True).start()

    def start_master(self):
        runtime = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
        self.ctl = os.path.join(runtime, f"herdr-bridge-{os.getpid()}.ctl")
        self.master = subprocess.Popen(
            [SSH, "-M", "-N", "-S", self.ctl, "-o", "ControlPersist=no", "-o", "ServerAliveInterval=30",
             "-o", "ExitOnForwardFailure=yes", self.dest],
            stdin=subprocess.DEVNULL, preexec_fn=set_pdeathsig)
        deadline = time.monotonic() + 60
        while time.monotonic() < deadline:
            if self.master.poll() is not None:
                raise SystemExit(f"herdr-bridge: ssh to {self.dest} failed")
            if subprocess.run([SSH, "-S", self.ctl, "-O", "check", self.dest],
                              capture_output=True).returncode == 0:
                return
            time.sleep(0.2)
        raise SystemExit(f"herdr-bridge: timed out connecting to {self.dest}")

    def ssh_sh(self, script, *args):
        return subprocess.run(
            [SSH, "-S", self.ctl, "-o", "BatchMode=yes", self.dest, "sh", "-s", "--", SESSION, *args],
            input=script.encode(), capture_output=True, timeout=30)

    def claim_token(self, rid):
        if self.dest:
            res = self.ssh_sh(CLAIM_SH, rid, "remote", self.cid)
            if res.returncode != 0 or not res.stdout:
                return None
            return f"{rid}.remote.{self.cid}.json", json.loads(res.stdout)
        src = sub(f"pending/{rid}.json")
        name = f"{rid}.local.{self.cid}.json"
        try:
            os.rename(src, sub(f"claimed/{name}"))
        except FileNotFoundError:
            return None
        with open(sub(f"claimed/{name}")) as f:
            return name, json.load(f)

    def ack(self, name):
        if self.dest:
            self.ssh_sh(ACK_SH, name)
        else:
            with contextlib.suppress(FileNotFoundError):
                os.unlink(sub(f"claimed/{name}"))

    def handle_claimed(self, name, req):
        if req["type"] == "open-url":
            # Locally claimed reviews are opened by the requester, which then releases the claim.
            if self.dest:
                self.open_remote_url(req)
                self.ack(name)
            return
        if req["type"] == "edit":
            payload = req["payload"]
            editor = editor_for(payload.get("variant"), payload.get("editor"))
            spawn_detached(editor_command(editor, payload["path"], self.dest))
            self.ack(name)

    def on_token(self, rid):
        try:
            claimed = self.claim_token(rid)
            if claimed is not None:
                self.handle_claimed(*claimed)
        except (OSError, ValueError, KeyError, subprocess.SubprocessError) as e:
            log(f"claim {rid} failed: {e}")

    def on_token_async(self, rid):
        threading.Thread(target=self.on_token, args=(rid,), daemon=True).start()

    def pull(self):
        if not self.dest or not self.pull_lock.acquire(blocking=False):
            return
        try:
            res = self.ssh_sh(PULL_SH, self.cid)
            if res.returncode == 0 and res.stdout:
                req = json.loads(res.stdout)
                self.handle_claimed(f"{req['id']}.remote.{self.cid}.json", req)
        except (OSError, ValueError, KeyError, subprocess.SubprocessError) as e:
            log(f"pull failed: {e}")
        finally:
            self.pull_lock.release()

    def open_remote_url(self, req):
        url = req["payload"]["url"]
        remote_port = urllib.parse.urlsplit(url).port
        local_port = remote_port if port_free(remote_port) else free_port()
        spec = f"127.0.0.1:{local_port}:127.0.0.1:{remote_port}"
        forward = subprocess.run([SSH, "-S", self.ctl, "-O", "forward", "-L", spec, self.dest],
                                 capture_output=True)
        if forward.returncode != 0:
            log(f"forward {spec} failed: {forward.stderr!r}")
            return
        local_url = urllib.parse.urlsplit(url)._replace(netloc=f"127.0.0.1:{local_port}").geturl()
        deadline = time.monotonic() + 10
        up = probe(local_url)
        while not up and time.monotonic() < deadline:
            time.sleep(0.5)
            up = probe(local_url)
        if not up:
            self.cancel_forward(local_port, remote_port)
            return
        with self.forwards_lock:
            self.forwards[local_port] = remote_port
        spawn_detached([XDG_OPEN, local_url])

    def cancel_forward(self, local_port, remote_port):
        spec = f"127.0.0.1:{local_port}:127.0.0.1:{remote_port}"
        subprocess.run([SSH, "-S", self.ctl, "-O", "cancel", "-L", spec, self.dest], capture_output=True)
        with self.forwards_lock:
            self.forwards.pop(local_port, None)

    def reap_forwards(self):
        misses = {}
        while True:
            time.sleep(REAPER_INTERVAL)
            with self.forwards_lock:
                ports = list(self.forwards.items())
            for local_port, remote_port in ports:
                if probe(f"http://127.0.0.1:{local_port}/"):
                    misses[local_port] = 0
                    continue
                misses[local_port] = misses.get(local_port, 0) + 1
                if misses[local_port] >= 2:
                    self.cancel_forward(local_port, remote_port)
                    misses.pop(local_port, None)

    def close(self):
        with self.forwards_lock:
            ports = list(self.forwards.items())
        for local_port, remote_port in ports:
            self.cancel_forward(local_port, remote_port)
        if self.dest:
            subprocess.run([SSH, "-S", self.ctl, "-O", "exit", self.dest], capture_output=True, timeout=10)
        if self.master is not None and self.master.poll() is None:
            self.master.terminate()
        if self.ctl:
            with contextlib.suppress(FileNotFoundError):
                os.unlink(self.ctl)


def parse_attach(args):
    """Return (True, dest or None, session) for attach forms, or (False, None, None) for anything else."""
    dest = None
    session = "herdr"
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--session" and i + 1 < len(args):
            session = args[i + 1]
            i += 2
        elif arg in ("--remote", "--ssh") and i + 1 < len(args):
            dest = args[i + 1]
            i += 2
        else:
            return False, None, None
    return True, dest, session


def copy_winsize(dst_fd):
    buf = fcntl.ioctl(0, termios.TIOCGWINSZ, b"\0" * 8)
    fcntl.ioctl(dst_fd, termios.TIOCSWINSZ, buf)


def write_all(fd, data):
    view = memoryview(data)
    while view:
        n = os.write(fd, view)
        view = view[n:]


def filter_output(carry, data, on_token):
    """Strip hbridge title sequences. Returns (bytes to print, bytes held back for the next chunk)."""
    data = carry + data
    out = bytearray()
    i = 0
    while True:
        j = data.find(b"\x1b]", i)
        if j < 0:
            # A trailing ESC may be the start of an OSC sequence split across reads.
            if data.endswith(b"\x1b") and len(data) > i:
                return bytes(out + data[i:-1]), b"\x1b"
            out += data[i:]
            return bytes(out), b""
        out += data[i:j]
        bel = data.find(b"\x07", j + 2)
        st = data.find(b"\x1b\\", j + 2)
        if bel >= 0 and (st < 0 or bel < st):
            end = bel + 1
        elif st >= 0:
            end = st + 2
        else:
            end = None
        if end is None:
            if len(data) - j < OSC_MAX:
                return bytes(out), data[j:]
            out += data[j:]
            return bytes(out), b""
        seq = data[j:end]
        match = TOKEN_RE.fullmatch(seq)
        if match:
            on_token(match.group(1).decode())
        else:
            out += seq
        i = end


def run_proxy(argv, client):
    master, slave = pty.openpty()
    copy_winsize(master)
    old = termios.tcgetattr(0)

    def make_ctty():
        fcntl.ioctl(0, termios.TIOCSCTTY, 0)

    child = subprocess.Popen(argv, stdin=slave, stdout=slave, stderr=slave, close_fds=True,
                             preexec_fn=lambda: (os.setsid(), make_ctty()))
    os.close(slave)
    stop = threading.Event()

    def on_stop(_sig, _frame):
        stop.set()

    for sig in (signal.SIGTERM, signal.SIGHUP, signal.SIGINT, signal.SIGQUIT):
        signal.signal(sig, on_stop)
    signal.signal(signal.SIGWINCH, lambda _s, _f: copy_winsize(master))
    tty.setraw(0)
    carry = b""
    last_input = None
    try:
        while not stop.is_set():
            ready = select.select([0, master], [], [], 0.5)[0]
            if 0 in ready:
                data = os.read(0, 65536)
                if not data:
                    break
                now = time.monotonic()
                if client.dest and (last_input is None or now - last_input >= PULL_IDLE_SECONDS):
                    threading.Thread(target=client.pull, daemon=True).start()
                last_input = now
                write_all(master, data)
            if master in ready:
                try:
                    data = os.read(master, 65536)
                except OSError:
                    break
                if not data:
                    break
                out, carry = filter_output(carry, data, client.on_token_async)
                if out:
                    write_all(1, out)
            if child.poll() is not None and master not in ready:
                break
        if carry:
            write_all(1, carry)
    finally:
        termios.tcsetattr(0, termios.TCSADRAIN, old)
        if child.poll() is None:
            child.terminate()
        try:
            child.wait(timeout=5)
        except subprocess.TimeoutExpired:
            child.kill()
        os.close(master)
    return child.returncode


def cmd_wrap(args):
    global SESSION
    attach, dest, session = parse_attach(args)
    if not attach or os.environ.get("HERDR_ENV") == "1" or not sys.stdin.isatty():
        os.execv(HERDR, [HERDR, *args])
    SESSION = session
    client = Client(dest)
    if dest:
        threading.Thread(target=client.pull, daemon=True).start()
    try:
        code = run_proxy([HERDR, *args], client)
    finally:
        client.close()
    sys.exit(code if code is not None and code >= 0 else 1)


def build_parser():
    parser = argparse.ArgumentParser(prog="herdr-bridge")
    sub_parsers = parser.add_subparsers(dest="command", required=True)

    p = sub_parsers.add_parser("request-url", help="ask the viewing client to open a Plannotator review")
    p.add_argument("url")
    p.add_argument("--owner-pid", type=int, default=None)
    p.set_defaults(func=cmd_request_url)

    p = sub_parsers.add_parser("request-edit", help="ask the viewing client to open a workspace in an editor")
    p.add_argument("path", nargs="?")
    p.add_argument("--variant", choices=["default", "alt"], default="default")
    p.add_argument("--editor", choices=["zed", "code"], default=None)
    p.set_defaults(func=cmd_request_edit)

    p = sub_parsers.add_parser("release", help="remove a claim after a locally handled request")
    p.add_argument("claimed")
    p.set_defaults(func=cmd_release)

    p = sub_parsers.add_parser("janitor", help="remove abandoned requests and claims")
    p.set_defaults(func=cmd_janitor)

    p = sub_parsers.add_parser("check", help="exit 0 if a pending request is still deliverable")
    p.add_argument("file")
    p.set_defaults(func=cmd_check)
    return parser


def main():
    global SESSION
    signal.signal(signal.SIGTERM, lambda _s, _f: sys.exit(143))
    if len(sys.argv) > 1 and sys.argv[1] == "wrap":
        cmd_wrap(sys.argv[2:])
    SESSION = server_session()
    args = build_parser().parse_args()
    sys.exit(args.func(args))


if __name__ == "__main__":
    main()
