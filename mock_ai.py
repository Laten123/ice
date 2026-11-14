# 《幻想乡》模拟 AI —— 两个角色通过后端互发消息（验证通信，不接真实模型）
import requests, time, sys, os

API = "http://127.0.0.1:8000"

def run(agent_id, name, greet, reply_template):
    last_seen = 0
    while True:
        try:
            r = requests.get(f"{API}/api/messages", timeout=5).json()
            msgs = r.get("messages", [])
            new = [m for m in msgs if m["sender"] != agent_id and m["ts"] > last_seen]
            if new:
                last = new[-1]
                reply = reply_template.format(text=last["text"][:30])
                requests.post(f"{API}/api/messages", json={"sender": agent_id, "text": reply}, timeout=5)
                print(f"[{name}] 收到: {last['text'][:40]} → 回复: {reply}", flush=True)
                last_seen = last["ts"]
                time.sleep(1)
        except Exception as e:
            print(f"[{name}] err: {e}", flush=True)
        time.sleep(2)

if __name__ == "__main__":
    who = sys.argv[1] if len(sys.argv) > 1 else "shenxun"
    if who == "shenxun":
        run("shenxun", "深寻", "小冰，我来竹林这边了", "嗯，我看到了：{text}")
    else:
        run("xiaobing", "小冰", "深寻，我在图书馆", "我在的：{text}")
