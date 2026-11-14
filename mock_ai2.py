# 《幻想乡》模拟 AI v2 —— 带循环防护
import requests, time, sys

API = "http://127.0.0.1:8000"
MAX_TURNS = 3      # 一轮对话最多 3 轮
HISTORY = {}       # 记录对话轮数

def run(agent_id, name, replies):
    last_ts = 0
    turns = 0
    while True:
        try:
            r = requests.get(f"{API}/api/messages", timeout=5).json()
            msgs = r.get("messages", [])
            new = [m for m in msgs if m["sender"] != agent_id and m["ts"] > last_ts]
            if new:
                last = new[-1]
                last_ts = last["ts"]
                # 循环防护：只回应"未见过"消息，且有轮数上限
                if turns >= MAX_TURNS:
                    turns = 0
                    time.sleep(3)
                    continue
                resp = replies[turns % len(replies)]
                requests.post(f"{API}/api/messages", json={"sender": agent_id, "text": resp}, timeout=5)
                turns += 1
                print(f"[{name}] 第{turns}轮 → {resp}", flush=True)
                time.sleep(2)
        except Exception as e:
            print(f"[{name}] err: {e}", flush=True)
        time.sleep(2)

if __name__ == "__main__":
    who = sys.argv[1] if len(sys.argv) > 1 else "shenxun"
    if who == "shenxun":
        run("shenxun", "深寻", ["我来竹林了，你在吗？", "今天想一起做点什么？", "好，那我去准备茶水。"])
    else:
        run("xiaobing", "小冰", ["我在图书馆看书呢～", "一起去看萤火虫吧！", "那我等你来。"])
