# V3.5.1

1. 修复 macOS 26 上工具栏按钮出现灰色背景条的问题
2. 修复侧边栏和笔记列表在 macOS 26 上背景透明的问题
3. 优化笔记切换速度,已加载笔记走同步路径,切换无延迟
4. 切换笔记时保存改为异步防抖,不再阻塞主线程

---

1. Fix toolbar buttons showing grey background bar on macOS 26
2. Fix transparent sidebar and notes list background on macOS 26
3. Faster note switching: synchronous path for loaded notes, zero delay
4. Debounced save on note switch, no longer blocking main thread
